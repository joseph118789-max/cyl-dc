
## cyl-dc

##Prerequisites
Proxmox API Token: Ensure you have a token with PVEVMAdmin permissions.

Ubuntu 24.04 Template: A VM template in Proxmox with cloud-init installed.

SSH Keys: Your public key should be added to the Terraform cloud_init section so Ansible can log in.

Dialing Port forward at jump host user@kubuntu-virtual-machine
```
$ ssh -L 0.0.0.0:8006:10.10.0.9:8006 wg
```
