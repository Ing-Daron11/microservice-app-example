#!/bin/bash

# Script para build y push de imágenes a Azure Container Registry
# Autor: DevOps Team para Azure for Students

set -e

# Configuración desde Terraform outputs
ACR_NAME="microappdevacryckctn"
ACR_LOGIN_SERVER="microappdevacryckctn.azurecr.io"
RESOURCE_GROUP="rg-microapp-dev-student"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Azure Container Registry - Build & Push${NC}"
echo -e "${BLUE}===========================================${NC}"

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [COMANDO] [SERVICIO]"
    echo ""
    echo "Comandos:"
    echo "  login              - Login a ACR"
    echo "  build-all          - Construir todas las imágenes"
    echo "  push-all           - Subir todas las imágenes"
    echo "  build-push-all     - Construir y subir todas las imágenes"
    echo "  build [servicio]   - Construir imagen específica"
    echo "  push [servicio]    - Subir imagen específica"
    echo ""
    echo "Servicios disponibles:"
    echo "  - frontend"
    echo "  - auth-api"
    echo "  - users-api"
    echo "  - todos-api"
    echo "  - log-message-processor"
}

# Función para login en ACR
acr_login() {
    echo -e "${YELLOW}🔐 Logging in to Azure Container Registry...${NC}"
    
    # Login a Azure CLI
    az login --output none
    
    # Login a ACR
    az acr login --name $ACR_NAME
    
    echo -e "${GREEN}✅ Successfully logged in to $ACR_LOGIN_SERVER${NC}"
}

# Función para construir imagen
build_image() {
    local service=$1
    local image_tag="$ACR_LOGIN_SERVER/$service:latest"
    
    echo -e "${YELLOW}🔨 Building $service...${NC}"
    
    if [ ! -d "./$service" ]; then
        echo -e "${RED}❌ Directory ./$service not found${NC}"
        return 1
    fi
    
    docker build -t $image_tag ./$service/
    echo -e "${GREEN}✅ Built $service successfully${NC}"
}

# Función para subir imagen
push_image() {
    local service=$1
    local image_tag="$ACR_LOGIN_SERVER/$service:latest"
    
    echo -e "${YELLOW}📤 Pushing $service to ACR...${NC}"
    docker push $image_tag
    echo -e "${GREEN}✅ Pushed $service successfully${NC}"
}

# Array de microservicios
SERVICES=("frontend" "auth-api" "users-api" "todos-api" "log-message-processor")

# Función para construir todas las imágenes
build_all() {
    echo -e "${BLUE}🏗️ Building all microservices...${NC}"
    
    for service in "${SERVICES[@]}"; do
        build_image $service
    done
    
    echo -e "${GREEN}🎉 All images built successfully!${NC}"
}

# Función para subir todas las imágenes
push_all() {
    echo -e "${BLUE}📤 Pushing all images to ACR...${NC}"
    
    for service in "${SERVICES[@]}"; do
        push_image $service
    done
    
    echo -e "${GREEN}🎉 All images pushed successfully!${NC}"
}

# Función para construir y subir todo
build_push_all() {
    acr_login
    build_all
    push_all
    
    echo -e "${GREEN}🚀 All microservices are now in Azure Container Registry!${NC}"
    echo -e "${BLUE}📋 Next step: Create Container Apps${NC}"
}

# Función para mostrar imágenes en ACR
show_images() {
    echo -e "${BLUE}📋 Images in ACR:${NC}"
    az acr repository list --name $ACR_NAME --output table
}

# Main script logic
case "${1:-help}" in
    login)
        acr_login
        ;;
    build-all)
        build_all
        ;;
    push-all)
        push_all
        ;;
    build-push-all)
        build_push_all
        ;;
    build)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please specify a service to build${NC}"
            show_help
            exit 1
        fi
        build_image $2
        ;;
    push)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Please specify a service to push${NC}"
            show_help
            exit 1
        fi
        push_image $2
        ;;
    images)
        show_images
        ;;
    help|*)
        show_help
        ;;
esac