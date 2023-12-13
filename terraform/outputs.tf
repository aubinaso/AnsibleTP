output "public_ip_address" {
  value = module.virtual_machine[*].public_ip_address
}

output "private_ip_address" {
  value = module.virtual_machine[*].private_ip_address
}