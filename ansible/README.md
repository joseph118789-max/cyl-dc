# Ansible Infrastructure for cyl-dc

## Prerequisites

Before running any playbooks, execute the following to enable network connectivity to pve2:

```bash
ansible-playbook playbooks/add-route.yml
```

This adds a static route:
```
ip route add 192.168.11.0/24 via 192.168.1.200
```

## Playbooks

- `playbooks/terraform-apply.yml` - Deploy VMs via Terraform
- `playbooks/terraform-destroy.yml` - Destroy Terraform-managed VMs
- `playbooks/wireguard.yml` - Configure WireGuard VPN
- `playbooks/add-route.yml` - Add static route (prerequisite)

## Usage

```bash
# Run via wrapper script
./run.sh

# Or manually
cd /root/.openclaw/workspace/projects/cyl-dc/ansible
ansible-playbook -i inventory/inventory.ini playbooks/terraform-apply.yml
```