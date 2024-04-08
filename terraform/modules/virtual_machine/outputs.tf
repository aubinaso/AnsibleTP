output "virtual_machine_id" {
  value = azurerm_linux_virtual_machine.virtualmachine.id
}

output "virtual_machine_name" {
  value = azurerm_linux_virtual_machine.virtualmachine.name
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "private_ip_address" {
  value = azurerm_network_interface.nic.private_ip_address
}