output "name" {
  description = "Instance name"
  value       = incus_instance.instance.name
}

output "status" {
  description = "Instance status"
  value       = incus_instance.instance.status
}

output "ipv4_address" {
  description = "Instance IPv4 address"
  value       = incus_instance.instance.ipv4_address
}
