# Ansible Infrastructure for cyl-dc

## Overview

Infrastructure-as-Code for deploying a K3s Kubernetes cluster across Proxmox VMs with WireGuard VPN, MetalLB, Longhorn, and Istio.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     K3s Cluster (4 nodes)                   │
├──────────────┬──────────────┬──────────────┬──────────────┤
│   k3s01      │   k3s02       │   k3s03      │   k3s04      │
│  (master)    │  (master)     │  (worker)    │  (worker)    │
│  192.168.1.150│ 192.168.11.150│ 192.168.1.151│ 192.168.11.151│
│  10.0.0.1/24 │  10.0.0.3/24  │ 10.0.0.2/24  │ 10.0.0.4/24 │
└──────────────┴──────────────┴──────────────┴──────────────┘
          │                           │
    WireGuard VPN (10.0.0.0/24)          │
          │                           │
┌────────────────┐          ┌────────────────┐
│  pve (Proxmox) │◄────────►│ pve2 (Proxmox) │
│  192.168.1.x   │  via wg   │  192.168.11.x  │
└────────────────┘          └────────────────┘
```

## Addons

| Addon | Version | Purpose |
|-------|---------|---------|
| **MetalLB** | v0.14.5 | LoadBalancer for bare-metal K3s |
| **Longhorn** | v1.6.0 | Distributed block storage |
| **Istio** | 1.29.1 | Service mesh |
| **local-path** |内置 | Default storage (Rancher) |

## Prerequisites

Before running any playbooks, ensure network connectivity:

```bash
ansible-playbook playbooks/add-route.yml
```

## Inventory

Edit `inventory/hosts.ini`:

```ini
[master]
k3s01 ansible_host=192.168.1.150 ansible_user=user wireguard_ip=10.0.0.1/24
k3s02 ansible_host=192.168.11.150 ansible_user=user wireguard_ip=10.0.0.3/24

[worker]
k3s03 ansible_host=192.168.1.151 ansible_user=user wireguard_ip=10.0.0.2/24
k3s04 ansible_host=192.168.11.151 ansible_user=user wireguard_ip=10.0.0.4/24

[k3s_cluster:children]
master
worker
```

## K3s Playbooks

### Core Cluster Setup

```bash
# Setup K3s cluster (full reinstall)
ansible-playbook playbooks/setup_k3s.yml -e cleanup=true

# Join nodes to existing cluster
ansible-playbook playbooks/join_k3s.yml
```

## Addon Playbooks

### 1. Storage Prerequisites
Installs open-iscsi and nfs-common on all nodes (required for Longhorn):

```bash
ansible-playbook playbooks/k3s-storage-prereqs.yml
```

### 2. MetalLB
Installs MetalLB load balancer with IP pool:

```bash
# Default: 192.168.1.200-192.168.1.250
ansible-playbook playbooks/metallb.yml

# Or target specific node
ansible-playbook playbooks/metallb.yml -l k3s01
```

### 3. Longhorn
Installs Longhorn distributed storage:

```bash
ansible-playbook playbooks/longhorn.yml -l k3s01

# Check status
ssh user@192.168.1.150 "kubectl get sc"
```

### 4. Istio
Installs Istio service mesh:

```bash
ansible-playbook playbooks/istio.yml -l k3s01

# Check status
ssh user@192.168.1.150 "kubectl get pods -n istio-system"
```

## Full Deployment Sequence

```bash
cd /root/.openclaw/workspace/projects/cyl-dc/ansible

# 1. Add static route for pve2 network
ansible-playbook playbooks/add-route.yml

# 2. Deploy VMs via Terraform
ansible-playbook playbooks/terraform-apply.yml

# 3. Configure WireGuard VPN
ansible-playbook playbooks/wireguard.yml
ansible-playbook playbooks/wireguard-peers.yml

# 4. Reboot nodes
ansible-playbook playbooks/reboot.yml

# 5. Setup K3s cluster
ansible-playbook playbooks/setup_k3s.yml

# 6. Install storage prerequisites (open-iscsi)
ansible-playbook playbooks/k3s-storage-prereqs.yml

# 7. Install addons
ansible-playbook playbooks/metallb.yml -l k3s01
ansible-playbook playbooks/longhorn.yml -l k3s01
ansible-playbook playbooks/istio.yml -l k3s01
```

## Quick Start

```bash
# Run wrapper script
./run.sh
```

## Usage Examples

```bash
# Get cluster info
ssh user@192.168.1.150 "k3s kubectl cluster-info"

# Get nodes
ssh user@192.168.1.150 "k3s kubectl get nodes"

# Get pods (all namespaces)
ssh user@192.168.1.150 "k3s kubectl get pods -A"

# Get storage classes
ssh user@192.168.1.150 "k3s kubectl get sc"

# Get istio-system pods
ssh user@192.168.1.150 "k3s kubectl get pods -n istio-system"

# Get metallb-system pods
ssh user@192.168.1.150 "k3s kubectl get pods -n metallb-system"
```

## Playbook Variables

### metallb.yml
```yaml
metallb_version: v0.14.5      # MetalLB version
ip_pool_start: 192.168.1.200  # IP range start
ip_pool_end: 192.168.1.250    # IP range end
```

### longhorn.yml
```yaml
longhorn_version: v1.6.0       # Longhorn version
```

### istio.yml
```yaml
istio_version: "1.29.1"        # Istio version
```

### k3s-storage-prereqs.yml
No variables - installs open-iscsi and nfs-common on all nodes.

## Files

- `playbooks/` - Ansible playbooks
- `inventory/` - Host definitions
- `templates/` - Configuration templates
- `terraform/` - Terraform definitions for VM deployment

## Troubleshooting

```bash
# Check WireGuard status
ssh user@<node-ip> "sudo wg show"

# Check K3s status
ssh user@<node-ip> "systemctl status k3s"

# View K3s logs
ssh user@<node-ip> "sudo journalctl -u k3s --no-pager -n 50"

# Check pod events
ssh user@192.168.1.150 "kubectl describe pod <pod-name> -n <namespace>"

# Restart WireGuard
ssh user@<node-ip> "sudo wg-quick down wg0; sudo wg-quick up wg0"

# Check node resources
ssh user@192.168.1.150 "kubectl describe nodes k3s01"
```