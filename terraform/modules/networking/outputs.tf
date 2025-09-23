# terraform/modules/networking/outputs.tf
output "vnet_id" {
  description = "ID de la virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Nombre de la virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_ids" {
  description = "IDs de las subnets creadas"
  value = {
    for k, v in azurerm_subnet.microservices : k => v.id
  }
}

output "subnet_names" {
  description = "Nombres de las subnets"
  value = {
    for k, v in azurerm_subnet.microservices : k => v.name
  }
}

output "nsg_ids" {
  description = "IDs de los Network Security Groups"
  value = {
    for k, v in azurerm_network_security_group.microservices : k => v.id
  }
}