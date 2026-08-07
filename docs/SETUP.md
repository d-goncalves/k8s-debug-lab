# Setup

## Proxmox API token

Terraform authenticates with a scoped API token, not your root password.
Create a dedicated user and role (run on the Proxmox host as root):

```bash
# a role with only what provisioning needs
pveum role add TerraformProv
pveum role modify TerraformProv --privs \
  "Datastore.Allocate,Datastore.AllocateSpace,Datastore.AllocateTemplate,Datastore.Audit,\
Pool.Allocate,Sys.Audit,Sys.Console,Sys.Modify,VM.Allocate,VM.Audit,VM.Clone,\
VM.Config.CDROM,VM.Config.CPU,VM.Config.Cloudinit,VM.Config.Disk,VM.Config.HWType,\
VM.Config.Memory,VM.Config.Network,VM.Config.Options,VM.Migrate,VM.PowerMgmt,SDN.Use"

pveum user add terraform@pve
pveum acl modify / --user terraform@pve --role TerraformProv

# create the token (privsep off so it inherits the role's privileges)
pveum user token add terraform@pve tf --privsep 0
```

The last command prints the secret **once**. Put it in `terraform.tfvars` as
`user@realm!tokenid=secret`, e.g. `terraform@pve!tf=xxxxxxxx-...`.

### Privilege names differ by Proxmox version
On some PVE versions the granular `VM.Config.*` privileges are consolidated, and
`VM.Monitor` does not exist. If `role modify` rejects your list, get the valid
names from your node and adjust:

```bash
pvesh get /access/roles/Administrator --output-format json | tr ',' '\n' | grep -oE '[A-Z][A-Za-z]+\.[A-Za-z.]+' | sort -u
```

## Networking

The VM takes a **static** address (`vm_address`). Pick one that is free and
**outside your DHCP pool**.

Set `vm_nameservers` to a real resolver (default `1.1.1.1`). Do **not** let the
VM inherit a split-DNS resolver it cannot reach — e.g. a Tailscale MagicDNS
address (`100.100.100.100`) handed out by DHCP will make every lookup on the VM
hang while the network itself works fine.

## Not on Proxmox?

Skip Terraform. Build any Rocky/RHEL 9 host, then point Ansible at it:

```bash
cd ansible
ansible-playbook -i "<vm-ip>," site.yml
```

## The provider needs SSH to the Proxmox node

The `bpg/proxmox` provider imports the downloaded cloud image as a VM disk
**over SSH to the node**, not through the API. It uses `ssh-agent` and
deliberately **ignores `~/.ssh/config`**. So:

1. An agent key must be authorised for the provisioning user in that user's
   `authorized_keys` on the Proxmox host (default `root`).
2. Set `proxmox_ssh_user` in `terraform.tfvars` to match.

Symptom if this is missing:
`unable to authenticate user "" over SSH to <node>:22 ... no supported methods remain`
