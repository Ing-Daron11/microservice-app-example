# [variables.tf](http://_vscodecontentref_/0)
variable "prefix" {
  description = "Prefix para el nombre del ACR"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del resource group"
  type        = string
}

variable "location" {
  description = "Ubicación de Azure"
  type        = string
}

variable "sku" {
  description = "SKU del ACR (Basic para estudiantes)"
  type        = string
  default     = "Basic"
  
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU debe ser Basic, Standard o Premium."
  }
}

variable "tags" {
  description = "Tags para el recurso"
  type        = map(string)
  default     = {}
}