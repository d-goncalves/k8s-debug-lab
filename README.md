# k8s-debug-lab

A disposable, reproducible Kubernetes troubleshooting environment. It provisions
a single-node [k3s](https://k3s.io) VM, deploys a small three-tier app
(`ingress → web → api → database`), and lets you **inject named faults** across
the cluster and the host so you can practise debugging under realistic conditions.

Everything is driven from one CLI on your workstation. The full lifecycle —
create the VM, break it, debug it, reset it, destroy it — is automated with
**Terraform** and **Ansible**.

```
./provision create          # Terraform builds the VM, Ansible configures it, health is verified
./provision break -r 4      # inject four random faults
./provision ssh             # shell in and debug, exactly like a real live test
./provision reveal          # stuck? print the answer key
./provision reset           # revert everything, verify healthy
./provision rebuild         # blow it away and start clean
```

## Why

I built this to train for a live "SSH into a broken cluster and fix it"
interview. Reading about failure modes is not the same as recognising a
`targetPort` mismatch from a hanging curl, or an immutable file from an
`Operation not permitted` as root. The only way to get fast is reps against
real breakage, and the only safe way to get reps is a box you can destroy.

## Architecture

| Layer | Tool | Role |
|-------|------|------|
| VM provisioning | Terraform (`bpg/proxmox`) | create/destroy the Rocky 9 VM |
| Host + cluster config | Ansible | k3s, tooling, deploy the stack, verify baseline |
| Fault lifecycle | `provision` (bash) | inject / reveal / reset, run from your Mac |
| Workload | k3s + Traefik | `demo` namespace, `demo.local` |

Faults **execute on the VM** (many are host-level: systemd, disk, file
attributes), but you never type them. You debug over `provision ssh` — the tool
manages the lab, it does not solve it for you.

## The design choice worth noting

Ansible is the core and works against **any** Rocky/RHEL host. Terraform is an
optional convenience for Proxmox users. Point the Ansible inventory at a cloud
VM or a spare box and the lab builds there just the same.

## Quick start

```bash
# 1. Proxmox users: create an API token (see docs/SETUP.md), then:
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
$EDITOR terraform/terraform.tfvars     # endpoint, token, network, ssh key

# 2. Build and verify
./provision create

# 3. Practise
./provision list
./provision break service-selector-mismatch disk-deleted-file-held
./provision ssh
# ... debug ...
./provision reset
```

Requirements on your workstation: `terraform`, `ansible`, `ssh`, `curl`.

## Fault catalogue

Run `./provision list`, or read [docs/FAULTS.md](docs/FAULTS.md) for the full
table with symptoms, causes and fixes. 35 faults across two layers:

- **Kubernetes (21):** ingress class / backend / host, service selector, both
  port mismatches, PVC storage class, secret key vs reference, readiness probe,
  image tag, paused rollout, cordon, taint, resource quota, CoreDNS, dnsPolicy,
  OOM, configmap mount, nodeSelector, scale-to-zero.
- **Host (14):** hosts entry missing/wrong, unreachable resolver, immutable file,
  deleted-file-held disk, runaway log, failed / masked / start-limited units,
  disabled NTP, CPU runaway, disabled logrotate, world-readable kubeconfig,
  rogue UID-0 account.

## Method

The debugging approach this lab trains — a fixed read-only sweep, the
"every fault is an unresolved reference" model, and reading the mechanism rather
than guessing — is written up in [docs/METHOD.md](docs/METHOD.md).

## Note on authorship

The methodology docs were developed with AI assistance during interview prep.
The Terraform, Ansible, stack and fault catalogue are my own implementation.
