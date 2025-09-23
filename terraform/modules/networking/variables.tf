# terraform/modules/networking/variables.tf
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
  description = "Configuración de microservicios para Container Apps"
  type = map(object({
    subnet_cidr    = string
    allowed_ports  = list(string)
    container_port = number
    cpu_cores     = number
    memory_gb     = number
  }))
}

variable "tags" {
  description = "Tags para los recursos"
  type        = map(string)
  default     = {}
}