# terraform/modules/container-apps-config/outputs.tf

output "service_environment_variables" {
  description = "Variables de entorno por servicio para Container Apps"
  value       = local.service_environment_variables
}

output "internal_urls" {
  description = "URLs internas para comunicación entre servicios"
  value       = local.internal_urls
}

output "shared_environment_variables" {
  description = "Variables de entorno compartidas"
  value       = local.shared_environment_variables
}