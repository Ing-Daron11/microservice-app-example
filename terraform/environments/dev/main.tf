# terraform/environments/dev/main.tf
terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

# Configurar el provider de Azure (automático con az login)
provider "azurerm" {
  features {}
  # subscription_id y tenant_id se toman automáticamente de az login
}

# Variables locales optimizadas para estudiante
locals {
  environment = "dev"
  prefix      = "microapp-${local.environment}"
  
  # Configuración específica para Container Apps (más económico que VMs)
  microservices = {
    frontend = {
      subnet_cidr    = "10.0.1.0/24"
      allowed_ports  = ["80", "443"]
      container_port = 80
      cpu_cores     = 0.25
      memory_gb     = 0.5
    }
    auth-api = {
      subnet_cidr    = "10.0.2.0/24"
      allowed_ports  = ["8081"]
      container_port = 8081
      cpu_cores     = 0.25
      memory_gb     = 0.5
    }
    users-api = {
      subnet_cidr    = "10.0.3.0/24"
      allowed_ports  = ["8083"]
      container_port = 8083
      cpu_cores     = 0.25
      memory_gb     = 0.5
    }
    todos-api = {
      subnet_cidr    = "10.0.4.0/24"
      allowed_ports  = ["8082"]
      container_port = 8082
      cpu_cores     = 0.5  # Más CPU para cache Redis
      memory_gb     = 1.0
    }
    shared-services = {
      subnet_cidr    = "10.0.5.0/24"
      allowed_ports  = ["6379", "9411"]
      container_port = 6379
      cpu_cores     = 0.25
      memory_gb     = 0.5
    }
  }
  
  common_tags = {
    Environment    = local.environment
    Project        = "microservice-app"
    CreatedBy      = "terraform"
    Owner          = "student-icesi"
    University     = "icesi"
    CostCenter     = "azure-for-students"
    AutoShutdown   = "true"
  }
}

# Resource group (ya existente)
module "resource_group" {
  source = "../../modules/resource-group"
  
  resource_group_name = "rg-${local.prefix}-student"
  location           = "East US"
  environment        = local.environment
  tags               = local.common_tags
}

# Azure Container Registry
module "acr" {
  source = "../../modules/acr"
  
  prefix              = replace(local.prefix, "-", "") # ACR no acepta guiones
  resource_group_name = module.resource_group.name
  location           = module.resource_group.location
  sku                = "Basic" # Más económico para estudiantes
  tags               = local.common_tags
}

# Networking
module "networking" {
  source = "../../modules/networking"
  
  prefix              = local.prefix
  location           = module.resource_group.location
  resource_group_name = module.resource_group.name
  microservices      = local.microservices
  tags               = local.common_tags
}