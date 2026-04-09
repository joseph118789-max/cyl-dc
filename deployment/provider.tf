terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://10.10.0.9:8006/"
  api_token = var.proxmox_api_token
  insecure = true
}
