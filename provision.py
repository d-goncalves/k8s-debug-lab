#!/usr/bin/env python3
"""provision - k8s-debug-lab lifecycle CLI.

Runs on your workstation. Manages a disposable k3s VM and injects/reverts
named faults for debugging practice. Faults execute on the VM over ssh (many
are host-level and only make sense there); you never type them yourself.
Debugging is done by YOU over `provision ssh`, exactly like a real live test.
"""
import json
import pathlib
import subprocess
import sys

import click

ROOT = pathlib.Path(__file__).resolve().parent
TF_DIR = ROOT / "terraform"
ANS_DIR = ROOT / "ansible"
FAULT_DIR = ROOT / "lab" / "faults"
STATE = ROOT / ".state"
ACTIVE = STATE / "active"
LAYERS = ("k8s", "host")
SSH_OPTS = ["-o", "StrictHostKeyChecking=accept-new", "-o", "ConnectTimeout=10"]

STATE.mkdir(exist_ok=True)


# --- output helpers -------------------------------------------------------
def ok(msg):
    click.secho(f"✓ {msg}", fg="green")


def bad(msg):
    click.secho(f"✗ {msg}", fg="red")


def info(msg):
    click.secho(f"→ {msg}", fg="cyan")


# --- terraform outputs (authoritative source of VM details) ---------------
def tf_output(name):
    try:
        res = subprocess.run(
            ["terraform", f"-chdir={TF_DIR}", "output", "-json"],
            capture_output=True, text=True, check=True,
        )
        return json.loads(res.stdout).get(name, {}).get("value")
    except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError):
        return None


def vm_ip():
    ip = tf_output("vm_address")
    return ip.strip() if ip else None


def vm_user():
    u = tf_output("ssh_user")
    return u.strip() if u else "rocky"


def require_vm():
    ip = vm_ip()
    if not ip:
        bad("No VM found. Run: ./provision create")
        sys.exit(1)
    return ip


# --- remote execution -----------------------------------------------------
def rsh(cmd, capture=True):
    """Unprivileged command on the VM."""
    ip = require_vm()
    return subprocess.run(
        ["ssh", *SSH_OPTS, f"{vm_user()}@{ip}", cmd],
        capture_output=capture, text=True,
    )


def rroot(script):
    """Root command on the VM, via sudo, script fed on stdin."""
    ip = require_vm()
    return subprocess.run(
        ["ssh", *SSH_OPTS, f"{vm_user()}@{ip}", "sudo bash -s"],
        input=script, capture_output=True, text=True,
    )


# --- fault catalogue ------------------------------------------------------
def fault_file(fid):
    for layer in LAYERS:
        f = FAULT_DIR / layer / f"{fid}.sh"
        if f.exists():
            return f, layer
    return None, None


def fault_meta(path, key):
    prefix = f"# {key}: "
    for line in path.read_text().splitlines():
        if line.startswith(prefix):
            return line[len(prefix):]
    return ""


def all_faults():
    for layer in LAYERS:
        for f in sorted((FAULT_DIR / layer).glob("*.sh")):
            yield f.stem, layer, f


def run_fault(action, fid):
    path, _ = fault_file(fid)
    if not path:
        bad(f"unknown fault: {fid}")
        return False
    script = (
        "set -e\n"
        "export STACK_DIR=/opt/lab/stack\n"
        'k() { /usr/local/bin/k3s kubectl "$@"; }\n'
        f"{path.read_text()}\n"
        f"{action}\n"
    )
    return rroot(script).returncode == 0


def active_ids():
    if ACTIVE.exists():
        return [x for x in ACTIVE.read_text().splitlines() if x.strip()]
    return []


def write_active(ids):
    ordered = sorted(set(ids))
    ACTIVE.write_text("\n".join(ordered) + ("\n" if ordered else ""))


# --- health ---------------------------------------------------------------
def verify(quiet=False):
    ip = vm_ip()
    if not ip:
        bad("No VM.")
        return False
    a = rsh("curl -s -o /dev/null -w '%{http_code}' --max-time 8 http://demo.local/")
    b = rsh("curl -s --max-time 8 http://demo.local/api/")
    code = (a.stdout or "").strip() or "000"
    body = (b.stdout or "").strip()
    good = code == "200" and "api ok" in body
    if not quiet:
        (ok if code == "200" else bad)(f"curl / -> {code}")
        (ok if "api ok" in body else bad)(f"curl /api/ -> {body or 'no response'}")
    return good


# --- CLI ------------------------------------------------------------------
@click.group(help=__doc__)
def cli():
    pass


@cli.command(help="Provision the VM (terraform) and configure it (ansible).")
def create():
    info("terraform apply")
    subprocess.run(["terraform", f"-chdir={TF_DIR}", "init", "-input=false"],
                   check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["terraform", f"-chdir={TF_DIR}", "apply", "-auto-approve"],
                   check=True)
    ip = require_vm()
    subprocess.run(["ssh-keygen", "-R", ip],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    info(f"waiting for ssh on {ip}")
    while subprocess.run(
        ["ssh", *SSH_OPTS, f"{vm_user()}@{ip}", "true"],
        capture_output=True,
    ).returncode != 0:
        __import__("time").sleep(5)
    info("running ansible")
    subprocess.run(
        ["ansible-playbook", "-i", f"{ip},", "site.yml"],
        cwd=ANS_DIR, check=True,
        env={**__import__("os").environ, "ANSIBLE_HOST_KEY_CHECKING": "False"},
    )
    write_active([])
    verify()


@cli.command(help="Tear the VM down.")
def destroy():
    subprocess.run(["terraform", f"-chdir={TF_DIR}", "destroy", "-auto-approve"],
                   check=True)
    write_active([])


@cli.command(help="Destroy + create, clean slate.")
@click.pass_context
def rebuild(ctx):
    ctx.invoke(destroy)
    ctx.invoke(create)


@cli.command(help="Is the VM up and the stack healthy?")
def status():
    ip = vm_ip()
    if not ip:
        bad("No VM (run: ./provision create)")
        sys.exit(1)
    if rsh("true").returncode == 0:
        ok(f"VM reachable at {ip}")
    else:
        bad(f"VM {ip} not reachable")
        sys.exit(1)
    verify()


@cli.command("verify", help="Run the two acceptance checks.")
def verify_cmd():
    verify()


@cli.command("list", help="Show the fault catalogue.")
def list_cmd():
    click.echo()
    click.echo(f"{'ID':<32} {'LAYER':<10} SYMPTOM")
    click.echo(f"{'--':<32} {'-----':<10} -------")
    for fid, layer, f in all_faults():
        click.echo(f"{fid:<32} {layer:<10} {fault_meta(f, 'symptom')}")
    click.echo()


@cli.command("break", help="Inject named faults (or -r N random ones).")
@click.argument("ids", nargs=-1)
@click.option("-r", "--random", "n_random", type=int, default=0,
              help="Inject N random faults instead.")
def break_cmd(ids, n_random):
    if n_random:
        import random
        pool = [fid for fid, _, _ in all_faults()]
        ids = random.sample(pool, min(n_random, len(pool)))
    if not ids:
        bad("nothing to inject (give fault ids or -r N)")
        sys.exit(1)
    active = active_ids()
    for fid in ids:
        _, layer = fault_file(fid)
        info(f"injecting {fid} ({layer})")
        if run_fault("inject", fid):
            active.append(fid)
            ok(fid)
        else:
            bad(f"{fid} failed to inject")
    write_active(active)


@cli.command(help="Show what is injected (the answer key).")
def reveal():
    ids = active_ids()
    if not ids:
        info("no faults currently injected")
        return
    click.echo()
    click.secho("Currently injected:", fg="yellow", bold=True)
    for fid in ids:
        path, layer = fault_file(fid)
        click.echo(f"\n  {fid} ({layer})")
        click.echo(f"    answer: {fault_meta(path, 'answer')}")
    click.echo()


@cli.command(help="Revert everything, back to healthy.")
def reset():
    for fid in active_ids():
        info(f"reverting {fid}")
        (ok if run_fault("revert", fid) else bad)(fid)
    write_active([])
    verify()


@cli.command(help="Shell into the VM to debug.")
def ssh():
    ip = require_vm()
    subprocess.run(["ssh", "-o", "StrictHostKeyChecking=accept-new",
                    f"{vm_user()}@{ip}"])


@cli.command(help="Fetch kubeconfig + open a localhost:6443 tunnel.")
def kubeconfig():
    ip = require_vm()
    res = rsh("sudo cat /etc/rancher/k3s/k3s.yaml")
    (STATE / "kubeconfig").write_text(res.stdout)
    subprocess.run(["ssh", "-o", "StrictHostKeyChecking=accept-new",
                    "-f", "-N", "-L", "6443:127.0.0.1:6443", f"{vm_user()}@{ip}"])
    info("tunnel open on localhost:6443")
    info(f"run: export KUBECONFIG={STATE / 'kubeconfig'}")


if __name__ == "__main__":
    cli()
