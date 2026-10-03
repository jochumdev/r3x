resource "incus_storage_volume" "persist" {
  count        = var.persist_volume ? 1 : 0
  name         = "${var.host}-persist"
  pool         = var.storage_pool
  remote       = var.incus_remote
  content_type = "filesystem"

  dynamic "file" {
    for_each = var.persist_files
    content {
      target_path        = file.value.target_path
      source_path        = lookup(file.value, "source_path", null)
      content            = lookup(file.value, "content", null)
      mode               = lookup(file.value, "mode", "0600")
      uid                = lookup(file.value, "uid", 0)
      gid                = lookup(file.value, "gid", 0)
      create_directories = lookup(file.value, "create_directories", true)
    }
  }
}

resource "incus_instance" "instance" {
  name     = var.host
  type     = var.instance_type
  image    = coalesce(var.image, "nixos/${var.host}")
  remote   = var.incus_remote
  running  = var.running
  profiles = var.profiles
  config   = var.config

  dynamic "device" {
    for_each = var.persist_volume ? [1] : []
    content {
      name = "persist"
      type = "disk"
      properties = {
        pool   = var.storage_pool
        source = incus_storage_volume.persist[0].name
        path   = "/persist"
      }
    }
  }

  dynamic "device" {
    for_each = var.devices
    content {
      name       = device.value.name
      type       = device.value.type
      properties = device.value.properties
    }
  }

  dynamic "file" {
    for_each = var.files
    content {
      target_path        = file.value.target_path
      content            = file.value.content
      mode               = lookup(file.value, "mode", "0600")
      uid                = lookup(file.value, "uid", 0)
      gid                = lookup(file.value, "gid", 0)
      create_directories = lookup(file.value, "create_directories", true)
    }
  }
}
