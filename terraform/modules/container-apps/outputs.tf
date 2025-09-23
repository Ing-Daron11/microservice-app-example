# terraform/modules/container-apps/outputs.tf
output "container_app_environment_id" {
  description = "ID del Container App Environment"
  value       = azurerm_container_app_environment.main.id
}

output "container_app_environment_name" {
  description = "Nombre del Container App Environment"
  value       = azurerm_container_app_environment.main.name
}

output "log_analytics_workspace_id" {
  description = "ID del Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "frontend_url" {
  description = "URL pública del frontend"
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "zipkin_url" {
  description = "URL pública de Zipkin para tracing"
  value       = "https://${azurerm_container_app.zipkin.ingress[0].fqdn}"
}

output "container_apps" {
  description = "URLs de todos los Container Apps"
  value = {
    frontend                = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
    zipkin                  = "https://${azurerm_container_app.zipkin.ingress[0].fqdn}"
    auth_api_internal       = "http://${var.prefix}-auth-api"
    users_api_internal      = "http://${var.prefix}-users-api"
    todos_api_internal      = "http://${var.prefix}-todos-api"
    redis_internal          = "${var.prefix}-redis"
    log_processor_internal  = "Internal service (no external access)"
  }
}

output "service_endpoints" {
  description = "Endpoints de servicios para configuración"
  value = {
    frontend_public    = azurerm_container_app.frontend.ingress[0].fqdn
    zipkin_public      = azurerm_container_app.zipkin.ingress[0].fqdn
    auth_api_internal  = "${var.prefix}-auth-api"
    users_api_internal = "${var.prefix}-users-api"
    todos_api_internal = "${var.prefix}-todos-api"
    redis_internal     = "${var.prefix}-redis"
  }
}

output "cost_summary" {
  description = "Resumen de costos estimados"
  value = {
    container_apps_count     = 6
    total_cpu_allocated     = sum([for ms in var.microservices : ms.cpu_cores]) + 0.5  # +0.5 para log-processor
    total_memory_allocated  = "${sum([for ms in var.microservices : ms.memory_gb]) + 0.5}GB"
    estimated_monthly_cost  = "$20-35 USD/month"
    log_analytics_retention = "30 days (minimum cost)"
  }
}