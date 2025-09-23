# Variables locales para URLs internas de Container Apps
locals {
  
  # URLs internas - TODAS usan puerto 80 en Container Apps
  internal_urls = {
    users_api = "http://microapp-dev-users-api-ca:80"
    auth_api  = "http://microapp-dev-auth-api-ca:80"
    todos_api = "http://microapp-dev-todos-api-ca:80"
    redis     = "microapp-dev-redis-ca:6379"  # Redis sí usa 6379
    zipkin    = "http://microapp-dev-zipkin-ca:80"  # Zipkin también puerto 80
  }
  
  # Variables compartidas por todos los servicios
  shared_environment_variables = {
    JWT_SECRET = var.jwt_secret
    ZIPKIN_URL = "${local.internal_urls.zipkin}/api/v2/spans"
    NODE_ENV   = "production"
  }
  
  # Variables específicas por microservicio
  service_environment_variables = {
    
    # FRONTEND
    frontend = merge(local.shared_environment_variables, {
      # Frontend no necesita variables específicas, usa nginx.conf para proxy
    })
    
    # AUTH-API (Go) - PUERTO 80 para Container Apps
    auth-api = merge(local.shared_environment_variables, {
      AUTH_API_PORT     = "80"
      USERS_API_ADDRESS = "${local.internal_urls.users_api}"
      ZIPKIN_URL        = "${local.internal_urls.zipkin}/api/v2/spans"
    })
    
    # USERS-API (Java Spring Boot) - PUERTO 80
    users-api = merge(local.shared_environment_variables, {
      SERVER_PORT                           = "80"
      SPRING_PROFILES_ACTIVE               = "docker"
      SPRING_ZIPKIN_BASE_URL               = "${local.internal_urls.zipkin}"
      SPRING_SLEUTH_SAMPLER_PERCENTAGE     = "1.0"
      SPRING_DATASOURCE_URL                = "jdbc:h2:mem:testdb"
      SPRING_H2_CONSOLE_ENABLED            = "true"
    })
    
    # TODOS-API (Node.js) - PUERTO 80
    todos-api = merge(local.shared_environment_variables, {
      TODO_API_PORT = "80"
      REDIS_HOST    = "microapp-dev-redis-ca"
      REDIS_PORT    = "6379"
      REDIS_CHANNEL = "log_channel"
      ZIPKIN_URL    = "${local.internal_urls.zipkin}/api/v2/spans"
    })
    
    # LOG-MESSAGE-PROCESSOR (Python)
    log-message-processor = merge(local.shared_environment_variables, {
      REDIS_HOST         = "microapp-dev-redis-ca"
      REDIS_PORT         = "6379"
      REDIS_CHANNEL      = "log_channel"
      ZIPKIN_URL         = "${local.internal_urls.zipkin}/api/v2/spans"
      PYTHONUNBUFFERED   = "1"
    })
  
    # ZIPKIN - También puerto 80
    zipkin = {
      STORAGE_TYPE = "mem"
    }
    
    # REDIS
    redis = {
      # Redis no necesita variables especiales
    }
  }
}