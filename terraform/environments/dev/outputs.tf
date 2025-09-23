# terraform/environments/dev/outputs.tf
output "resource_group_name" {
  description = "Nombre del resource group creado"
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "Ubicación del resource group"
  value       = module.resource_group.location
}

output "acr_name" {
  description = "Nombre del Azure Container Registry"
  value       = module.acr.name
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = module.acr.login_server
}

output "acr_admin_username" {
  description = "ACR admin username"
  value       = module.acr.admin_username
  sensitive   = true
}

# Networking outputs (NUEVO)
output "vnet_name" {
  description = "Nombre de la virtual network"
  value       = module.networking.vnet_name
}

output "subnet_ids" {
  description = "IDs de las subnets por microservicio"
  value       = module.networking.subnet_ids
}

output "microservices_config" {
  description = "Configuración de microservicios para Container Apps"
  value       = local.microservices
}

output "subscription_info" {
  description = "Información de la suscripción de estudiante"
  value = {
    subscription_id   = var.student_subscription_id
    subscription_name = "Azure for Students"
    university        = "Universidad Icesi"
    tenant_id         = var.tenant_id
  }
}

output "cost_optimization" {
  description = "Configuraciones de optimización de costos"
  value = {
    acr_sku                = "Basic"
    container_apps_planned = true
    estimated_monthly_cost = "$15-25 USD"
    total_cpu_cores       = sum([for ms in local.microservices : ms.cpu_cores])
    total_memory_gb       = sum([for ms in local.microservices : ms.memory_gb])
  }
}


# Container Apps outputs (NUEVO)
output "container_apps_environment" {
  description = "Container Apps Environment información"
  value = {
    id   = module.container_apps.container_app_environment_id
    name = module.container_apps.container_app_environment_name
  }
}

output "application_urls" {
  description = "URLs de la aplicación desplegada"
  value = module.container_apps.container_apps
}

output "frontend_url" {
  description = "URL principal de la aplicación"
  value       = module.container_apps.frontend_url
}

output "zipkin_url" {
  description = "URL de Zipkin para distributed tracing"
  value       = module.container_apps.zipkin_url
}

output "deployment_summary" {
  description = "Resumen completo del deployment"
  value = {
    infrastructure = {
      resource_group = module.resource_group.name
      location       = module.resource_group.location
      acr_name       = module.acr.name
      vnet_name      = module.networking.vnet_name
    }
    application = {
      frontend_url = module.container_apps.frontend_url
      zipkin_url   = module.container_apps.zipkin_url
      services     = length(local.microservices)
    }
    costs = module.container_apps.cost_summary
  }
}