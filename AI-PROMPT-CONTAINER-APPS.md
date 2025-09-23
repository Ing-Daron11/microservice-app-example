# 🤖 PROMPT PARA AGENTE IA - Container Apps

Necesito que crees un módulo Terraform `container-apps` para desplegar microservicios en Azure Container Apps. La configuración de variables de entorno YA ESTÁ LISTA.

## CONTEXTO TÉCNICO

**Proyecto**: Microservicios con Circuit Breaker  
**Infraestructura existente**: Resource Group, ACR, Networking, Variables de entorno  
**Tu tarea**: Crear Container Apps usando la configuración existente  

## MÓDULOS EXISTENTES (NO MODIFICAR)

```
terraform/modules/
├── resource-group/       ✅ LISTO  
├── acr/                 ✅ LISTO
├── networking/          ✅ LISTO
└── container-apps-config/ ✅ LISTO (variables de entorno)
```

## CREAR NUEVO MÓDULO

**Ubicación**: `terraform/modules/container-apps/`

**Archivos a crear**:
- `main.tf` - Container App Environment + Container Apps
- `variables.tf` - Variables de entrada
- `outputs.tf` - Outputs (URLs, domains)

## CONFIGURACIÓN BASE

### Variables de entrada:
```hcl
variable "prefix" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "acr_login_server" { type = string }
variable "microservices_config" { type = map(object({ cpu_cores = number, memory_gb = number, container_port = number })) }
variable "service_environment_variables" { type = map(map(string)) }
variable "infrastructure_subnet_id" { type = string }
variable "tags" { type = map(string) }
```

### Microservicios a crear:

| Servicio | Imagen | Puerto | CPU | Memoria | Ingress |
|----------|--------|--------|-----|---------|---------|
| frontend | ACR/frontend:latest | 80 | 0.25 | 0.5Gi | Externo |
| auth-api | ACR/auth-api:latest | 8081 | 0.25 | 0.5Gi | Interno |
| users-api | ACR/users-api:latest | 8083 | 0.25 | 0.5Gi | Interno |
| todos-api | ACR/todos-api:latest | 8082 | 0.5 | 1.0Gi | Interno |
| log-message-processor | ACR/log-message-processor:latest | - | 0.25 | 0.5Gi | Sin ingress |
| redis | redis:7-alpine | 6379 | 0.25 | 0.5Gi | Interno |
| zipkin | openzipkin/zipkin:latest | 9411 | 0.25 | 0.5Gi | Interno |

## ESTRUCTURA TERRAFORM

```hcl
# Container App Environment
resource "azurerm_container_app_environment" "main" {
  name                     = "${var.prefix}-ca-env"
  location                = var.location
  resource_group_name     = var.resource_group_name
  infrastructure_subnet_id = var.infrastructure_subnet_id
  tags = var.tags
}

# Container Apps para microservicios
resource "azurerm_container_app" "microservices" {
  for_each = var.microservices_config
  
  name                         = "${var.prefix}-${each.key}-ca"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name         = var.resource_group_name
  revision_mode               = "Single"
  
  template {
    container {
      name   = each.key
      image  = "${var.acr_login_server}/${each.key}:latest"
      cpu    = each.value.cpu_cores
      memory = "${each.value.memory_gb}Gi"
      
      # Variables de entorno (YA configuradas)
      dynamic "env" {
        for_each = var.service_environment_variables[each.key]
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }
  
  ingress {
    external_enabled = each.key == "frontend"
    target_port     = each.value.container_port
    
    traffic_weight {
      latest_revision = true
      percentage     = 100
    }
  }
}

# Container Apps para servicios de infraestructura (Redis, Zipkin)
resource "azurerm_container_app" "redis" {
  name                         = "${var.prefix}-redis-ca"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name         = var.resource_group_name
  revision_mode               = "Single"
  
  template {
    container {
      name   = "redis"
      image  = "redis:7-alpine"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }
  
  ingress {
    external_enabled = false
    target_port     = 6379
    
    traffic_weight {
      latest_revision = true
      percentage     = 100
    }
  }
}

resource "azurerm_container_app" "zipkin" {
  name                         = "${var.prefix}-zipkin-ca"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name         = var.resource_group_name
  revision_mode               = "Single"
  
  template {
    container {
      name   = "zipkin"
      image  = "openzipkin/zipkin:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      
      env {
        name  = "STORAGE_TYPE"
        value = "mem"
      }
    }
  }
  
  ingress {
    external_enabled = false
    target_port     = 9411
    
    traffic_weight {
      latest_revision = true
      percentage     = 100
    }
  }
}
```

## OUTPUTS REQUERIDOS

```hcl
output "container_app_environment_domain" {
  value = azurerm_container_app_environment.main.default_domain
}

output "container_app_urls" {
  value = {
    for k, v in azurerm_container_app.microservices : k => v.latest_revision_fqdn
  }
}

output "frontend_url" {
  value = "https://${azurerm_container_app.microservices["frontend"].latest_revision_fqdn}"
}
```

## USO EN main.tf

```hcl
module "container_apps" {
  source = "../../modules/container-apps"
  
  prefix              = local.prefix
  location           = module.resource_group.location
  resource_group_name = module.resource_group.name
  acr_login_server   = module.acr.login_server
  microservices_config = local.microservices
  service_environment_variables = module.container_apps_config.service_environment_variables
  infrastructure_subnet_id = module.networking.subnet_ids["shared-services"]
  tags = local.common_tags
}
```

## PUNTOS CRÍTICOS

1. **DNS Interno**: Las URLs internas usan formato `<app>.internal.<domain>`
2. **Circuit Breaker**: auth-api debe conectar a users-api internamente
3. **Solo frontend externo**: Los demás servicios son internos
4. **Variables ya listas**: Usa `var.service_environment_variables` tal como viene

## VALIDACIÓN

Después de crear, verificar:
- Container App Environment creado con subnet
- 7 Container Apps (5 microservicios + redis + zipkin)
- Solo frontend con ingress externo
- Variables de entorno aplicadas correctamente

¿Entiendes el contexto? Crear módulo container-apps usando la configuración existente.