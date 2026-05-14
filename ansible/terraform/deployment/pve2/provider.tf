terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.0"
    }
  }
}

variable "proxmox_api_token" {
  default = "root@pam!oc1=460a8e5b-2556-46e7-8e2b-f3808593d04b"
}

provider "proxmox" {
  endpoint = "https://10.10.0.9:8006/"
  api_token = var.proxmox_api_token
  insecure = true
}
