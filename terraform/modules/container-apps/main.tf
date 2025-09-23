# terraform/modules/container-apps/main.tf
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
  retention_in_days   = 30  # Mínimo para ahorrar costos

  tags = var.tags
}

# Redis Container App (shared service) - SIN INGRESS
resource "azurerm_container_app" "redis" {
  name                         = "${var.prefix}-redis"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "redis"
      image  = "redis:7-alpine"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "REDIS_SAVE"
        value = ""  # Disable persistence for demo
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
  name                         = "${var.prefix}-zipkin"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

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

    min_replicas = 1
    max_replicas = 1
  }

  ingress {
    external_enabled = true
    target_port      = 9411

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = var.tags
}

# Users API Container App
resource "azurerm_container_app" "users_api" {
  name                         = "${var.prefix}-users-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "users-api"
      image  = "${var.acr_login_server}/users-api:latest"
      cpu    = var.microservices["users-api"].cpu_cores
      memory = "${var.microservices["users-api"].memory_gb}Gi"

      env {
        name  = "SERVER_PORT"
        value = tostring(var.microservices["users-api"].container_port)
      }
      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }
      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "azure"
      }
      env {
        name  = "SPRING_ZIPKIN_BASE_URL"
        value = "http://${var.prefix}-zipkin"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = false
    target_port      = var.microservices["users-api"].container_port

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

  depends_on = [azurerm_container_app.zipkin]
}

# Auth API Container App
resource "azurerm_container_app" "auth_api" {
  name                         = "${var.prefix}-auth-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "auth-api"
      image  = "${var.acr_login_server}/auth-api:latest"
      cpu    = var.microservices["auth-api"].cpu_cores
      memory = "${var.microservices["auth-api"].memory_gb}Gi"

      env {
        name  = "AUTH_API_PORT"
        value = tostring(var.microservices["auth-api"].container_port)
      }
      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }
      env {
        name  = "USERS_API_ADDRESS"
        value = "http://${var.prefix}-users-api"
      }
      env {
        name  = "ZIPKIN_URL"
        value = "http://${var.prefix}-zipkin:9411/api/v2/spans"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = false
    target_port      = var.microservices["auth-api"].container_port

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

  depends_on = [azurerm_container_app.users_api]
}

# Todos API Container App (con Cache-Aside)
resource "azurerm_container_app" "todos_api" {
  name                         = "${var.prefix}-todos-api"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "todos-api"
      image  = "${var.acr_login_server}/todos-api:latest"
      cpu    = var.microservices["todos-api"].cpu_cores
      memory = "${var.microservices["todos-api"].memory_gb}Gi"

      env {
        name  = "TODO_API_PORT"
        value = tostring(var.microservices["todos-api"].container_port)
      }
      env {
        name  = "JWT_SECRET"
        value = var.jwt_secret
      }
      env {
        name  = "REDIS_HOST"
        value = "${var.prefix}-redis"
      }
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      env {
        name  = "REDIS_CHANNEL"
        value = "log_channel"
      }
      env {
        name  = "ZIPKIN_URL"
        value = "http://${var.prefix}-zipkin:9411/api/v2/spans"
      }
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = false
    target_port      = var.microservices["todos-api"].container_port

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

  depends_on = [azurerm_container_app.redis, azurerm_container_app.auth_api]
}

# Log Message Processor Container App
resource "azurerm_container_app" "log_processor" {
  name                         = "${var.prefix}-log-processor"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "log-processor"
      image  = "${var.acr_login_server}/log-message-processor:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "REDIS_HOST"
        value = "${var.prefix}-redis"
      }
      env {
        name  = "REDIS_PORT"
        value = "6379"
      }
      env {
        name  = "REDIS_CHANNEL"
        value = "log_channel"
      }
      env {
        name  = "ZIPKIN_URL"
        value = "http://${var.prefix}-zipkin:9411/api/v2/spans"
      }
    }

    min_replicas = 1
    max_replicas = 1
  }

  # Log processor NO necesita ingress - solo procesamiento interno

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

  depends_on = [azurerm_container_app.redis]
}

# Frontend Container App
resource "azurerm_container_app" "frontend" {
  name                         = "${var.prefix}-frontend"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  template {
    container {
      name   = "frontend"
      image  = "${var.acr_login_server}/frontend:latest"
      cpu    = var.microservices["frontend"].cpu_cores
      memory = "${var.microservices["frontend"].memory_gb}Gi"

      # El frontend Vue.js obtiene las URLs desde el nginx.conf
      # No necesita variables de entorno de APIs internas
    }

    min_replicas = 1
    max_replicas = 3
  }

  ingress {
    external_enabled = true
    target_port      = var.microservices["frontend"].container_port

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

  depends_on = [
    azurerm_container_app.auth_api,
    azurerm_container_app.todos_api,
    azurerm_container_app.users_api
  ]
}