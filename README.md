## cyl-dc

## Prerequisites
- Proxmox API Token: Ensure you have a token with PVEVMAdmin permissions.
- Ubuntu 24.04 Template: A VM template in Proxmox with cloud-init installed.
- SSH Keys: Your public key should be added to the Terraform cloud_init section so Ansible can log in.

## Network Topology

| Node | LAN IP | WG IP | Subnet |
|------|-------|-------|--------|
| k3s01 | 192.168.1.150 | 10.0.0.1/24 | 192.168.1.x |
| k3s02 | 192.168.1.151 | 10.0.0.2/24 | 192.168.1.x |
| k3s03 | 192.168.11.150 | 10.0.0.3/24 | 192.168.11.x |
| k3s04 | 192.168.11.151 | 10.0.0.4/24 | 192.168.11.x |

## Deployment

### 1. Terraform - Deploy VMs
```bash
cd terraform/deployment/pve && terraform apply -auto-approve
cd terraform/deployment/pve2 && terraform apply -auto-approve
```

### 2. Ansible - Install WireGuard
```bash
cd ansible
ansible-playbook -i inventory/hosts.ini playbooks/wireguard.yml
```

### 3. Ansible - Setup K3s
```bash
ansible-playbook -i inventory/hosts.ini playbooks/setup_k3s.yml
```

## WireGuard Configuration

### Key Points (Fixed)
- **MTU = 1420** - Prevents fragmentation issues
- **No PostUp/PostDown routes** - Avoids routing loops between subnets
- **AllowedIPs only 10.0.0.0/24** - WireGuard handles ONLY VPN traffic

### Correct Config Template
```ini
[Interface]
Address = 10.0.0.x/24
PrivateKey = <your-private-key>
ListenPort = 51820
MTU = 1420

[Peer]
PublicKey = <peer-public-key>
AllowedIPs = 10.0.0.y/32
Endpoint = <peer-lan-ip>:51820
PersistentKeepalive = 25
```

## K3s Agent Installation (Critical Flags)

When installing agents that connect across WireGuard:
```bash
curl -sfL https://get.k3s.io | \
  K3S_URL=https://10.0.0.1:6443 \
  K3S_TOKEN=<token> \
  sh -s - agent \
  --flannel-iface=wg0 \
  --node-ip=10.0.0.x
```

**Key flags:**
- `--flannel-iface=wg0` - Use WireGuard interface for cluster networking
- `--node-ip=10.0.0.x` - Bind to WireGuard IP

## Inventory (hosts.ini)
```ini
[master]
k3s01 ansible_host=192.168.1.150 ansible_user=user wireguard_ip=10.0.0.1/24
k3s03 ansible_host=192.168.11.150 ansible_user=user wireguard_ip=10.0.0.3/24

[worker]
k3s02 ansible_host=192.168.1.151 ansible_user=user wireguard_ip=10.0.0.2/24
k3s04 ansible_host=192.168.11.151 ansible_user=user wireguard_ip=10.0.0.4/24

[pve_nodes]
k3s01 ansible_host=192.168.1.150 ansible_user=user wireguard_ip=10.0.0.1/24
k3s02 ansible_host=192.168.1.151 ansible_user=user wireguard_ip=10.0.0.2/24
k3s03 ansible_host=192.168.11.150 ansible_user=user wireguard_ip=10.0.0.3/24
k3s04 ansible_host=192.168.11.151 ansible_user=user wireguard_ip=10.0.0.4/24

[k3s_cluster:children]
master
worker
```

## Troubleshooting

### Check WireGuard status
```bash
sudo wg show
```

### Check K3s cluster
```bash
sudo kubectl get nodes -o wide
```

### Common Issues

1. **"Connection reset"** - Route loops. Fix: Use MTU=1420 and --flannel-iface=wg0
2. **Agent can't join** - Token mismatch. Use correct server token from k3s01
3. **Separate clusters** - Wipe node before rejoin: `k3s-uninstall.sh && rm -rf /var/lib/rancher/k3s`

## Dialing Port forward at jump host
```
$ ssh -L 0.0.0.0:8006:10.10.0.9:8006 wg
```