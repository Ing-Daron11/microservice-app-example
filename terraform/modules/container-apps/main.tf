# terraform/modules/container-apps/main.tf - VERSIÓN CORREGIDA
resource "azurerm_container_app_environment" "main" {
  name                       = "${var.prefix}-env"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = var.tags
}

# Log Analytics para Container Apps
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.prefix}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Redis Container App (shared service) - SIN INGRESS
resource "azurerm_container_app" "redis" {
  name                         = "${var.prefix}-redis-ca"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "redis"
      image  = "redis:7-alpine"
      cpu    = 0.25
      memory = "0.5Gi"

      # Variables de entorno desde el módulo de tu compañero
      dynamic "env" {
        for_each = var.service_environment_variables["redis"]
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    min_replicas = 1
    max_replicas = 1
  }

  # Redis NO necesita ingress - solo comunicación interna
  tags = var.tags
}

# Zipkin Container App
resource "azurerm_container_app" "zipkin" {
  name                         = "${var.prefix}-zipkin-ca"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "zipkin"
      image  = "openzipkin/zipkin:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      # Variables de entorno desde el módulo de tu compañero
      dynamic "env" {
        for_each = var.service_environment_variables["zipkin"]
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    min_replicas = 1
    max_replicas = 1
  }

  ingress {
    external_enabled = true  # Público para que puedan ver trazas
    target_port      = 9411

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}


# Microservicios usando configuración dinámica
resource "azurerm_container_app" "microservices" {
  for_each = { for k, v in var.microservices : k => v if k != "shared-services" }

  name                         = "${var.prefix}-${each.key}-ca"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = each.key
      image  = "${var.acr_login_server}/${each.key}:latest"
      cpu    = each.value.cpu_cores
      memory = "${each.value.memory_gb}Gi"

      # Variables de entorno desde el módulo
      dynamic "env" {
        for_each = var.service_environment_variables[each.key]
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = each.key == "frontend" ? true : false
    target_port      = 80  # IMPORTANTE: Todos los servicios usan puerto 80 en Container Apps

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  secret {
    name  = "acr-password"
    value = var.acr_admin_password
  }

  registry {
    server   = var.acr_login_server
    username = var.acr_admin_username
    password_secret_name = "acr-password"
  }

  tags = var.tags

  depends_on = [azurerm_container_app.redis, azurerm_container_app.zipkin]
}

#=====  No borrar Miguel!!!   ======
# Status Service Container App 
 resource "azurerm_container_app" "status_service" {
   name                         = "${var.prefix}-status-service-ca"
   container_app_environment_id = azurerm_container_app_environment.main.id
   resource_group_name          = var.resource_group_name
   revision_mode                = "Single"

   template {
     container {
       name   = "status-service"
       image  = "${var.acr_login_server}/status-service:latest"
       cpu    = 0.25
       memory = "0.5Gi"
     }

     min_replicas = 1
     max_replicas = 1
   }

   ingress {
     allow_insecure_connections = false
     external_enabled           = true
     target_port                = 3000

     traffic_weight {
       percentage      = 100
       latest_revision = true
     }
   }

   secret {
     name  = "acr-password"
     value = var.acr_admin_password
   }

   registry {
     server   = var.acr_login_server
     username = var.acr_admin_username
     password_secret_name = "acr-password"
   }

   tags = var.tags
 }

