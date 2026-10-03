terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = ">= 1.2.0"
    }
  }
}

provider "incus" {
  default_remote            = var.incus_remote
  accept_remote_certificate = true
}
