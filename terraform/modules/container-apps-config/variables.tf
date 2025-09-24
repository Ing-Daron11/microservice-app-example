# terraform/modules/container-apps-config/variables.tf

variable "prefix" {
  description = "Prefijo para nombres de recursos"
  type        = string
}

variable "container_app_environment_domain" {
  description = "Dominio del Container App Environment (ejemplo: proudsky-12345.eastus.azurecontainerapps.io)"
  type        = string
}

variable "jwt_secret" {
  description = "Secret para JWT tokens"
  type        = string
  default     = "myfancysecret"
  sensitive   = true
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
}