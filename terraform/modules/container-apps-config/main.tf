
# Variables locales para URLs internas de Container Apps
locals {
  
  # URLs internas (comunicación entre Container Apps)
  internal_urls = {
    users_api = "http://users-api:80"
    auth_api  = "http://auth-api:80"
    todos_api = "http://todos-api:80"
    redis     = "http://redis:6379"
    zipkin    = "http://zipkin:80"
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

    })
    
    # AUTH-API (Go)
    auth-api = merge(local.shared_environment_variables, {
      AUTH_API_PORT     = "8081"
      USERS_API_ADDRESS = "${local.internal_urls.users_api}"
      ZIPKIN_URL        = "${local.internal_urls.zipkin}/api/v2/spans"
    })
    
    # USERS-API (Java Spring Boot)
    users-api = merge(local.shared_environment_variables, {
      SERVER_PORT                           = "8083"
      SPRING_PROFILES_ACTIVE               = "docker"
      SPRING_ZIPKIN_BASE_URL               = "${local.internal_urls.zipkin}"
      SPRING_SLEUTH_SAMPLER_PERCENTAGE     = "100.0"
      SPRING_DATASOURCE_URL                = "jdbc:h2:mem:testdb"
      SPRING_H2_CONSOLE_ENABLED            = "true"
    })
    
    # TODOS-API (Node.js)
    todos-api = merge(local.shared_environment_variables, {
      TODO_API_PORT = "8082"
      REDIS_HOST    = "${replace(local.internal_urls.redis, "http://", "")}"
      REDIS_PORT    = "6379"
      REDIS_CHANNEL = "log_channel"
      ZIPKIN_URL    = "${local.internal_urls.zipkin}/api/v2/spans"
    })
    
    # LOG-MESSAGE-PROCESSOR (Python)
    log-message-processor = merge(local.shared_environment_variables, {
      REDIS_HOST         = "${replace(local.internal_urls.redis, "http://", "")}"  # Solo el hostname
      REDIS_PORT         = "6379"
      REDIS_CHANNEL      = "log_channel"
      ZIPKIN_URL         = "${local.internal_urls.zipkin}/api/v2/spans"
      PYTHONUNBUFFERED   = "1"
    })
  
    # ZIPKIN
    zipkin = {
      STORAGE_TYPE = "mem"
    }
  }
}
