# terraform/environments/dev/variables.tf
variable "student_subscription_id" {
  description = "Azure for Students Subscription ID"
  type        = string
  default     = "270b4efe-9ebd-44f7-ab7e-a468a5d58e77"
}

variable "tenant_id" {
  description = "Tenant ID de Universidad Icesi"
  type        = string
  default     = "e994072b-523e-4bfe-86e2-442c5e10b244"
}

variable "vm_auto_shutdown" {
  description = "Configurar auto-apagado para ahorrar costos"
  type        = bool
  default     = true
}

variable "max_vm_count" {
  description = "Máximo número de VMs para evitar costos excesivos"
  type        = number
  default     = 5
}

variable "vm_size_student" {
  description = "Tamaño de VM optimizado para estudiante (bajo costo)"
  type        = string
  default     = "Standard_B1s"  # 1 vCPU, 1GB RAM - ~$7.59/mes
}