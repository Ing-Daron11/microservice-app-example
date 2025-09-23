# terraform/modules/container-apps-config/main.tf
# Configuración de variables de entorno para Container Apps
# Autor: DevOps Team para microservicios

# Variables locales para URLs internas de Container Apps
locals {
  # DNS interno de Container Apps: <app-name>.internal.<environment-default-domain>
  # Ejemplo: microapp-dev-auth-api-ca.internal.proudsky-12345678.eastus.azurecontainerapps.io
  
  # URLs internas (comunicación entre Container Apps)
  internal_urls = {
    users_api = "http://${var.prefix}-users-api-ca.internal.${var.container_app_environment_domain}"
    auth_api  = "http://${var.prefix}-auth-api-ca.internal.${var.container_app_environment_domain}"
    todos_api = "http://${var.prefix}-todos-api-ca.internal.${var.container_app_environment_domain}"
    redis     = "http://${var.prefix}-redis-ca.internal.${var.container_app_environment_domain}"
    zipkin    = "http://${var.prefix}-zipkin-ca.internal.${var.container_app_environment_domain}"
  }
  
  # URLs externas (acceso desde frontend - HTTPS automático)
  external_urls = {
    auth_api  = "https://${var.prefix}-auth-api-ca.${var.container_app_environment_domain}"
    todos_api = "https://${var.prefix}-todos-api-ca.${var.container_app_environment_domain}"
    users_api = "https://${var.prefix}-users-api-ca.${var.container_app_environment_domain}"
    frontend  = "https://${var.prefix}-frontend-ca.${var.container_app_environment_domain}"
  }
  
  # Variables compartidas por todos los servicios
  shared_environment_variables = {
    JWT_SECRET = var.jwt_secret
    ZIPKIN_URL = "${local.internal_urls.zipkin}:9411/api/v2/spans"
    NODE_ENV   = "production"
  }
  
  # Variables específicas por microservicio
  service_environment_variables = {
    
    # 🎨 FRONTEND
    frontend = merge(local.shared_environment_variables, {
      # El frontend usa nginx y proxy reverso
      # Las llamadas van a rutas relativas que nginx redirige
    })
    
    # 🔐 AUTH-API (Go)
    auth-api = merge(local.shared_environment_variables, {
      AUTH_API_PORT     = "8081"
      USERS_API_ADDRESS = "${local.internal_urls.users_api}:8083"  # ⚡ CRÍTICO para Circuit Breaker
      ZIPKIN_URL        = "${local.internal_urls.zipkin}:9411/api/v2/spans"
    })
    
    # 👥 USERS-API (Java Spring Boot)
    users-api = merge(local.shared_environment_variables, {
      SERVER_PORT                           = "8083"
      SPRING_PROFILES_ACTIVE               = "docker"
      SPRING_ZIPKIN_BASE_URL               = "${local.internal_urls.zipkin}:9411/"
      SPRING_SLEUTH_SAMPLER_PERCENTAGE     = "100.0"
      SPRING_DATASOURCE_URL                = "jdbc:h2:mem:testdb"
      SPRING_H2_CONSOLE_ENABLED            = "true"
    })
    
    # ✅ TODOS-API (Node.js)
    todos-api = merge(local.shared_environment_variables, {
      TODO_API_PORT = "8082"
      REDIS_HOST    = "${replace(local.internal_urls.redis, "http://", "")}"  # Solo el hostname
      REDIS_PORT    = "6379"
      REDIS_CHANNEL = "log_channel"
      ZIPKIN_URL    = "${local.internal_urls.zipkin}:9411/api/v2/spans"
    })
    
    # 📝 LOG-MESSAGE-PROCESSOR (Python)
    log-message-processor = merge(local.shared_environment_variables, {
      REDIS_HOST         = "${replace(local.internal_urls.redis, "http://", "")}"  # Solo el hostname
      REDIS_PORT         = "6379"
      REDIS_CHANNEL      = "log_channel"
      ZIPKIN_URL         = "${local.internal_urls.zipkin}:9411/api/v2/spans"
      PYTHONUNBUFFERED   = "1"
    })
    
    # 🔴 REDIS
    redis = {
      # Redis no necesita variables especiales
    }
    
    # 🔍 ZIPKIN
    zipkin = {
      STORAGE_TYPE = "mem"
    }
  }
}

# 🎯 EXPLICACIÓN DETALLADA:
#
# 1. **DNS Interno Container Apps:**
#    - Formato: <app-name>.internal.<environment-domain>
#    - Solo accesible desde dentro del mismo Container App Environment
#    - Ejemplo: microapp-dev-auth-api-ca.internal.proudsky-12345.eastus.azurecontainerapps.io
#
# 2. **Variables críticas para Circuit Breaker:**
#    - USERS_API_ADDRESS en auth-api DEBE apuntar a la URL interna de users-api
#    - Esto permite que el Circuit Breaker funcione igual que en local
#
# 3. **Redis y Zipkin:**
#    - Se comportan como servicios internos
#    - Redis: solo hostname (sin http://) para las conexiones
#    - Zipkin: URL completa para el tracing
#
# 4. **Frontend:**
#    - Usa nginx como proxy reverso
#    - Las llamadas a /login y /api/* se redirigen a los servicios correspondientes
#
# 5. **Ports mapping:**
#    - auth-api: 8081
#    - users-api: 8083  
#    - todos-api: 8082
#    - redis: 6379
#    - zipkin: 9411