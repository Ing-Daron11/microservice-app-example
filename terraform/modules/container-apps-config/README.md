# Módulo de Configuración para Container Apps

Este módulo maneja las variables de entorno y configuración de red para todos los microservicios en Azure Container Apps.

## Qué hace

Este módulo crea la configuración necesaria para que tus microservicios se comuniquen entre ellos en Azure Container Apps, igual que lo hacen localmente con docker-compose.

## Cómo usarlo

Después de desplegar con Terraform, obtén las variables de entorno:

```bash
cd terraform/environments/dev
terraform output service_environment_variables
```

Luego usa estas variables al crear tus Container Apps. La más importante es para el Circuit Breaker en auth-api:

```bash
USERS_API_ADDRESS=http://microapp-dev-users-api-ca.internal.<domain>:8083
```

## Diferencias principales con el setup local

| Local | Azure Container Apps |
|-------|---------------------|
| `http://users-api:8083` | `http://microapp-dev-users-api-ca.internal.<domain>:8083` |
| `redis:6379` | `microapp-dev-redis-ca.internal.<domain>:6379` |
| `http://zipkin:9411` | `http://microapp-dev-zipkin-ca.internal.<domain>:9411` |

## Por qué es importante

La implementación del Circuit Breaker necesita la URL interna correcta para proteger las llamadas entre auth-api y users-api. Este módulo asegura que todos los servicios se puedan encontrar usando el DNS interno de Azure.

## Pasos rápidos de configuración

1. Despliega el Container App Environment con Terraform
2. Ejecuta `terraform output service_environment_variables`
3. Usa esas variables al crear los Container Apps
4. Verifica que los servicios se comuniquen internamente

¡Eso es todo! Tus microservicios funcionarán igual que localmente.