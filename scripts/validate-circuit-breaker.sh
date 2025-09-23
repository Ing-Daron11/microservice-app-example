#!/bin/bash

# Script de validación para Circuit Breaker en Azure Container Apps
# Verifica que las variables de entorno estén correctamente configuradas

set -e

echo "🔍 Validando configuración de Circuit Breaker para Azure Container Apps"
echo "=================================================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Función para validar Terraform outputs
validate_terraform_config() {
    echo -e "${BLUE}📋 Validando configuración de Terraform...${NC}"
    
    cd terraform/environments/dev
    
    # Verificar que terraform esté inicializado
    if [ ! -d ".terraform" ]; then
        echo -e "${YELLOW}⚠️  Terraform no inicializado. Ejecutando terraform init...${NC}"
        terraform init
    fi
    
    # Validar configuración
    echo -e "${YELLOW}🔍 Validando sintaxis de Terraform...${NC}"
    terraform validate
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Configuración de Terraform válida${NC}"
    else
        echo -e "${RED}❌ Error en configuración de Terraform${NC}"
        exit 1
    fi
    
    # Mostrar plan sin aplicar
    echo -e "${YELLOW}📋 Generando plan de Terraform...${NC}"
    terraform plan -no-color > terraform-plan.out
    
    echo -e "${GREEN}✅ Plan generado exitosamente${NC}"
    cd - > /dev/null
}

# Función para validar variables de entorno específicas del Circuit Breaker
validate_circuit_breaker_config() {
    echo -e "${BLUE}🔄 Validando configuración específica del Circuit Breaker...${NC}"
    
    # Verificar que el módulo container-apps-config existe
    if [ ! -f "terraform/modules/container-apps-config/main.tf" ]; then
        echo -e "${RED}❌ Módulo container-apps-config no encontrado${NC}"
        exit 1
    fi
    
    # Verificar variables críticas para Circuit Breaker
    echo -e "${YELLOW}🔍 Verificando variables críticas...${NC}"
    
    # Auth-API debe tener USERS_API_ADDRESS
    if grep -q "USERS_API_ADDRESS" terraform/modules/container-apps-config/main.tf; then
        echo -e "${GREEN}✅ USERS_API_ADDRESS configurada para auth-api${NC}"
    else
        echo -e "${RED}❌ USERS_API_ADDRESS faltante en auth-api${NC}"
        exit 1
    fi
    
    # Verificar formato de URLs internas
    if grep -q "internal\." terraform/modules/container-apps-config/main.tf; then
        echo -e "${GREEN}✅ URLs internas usando formato correcto (.internal.)${NC}"
    else
        echo -e "${RED}❌ URLs internas mal configuradas${NC}"
        exit 1
    fi
    
    # Verificar JWT_SECRET
    if grep -q "JWT_SECRET" terraform/modules/container-apps-config/main.tf; then
        echo -e "${GREEN}✅ JWT_SECRET configurado${NC}"
    else
        echo -e "${RED}❌ JWT_SECRET faltante${NC}"
        exit 1
    fi
}

# Función para validar Dockerfiles
validate_dockerfiles() {
    echo -e "${BLUE}🐳 Validando Dockerfiles...${NC}"
    
    services=("frontend" "auth-api" "users-api" "todos-api" "log-message-processor")
    
    for service in "${services[@]}"; do
        if [ -f "$service/Dockerfile" ]; then
            echo -e "${GREEN}✅ Dockerfile encontrado para $service${NC}"
        else
            echo -e "${RED}❌ Dockerfile faltante para $service${NC}"
            exit 1
        fi
    done
}

# Función para mostrar configuración para Container Apps
show_container_apps_config() {
    echo -e "${BLUE}📋 Configuración para Container Apps:${NC}"
    echo -e "${YELLOW}===========================================${NC}"
    
    echo -e "${BLUE}🔐 Auth-API (Circuit Breaker):${NC}"
    echo "  - USERS_API_ADDRESS: http://microapp-dev-users-api-ca.internal.<domain>:8083"
    echo "  - AUTH_API_PORT: 8081"
    echo "  - JWT_SECRET: myfancysecret"
    echo "  - ZIPKIN_URL: http://microapp-dev-zipkin-ca.internal.<domain>:9411/api/v2/spans"
    echo ""
    
    echo -e "${BLUE}👥 Users-API:${NC}"
    echo "  - SERVER_PORT: 8083"
    echo "  - SPRING_ZIPKIN_BASE_URL: http://microapp-dev-zipkin-ca.internal.<domain>:9411/"
    echo "  - SPRING_DATASOURCE_URL: jdbc:h2:mem:testdb"
    echo ""
    
    echo -e "${BLUE}✅ Todos-API:${NC}"
    echo "  - TODO_API_PORT: 8082"
    echo "  - REDIS_HOST: microapp-dev-redis-ca.internal.<domain>"
    echo "  - REDIS_PORT: 6379"
    echo "  - ZIPKIN_URL: http://microapp-dev-zipkin-ca.internal.<domain>:9411/api/v2/spans"
    echo ""
    
    echo -e "${BLUE}🎨 Frontend (Nginx):${NC}"
    echo "  - Proxy /login -> auth-api:8081"
    echo "  - Proxy /api/* -> todos-api:8082"
    echo "  - Configuración en nginx.conf"
    echo ""
}

# Función para generar comando de despliegue
generate_deployment_commands() {
    echo -e "${BLUE}🚀 Comandos para despliegue:${NC}"
    echo -e "${YELLOW}============================${NC}"
    
    echo "# 1. Aplicar infraestructura Terraform:"
    echo "cd terraform/environments/dev"
    echo "terraform apply"
    echo ""
    
    echo "# 2. Construir y subir imágenes:"
    echo "cd ../../../"
    echo "./scripts/azure-build-push.sh build-push-all"
    echo ""
    
    echo "# 3. Tu compañero debe usar estas variables en Container Apps:"
    echo "terraform output service_environment_variables"
    echo ""
    
    echo -e "${GREEN}📝 Nota: El Container App Environment domain se obtendrá después de crear el environment${NC}"
}

# Ejecutar validaciones
validate_terraform_config
validate_circuit_breaker_config
validate_dockerfiles
show_container_apps_config
generate_deployment_commands

echo ""
echo -e "${GREEN}🎉 ¡Validación completada exitosamente!${NC}"
echo -e "${BLUE}📋 El Circuit Breaker está listo para funcionar en Azure Container Apps${NC}"
echo -e "${YELLOW}💡 Asegúrate de que tu compañero use las variables de entorno generadas${NC}"