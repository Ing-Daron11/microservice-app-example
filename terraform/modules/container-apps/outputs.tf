# terraform/modules/container-apps/outputs.tf
output "container_app_environment_id" {
  description = "ID del Container App Environment"
  value       = azurerm_container_app_environment.main.id
}

output "container_app_environment_name" {
  description = "Nombre del Container App Environment"
  value       = azurerm_container_app_environment.main.name
}

output "container_app_environment_domain" {
  description = "Dominio del Container App Environment"
  value       = azurerm_container_app_environment.main.default_domain
}

output "frontend_url" {
  description = "URL pública del frontend"
  value       = "https://${azurerm_container_app.microservices["frontend"].ingress[0].fqdn}"
}

output "zipkin_url" {
  description = "URL pública de Zipkin para tracing"
  value       = "https://${azurerm_container_app.zipkin.ingress[0].fqdn}"
}

output "container_apps" {
  description = "URLs de todos los Container Apps"
  value = merge(
    {
      for k, v in azurerm_container_app.microservices : k => v.ingress[0].fqdn
    },
    {
      zipkin = azurerm_container_app.zipkin.ingress[0].fqdn
      redis  = "${var.prefix}-redis-ca.internal.${azurerm_container_app_environment.main.default_domain}"
      log_processor = "Internal service (no external access)"
    }
  )
}