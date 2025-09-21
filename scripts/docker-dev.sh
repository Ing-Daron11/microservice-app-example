#!/bin/bash

# Script para manejar el entorno de desarrollo con Docker
# Autor: DevOps Team
# Fecha: $(date)

set -e

COMPOSE_FILE="docker-compose.dev.yml"
PROJECT_NAME="microservice-app"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo -e "${BLUE}=== Microservice App - Docker Development Helper ===${NC}"
    echo ""
    echo "Uso: $0 [COMANDO]"
    echo ""
    echo "Comandos disponibles:"
    echo "  build      - Construir todas las imágenes"
    echo "  up         - Levantar todos los servicios"
    echo "  down       - Detener todos los servicios"
    echo "  restart    - Reiniciar todos los servicios"
    echo "  logs       - Ver logs de todos los servicios"
    echo "  logs-todos - Ver logs solo del todos-api"
    echo "  status     - Ver estado de los servicios"
    echo "  clean      - Limpiar contenedores e imágenes no usadas"
    echo "  test       - Hacer test básico de conectividad"
    echo "  help       - Mostrar esta ayuda"
    echo ""
}

# Función para build
build_services() {
    echo -e "${YELLOW}🔨 Construyendo imágenes...${NC}"
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME build --no-cache
    echo -e "${GREEN}✅ Build completado${NC}"
}

# Función para levantar servicios
up_services() {
    echo -e "${YELLOW}🚀 Levantando servicios...${NC}"
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME up -d
    echo -e "${GREEN}✅ Servicios levantados${NC}"
    echo ""
    echo -e "${BLUE}🌐 URLs disponibles:${NC}"
    echo "  - Todos API: http://localhost:8082"
    echo "  - Zipkin UI: http://localhost:9411"
    echo "  - Redis: localhost:6379"
}

# Función para bajar servicios
down_services() {
    echo -e "${YELLOW}🔻 Deteniendo servicios...${NC}"
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME down
    echo -e "${GREEN}✅ Servicios detenidos${NC}"
}

# Función para restart
restart_services() {
    echo -e "${YELLOW}🔄 Reiniciando servicios...${NC}"
    down_services
    up_services
}

# Función para ver logs
show_logs() {
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME logs -f
}

# Función para ver logs solo del todos-api
show_todos_logs() {
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME logs -f todos-api
}

# Función para ver status
show_status() {
    echo -e "${BLUE}📊 Estado de los servicios:${NC}"
    docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME ps
}

# Función para limpiar
clean_docker() {
    echo -e "${YELLOW}🧹 Limpiando Docker...${NC}"
    docker system prune -f
    echo -e "${GREEN}✅ Limpieza completada${NC}"
}

# Función para test básico
test_connectivity() {
    echo -e "${YELLOW}🧪 Testeando conectividad...${NC}"
    
    # Test Redis
    echo -n "Redis: "
    if docker-compose -f $COMPOSE_FILE -p $PROJECT_NAME exec redis redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
    fi
    
    # Test Todos API (nota: puede fallar por JWT)
    echo -n "Todos API: "
    if curl -s http://localhost:8082 > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${YELLOW}⚠️ No responde (normal sin JWT)${NC}"
    fi
    
    # Test Zipkin
    echo -n "Zipkin: "
    if curl -s http://localhost:9411/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
    fi
}

# Main script logic
case "${1:-help}" in
    build)
        build_services
        ;;
    up)
        up_services
        ;;
    down)
        down_services
        ;;
    restart)
        restart_services
        ;;
    logs)
        show_logs
        ;;
    logs-todos)
        show_todos_logs
        ;;
    status)
        show_status
        ;;
    clean)
        clean_docker
        ;;
    test)
        test_connectivity
        ;;
    help|*)
        show_help
        ;;
esac