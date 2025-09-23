# terraform/modules/container-apps/variables.tf
variable "prefix" {
  description = "Prefix para nombres de recursos"
  type        = string
}

variable "location" {
  description = "Región de Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del resource group"
  type        = string
}

variable "microservices" {
  description = "Configuración de microservicios"
  type = map(object({
    subnet_cidr    = string
    allowed_ports  = list(string)
    container_port = number
    cpu_cores     = number
    memory_gb     = number
  }))
}

variable "acr_login_server" {
  description = "ACR login server URL"
  type        = string
}

variable "acr_admin_username" {
  description = "ACR admin username"
  type        = string
  sensitive   = true
}

variable "acr_admin_password" {
  description = "ACR admin password"
  type        = string
  sensitive   = true
}

# NUEVA VARIABLE (trabajo de tu compañero)
variable "service_environment_variables" {
  description = "Variables de entorno por servicio (desde container-apps-config)"
  type        = map(map(string))
}

variable "jwt_secret" {
  description = "JWT secret para autenticación entre servicios"
  type        = string
  default     = "myfancysecret"
  sensitive   = true
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
}