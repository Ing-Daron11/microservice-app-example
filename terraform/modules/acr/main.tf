# terraform/modules/acr/main.tf
resource "azurerm_container_registry" "main" {
  name                = "${var.prefix}acr${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = true

  # Configuración específica para estudiante
  public_network_access_enabled = true
  zone_redundancy_enabled       = false # Ahorro de costos

  tags = var.tags
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Output de las credenciales (necesarias para push/pull)
output "login_server" {
  description = "ACR login server URL"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "ACR admin username"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "ACR admin password"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "name" {
  description = "ACR name"
  value       = azurerm_container_registry.main.name
}

output "id" {
  description = "ACR resource ID"
  value       = azurerm_container_registry.main.id
}