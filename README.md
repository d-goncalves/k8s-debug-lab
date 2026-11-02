# k8s-debug-lab

A disposable Kubernetes troubleshooting environment. It provisions a single-node [k3s](https://k3s.io) VM, deploys a small three-tier app (`ingress → web → api → database`), and injects named faults across the cluster and the host so you can practise debugging under realistic conditions.

The whole lifecycle (create, break, debug, reset, destroy) is automated with **Terraform** and **Ansible** and driven from one CLI on your workstation.

## Usage

Requirements on your workstation: `terraform`, `ansible`, `ssh`, `curl` and `python3`. The `provision` wrapper creates a local `.venv` and installs its one Python dependency (Click) on first run.

```bash
# 1. Configure. Proxmox users: create an API token first (see docs/SETUP.md)
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
$EDITOR terraform/terraform.tfvars        # endpoint, token, network, ssh key

# 2. Build the VM: Terraform creates it, Ansible configures k3s and the app, health is verified
./provision create

# 3. Practise
./provision list                          # show the fault catalogue
./provision break -r 4                    # inject four random faults (or name them: break service-selector-mismatch)
./provision ssh                           # shell in and debug, like a real live test
./provision reveal                        # stuck? print the answer key
./provision reset                         # revert everything and verify healthy

# Housekeeping
./provision status                        # is the VM up and the stack healthy?
./provision verify                        # run the two acceptance checks
./provision kubeconfig                    # fetch the kubeconfig and open a localhost:6443 tunnel
./provision rebuild                       # destroy and create, clean slate
./provision destroy                       # tear the VM down
```

Setup details are in [docs/SETUP.md](docs/SETUP.md).

## Architecture

| Layer | Tool | Role |
|-------|------|------|
| VM provisioning | Terraform (`bpg/proxmox`) | create and destroy the Rocky 9 VM |
| Host and cluster config | Ansible | k3s, tooling, deploy the stack, verify the baseline |
| Fault lifecycle | `provision` (Python and Click) | inject, reveal and reset, run from your workstation |
| Workload | k3s and Traefik | `demo` namespace, `demo.local` |

Faults **run on the VM**, because many are host-level (systemd, disk, file attributes), but you never type them. You debug over `provision ssh`: the tool manages the lab and does not solve it for you.

Ansible is the core and works against **any** Rocky or RHEL host. Terraform is an optional convenience for Proxmox users. Point the Ansible inventory at a cloud VM or a spare box and the lab builds there just the same.

## Why

I built this to train for a live "SSH into a broken cluster and fix it" interview. Reading about failure modes is not the same as recognising a `targetPort` mismatch from a hanging `curl`, or an immutable file from an `Operation not permitted` as root. The only way to get fast is reps against real breakage, and the only safe way to get reps is a box you can destroy.

## What a fault looks like

Each fault is one small script that carries its own metadata. This is a real one:

```bash
# id: service-selector-mismatch
# layer: kubernetes
# symptom: pods 1/1 Running, service reachable, nothing answers
# hint: kubectl get endpointslice -n demo
# answer: the Service selector matches no pod labels, so the EndpointSlice is empty
inject() { k patch svc web -n demo --type=merge -p '{"spec":{"selector":{"app":"web-frontend"}}}'; }
revert() { k patch svc web -n demo --type=merge -p '{"spec":{"selector":{"app":"web"}}}'; }
```

Everything looks healthy and nothing works. The fix is to notice that the Service points at labels no pod has.

## Fault catalogue

Run `./provision list`, or read [docs/FAULTS.md](docs/FAULTS.md) for the full table with symptoms, causes and fixes. 35 faults across two layers:

- **Kubernetes (21):** ingress class / backend / host, service selector, both port mismatches, PVC storage class, secret key vs reference, readiness probe, image tag, paused rollout, cordon, taint, resource quota, CoreDNS, dnsPolicy, OOM, configmap mount, nodeSelector, scale-to-zero.
- **Host (14):** hosts entry missing/wrong, unreachable resolver, immutable file, deleted-file-held disk, runaway log, failed / masked / start-limited units, disabled NTP, CPU runaway, disabled logrotate, world-readable kubeconfig, rogue UID-0 account.
