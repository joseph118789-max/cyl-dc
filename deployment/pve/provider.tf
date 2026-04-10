terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.0"
    }
  }
}

variable "proxmox_api_token" {
  default = "root@pam!oc1=49cf6d62-a529-495d-9ee5-dce81016bfce"
}

provider "proxmox" {
  endpoint = "https://192.168.1.253:8006/"
  api_token = var.proxmox_api_token
  insecure = true
}
