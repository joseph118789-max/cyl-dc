resource "proxmox_virtual_environment_vm" "vpn_nodes" {
  count     = 2
  name      = "k3s0${count.index + 1}"
  node_name = "pve"
  vm_id     = 200 + count.index

  clone {
    vm_id = 101
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.1.${150 + count.index}/24"
        gateway = "192.168.1.1"
      }
    }
    
    user_account {
      username = "user"
      keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB5HDZjLiZygMdm2pJHzDm+AgD82j4q9PL0kXgBJEeK9 root@openclaw01"]
    }
  }

  agent {
    enabled = false 
  }

  network_device {
    bridge = "vmbr0"
  }
}

output "vm_ips" {
  value = [for vm in proxmox_virtual_environment_vm.vpn_nodes : vm.initialization[0].ip_config[0].ipv4[0].address]
}
