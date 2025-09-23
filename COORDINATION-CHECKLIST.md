# ✅ CHECKLIST DE COORDINACIÓN - No Pisarse la Manguera 

## 🚦 DIVISIÓN DE RESPONSABILIDADES

### 👤 **TU TRABAJO (YA TERMINADO)**
- ✅ Módulo `resource-group`
- ✅ Módulo `acr` 
- ✅ Módulo `networking`
- ✅ Módulo `container-apps-config` (variables de entorno)
- ✅ Scripts de build (`azure-build-push.sh`)
- ✅ Validación (`validate-circuit-breaker.sh`)
- ✅ Documentación y handoff documents

### 👥 **TRABAJO DE TU COMPAÑERO**
- ⏳ Módulo `container-apps` (Container App Environment + Container Apps)
- ⏳ Integración en `terraform/environments/dev/main.tf`
- ⏳ Outputs para URLs finales
- ⏳ Testing de deployment

## 🔒 ARCHIVOS QUE **NO DEBE TOCAR** TU COMPAÑERO

```
❌ terraform/modules/resource-group/
❌ terraform/modules/acr/
❌ terraform/modules/networking/
❌ terraform/modules/container-apps-config/
❌ scripts/azure-build-push.*
❌ scripts/validate-circuit-breaker.sh
```

## ✅ ARCHIVOS QUE **SÍ PUEDE CREAR/MODIFICAR**

```
✅ terraform/modules/container-apps/ (NUEVO - su módulo)
✅ terraform/environments/dev/main.tf (agregar su módulo)
✅ terraform/environments/dev/outputs.tf (agregar sus outputs)
✅ Scripts adicionales para Container Apps (si los necesita)
```

## 🔄 PUNTOS DE INTEGRACIÓN

### 1. **En main.tf debe agregar:**
```hcl
# DESPUÉS de nuestros módulos existentes
module "container_apps" {
  source = "../../modules/container-apps"
  
  # Usar datos de nuestros módulos
  prefix              = local.prefix
  location           = module.resource_group.location
  resource_group_name = module.resource_group.name
  acr_login_server   = module.acr.login_server
  
  # Usar nuestra configuración de networking
  infrastructure_subnet_id = module.networking.subnet_ids["shared-services"]
  
  # CRÍTICO: Usar nuestras variables de entorno
  microservices_config = local.microservices
  service_environment_variables = module.container_apps_config.service_environment_variables
  
  tags = local.common_tags
}
```

### 2. **Actualizar dominio después de crear environment:**
```hcl
# En container_apps_config, cambiar:
module "container_apps_config" {
  # De: container_app_environment_domain = "proudsky-12345.eastus.azurecontainerapps.io"
  # A:  container_app_environment_domain = module.container_apps.container_app_environment_domain
}
```

## 🚨 CONFLICTOS POTENCIALES Y CÓMO EVITARLOS

### ❌ **NO hacer:**
1. Modificar archivos existentes de configuración
2. Cambiar nombres de variables en `container-apps-config`
3. Tocar los scripts de build
4. Modificar configuración de ACR o networking

### ✅ **SÍ hacer:**
1. Crear módulo nuevo desde cero
2. Usar las variables que ya están definidas
3. Referenciar módulos existentes
4. Agregar outputs nuevos en outputs.tf

## 🔍 VALIDACIÓN FINAL

### Cuando ambos terminen:
```bash
# 1. Validar Terraform
cd terraform/environments/dev
terraform validate

# 2. Ver plan completo
terraform plan

# 3. Validar Circuit Breaker
cd ../../../
./scripts/validate-circuit-breaker.sh

# 4. Aplicar (cuando ambos estén seguros)
cd terraform/environments/dev
terraform apply
```

## 📋 ENTREGABLES DE COORDINACIÓN

### Para entregar a tu compañero:
1. ✅ `HANDOFF-CONTAINER-APPS.md` - Documentación técnica completa
2. ✅ `AI-PROMPT-CONTAINER-APPS.md` - Prompt directo para su agente IA
3. ✅ Este checklist de coordinación
4. ✅ Variables de entorno configuradas y listas para usar

### Lo que debe entregar tu compañero:
1. ⏳ Módulo `terraform/modules/container-apps/` completo
2. ⏳ Integración en `main.tf` sin tocar módulos existentes
3. ⏳ Outputs con URLs finales de los Container Apps
4. ⏳ Confirmación de que usa las variables de entorno correctas

## 🎯 RESULTADO ESPERADO

Al final del trabajo coordinado:
- ✅ Infrastructure as Code completa
- ✅ Container Apps deployados con configuración correcta
- ✅ Circuit Breaker funcionando (auth-api → users-api)
- ✅ Comunicación Redis (todos-api ↔ redis)
- ✅ Trazas distribuidas (todos → Zipkin)
- ✅ Frontend accesible externamente

## 🔧 COMANDOS DE EMERGENCIA

Si hay conflictos:
```bash
# Ver estado actual
git status

# Ver diferencias
git diff

# Rollback si es necesario
git checkout -- <archivo>

# Validar configuración
terraform validate
```

---
**🤝 Con esta coordinación, ambos pueden trabajar sin pisarse!**