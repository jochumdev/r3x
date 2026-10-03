host = "dev01"

config = {
  "security.nesting"    = "true"
  "security.privileged" = "true"
}

devices = [
  {
    name = "eth0"
    type = "nic"
    properties = {
      network        = "incusbr0"
      "ipv4.address" = "10.90.190.81"
    }
  },
  {
    name = "projects"
    type = "disk"
    properties = {
      source = "/home/r3j0/projects"
      path   = "/home/r3j0/projects"
      shift  = "true"
    }
  },
  {
    name = "vendor"
    type = "disk"
    properties = {
      source = "/home/r3j0/vendor"
      path   = "/home/r3j0/vendor"
      shift  = "true"
    }
  }
]
