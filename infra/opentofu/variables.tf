variable "incus_remote" {
  type        = string
  description = "Incus remote name"
  default     = "local-https"
}

variable "host" {
  type        = string
  description = "Name of the host/instance to deploy"
}

variable "instance_type" {
  type        = string
  description = "Instance type: container or virtual-machine"
  default     = "container"
}

variable "image" {
  type        = string
  description = "Image to use for the instance (defaults to nixos/<host> if null)"
  default     = null
}

variable "running" {
  type        = bool
  description = "Whether the instance should be running"
  default     = true
}

variable "profiles" {
  type        = list(string)
  description = "Incus profiles"
  default     = ["default"]
}

variable "config" {
  type        = map(string)
  description = "Incus instance config options"
  default     = {}
}

variable "devices" {
  type = list(object({
    name       = string
    type       = string
    properties = map(string)
  }))
  description = "Device configurations (disks, nics, etc.)"
  default     = []
}

variable "files" {
  type = list(object({
    target_path        = string
    content            = string
    mode               = optional(string, "0600")
    uid                = optional(number, 0)
    gid                = optional(number, 0)
    create_directories = optional(bool, true)
  }))
  description = "Additional files to place inside the instance"
  default     = []
}

variable "storage_pool" {
  type        = string
  description = "Incus storage pool for persistent volumes"
  default     = "default"
}

variable "persist_volume" {
  type        = bool
  description = "Whether to create and attach a persistent storage volume"
  default     = true
}

variable "persist_files" {
  type = list(object({
    target_path        = string
    source_path        = optional(string)
    content            = optional(string)
    mode               = optional(string, "0600")
    uid                = optional(number, 0)
    gid                = optional(number, 0)
    create_directories = optional(bool, true)
  }))
  description = "Files to place on the persist storage volume"
  default     = []
}
