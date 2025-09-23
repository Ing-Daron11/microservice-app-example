# 🔄 Configuración de Variables de Entorno para Container Apps

## 📋 Resumen

Este módulo (`container-apps-config`) contiene toda la configuración de variables de entorno necesaria para que los microservicios se comuniquen correctamente en Azure Container Apps, manteniendo la misma funcionalidad que en local.

## 🎯 Objetivos Logrados

✅ **Circuit Breaker funcionando**: Auth-API → Users-API con URLs internas  
✅ **Comunicación Redis**: Todos-API y Log-Processor → Redis  
✅ **Trazas Zipkin**: Todos los servicios → Zipkin  
✅ **Frontend Proxy**: Nginx redirige /login y /api/* a servicios internos  
✅ **Variables específicas**: Cada microservicio tiene su configuración optimizada  

## 🏗️ Estructura Creada

```
terraform/modules/container-apps-config/
├── main.tf           # Configuración principal de variables
├── variables.tf      # Variables de entrada del módulo
├── outputs.tf        # Outputs para usar en Container Apps
└── nginx.conf        # Configuración de proxy para frontend
```

## 🔧 Cómo Usar en Container Apps

### 1. **Obtener las Variables**

Después de aplicar Terraform:

```bash
cd terraform/environments/dev
terraform output service_environment_variables
```

### 2. **Aplicar en Container Apps**

Para cada Container App, usar las variables del output correspondiente:

```terraform
# Ejemplo para auth-api Container App
resource "azurerm_container_app" "auth_api" {
  # ... configuración básica ...
  
  template {
    container {
      name  = "auth-api"
      image = "${var.acr_login_server}/auth-api:latest"
      
      # ⚡ CRÍTICO: Variables de entorno para Circuit Breaker
      env {
        name  = "USERS_API_ADDRESS"
        value = "http://microapp-dev-users-api-ca.internal.${var.container_app_environment_domain}:8083"
      }
      
      env {
        name  = "AUTH_API_PORT"
        value = "8081"
      }
      
      env {
        name  = "JWT_SECRET"
        value = "myfancysecret"
      }
      
      env {
        name  = "ZIPKIN_URL"
        value = "http://microapp-dev-zipkin-ca.internal.${var.container_app_environment_domain}:9411/api/v2/spans"
      }
    }
  }
}
```

### 3. **Configurar Frontend con Nginx**

El frontend necesita la configuración de `nginx.conf` para proxy reverso:

```dockerfile
# En el Dockerfile del frontend
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

## 🌐 Mapeo de Comunicación

### Local (Docker Compose) → Azure (Container Apps)

| Local | Azure Container Apps |
|-------|---------------------|
| `http://users-api:8083` | `http://microapp-dev-users-api-ca.internal.<domain>:8083` |
| `redis:6379` | `microapp-dev-redis-ca.internal.<domain>:6379` |
| `http://zipkin:9411` | `http://microapp-dev-zipkin-ca.internal.<domain>:9411` |

### URLs Internas vs Externas

- **Internas**: `<app>.internal.<domain>` - Solo entre Container Apps
- **Externas**: `<app>.<domain>` - Acceso desde internet (HTTPS automático)

## ⚡ Circuit Breaker - Configuración Crítica

El Circuit Breaker en `auth-api` **DEBE** tener:

```bash
USERS_API_ADDRESS=http://microapp-dev-users-api-ca.internal.<domain>:8083
```

### ¿Por qué es crítico?

1. **URL interna**: Comunicación directa entre Container Apps
2. **Puerto 8083**: Puerto específico del users-api  
3. **Dominio interno**: Solo accesible dentro del Container App Environment
4. **Mismo comportamiento**: Funciona igual que `http://users-api:8083` en local

## 🔍 Validación

Ejecutar el script de validación:

```bash
./scripts/validate-circuit-breaker.sh
```

## 📝 Checklist para Container Apps

- [ ] Container App Environment creado
- [ ] Obtener el domain del environment (formato: `proudsky-12345.eastus.azurecontainerapps.io`)
- [ ] Actualizar `container_app_environment_domain` en terraform
- [ ] Aplicar `terraform apply`
- [ ] Usar variables de `terraform output service_environment_variables`
- [ ] Configurar nginx.conf en frontend Container App
- [ ] Verificar comunicación interna entre servicios

## 🚀 Comandos de Despliegue

```bash
# 1. Aplicar infraestructura
cd terraform/environments/dev
terraform apply

# 2. Construir imágenes
cd ../../../
./scripts/azure-build-push.sh build-push-all

# 3. Crear Container Apps (tu parte)
# Usar las variables de: terraform output service_environment_variables
```

## 🎯 Resultado Esperado

Una vez deployado:

- ✅ **Frontend**: Accesible vía HTTPS externa
- ✅ **Auth-API**: Circuit Breaker protegiendo llamadas a Users-API
- ✅ **Users-API**: Respondiendo a auth-api internamente
- ✅ **Todos-API**: Conectado a Redis para cache
- ✅ **Log-Processor**: Procesando mensajes de Redis
- ✅ **Zipkin**: Recibiendo trazas de todos los servicios

## 💡 Notas Importantes

1. **Dominio dinámico**: El dominio del Container App Environment se genera automáticamente
2. **DNS interno**: Solo funciona dentro del mismo environment
3. **HTTPS automático**: Container Apps maneja certificados SSL automáticamente
4. **Health checks**: Configurar health checks en cada Container App
5. **Circuit Breaker**: Funcionará igual que en local, pero con URLs de Azure

¡Todo listo para que funcione como en local! 🎉