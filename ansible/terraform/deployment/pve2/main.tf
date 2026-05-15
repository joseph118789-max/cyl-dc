# Terraform config for k3s nodes on PVE2
# Storage: local1 on node pve2
# Note: Disk management handled separately - template provides disk

resource "proxmox_virtual_environment_vm" "vpn_nodes" {
  count     = 2
  name      = "k3s0${count.index + 3}"
  node_name = "pve2"
  vm_id     = 200 + count.index

  clone {
    vm_id    = 104
    full     = true
    retries  = 1
  }

  initialization {
    datastore_id = "local1"
    ip_config {
      ipv4 {
        address = "192.168.11.${150 + count.index}/24"
        gateway = "192.168.11.2"
      }
    }
    
    user_account {
      username = "user"
      keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5HDZjLiZygMdm2pJHzDm+AgD82j4q9PL0kXgBJEeK9 root@openclaw01"]
    }
  }

  agent {
    enabled = true 
    type    = "virtio"
  }

  network_device {
    bridge = "vmbr0"
  }
}

output "vm_ips" {
  value = [for vm in proxmox_virtual_environment_vm.vpn_nodes : vm.initialization[0].ip_config[0].ipv4[0].address]
}