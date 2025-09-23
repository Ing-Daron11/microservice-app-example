# terraform/modules/resource-group/outputs.tf
output "name" {
  description = "Nombre del resource group"
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Ubicación del resource group"
  value       = azurerm_resource_group.main.location
}

output "id" {
  description = "ID del resource group"
  value       = azurerm_resource_group.main.id
}

output "tags" {
  description = "Tags del resource group"
  value       = azurerm_resource_group.main.tags
}