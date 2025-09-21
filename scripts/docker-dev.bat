@echo off
REM Script para manejar el entorno de desarrollo con Docker en Windows
REM Autor: DevOps Team

set COMPOSE_FILE=docker-compose.dev.yml
set PROJECT_NAME=microservice-app

if "%1"=="" goto help
if "%1"=="help" goto help
if "%1"=="build" goto build
if "%1"=="up" goto up
if "%1"=="down" goto down
if "%1"=="restart" goto restart
if "%1"=="logs" goto logs
if "%1"=="logs-todos" goto logs-todos
if "%1"=="status" goto status
if "%1"=="clean" goto clean
if "%1"=="test" goto test
goto help

:help
echo === Microservice App - Docker Development Helper ===
echo.
echo Uso: %0 [COMANDO]
echo.
echo Comandos disponibles:
echo   build      - Construir todas las imagenes
echo   up         - Levantar todos los servicios
echo   down       - Detener todos los servicios
echo   restart    - Reiniciar todos los servicios
echo   logs       - Ver logs de todos los servicios
echo   logs-todos - Ver logs solo del todos-api
echo   status     - Ver estado de los servicios
echo   clean      - Limpiar contenedores e imagenes no usadas
echo   test       - Hacer test basico de conectividad
echo   help       - Mostrar esta ayuda
echo.
goto end

:build
echo 🔨 Construyendo imagenes...
docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% build --no-cache
echo ✅ Build completado
goto end

:up
echo 🚀 Levantando servicios...
docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% up -d
echo ✅ Servicios levantados
echo.
echo 🌐 URLs disponibles:
echo   - Todos API: http://localhost:8082
echo   - Zipkin UI: http://localhost:9411
echo   - Redis: localhost:6379
goto end

:down
echo 🔻 Deteniendo servicios...
docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% down
echo ✅ Servicios detenidos
goto end

:restart
echo 🔄 Reiniciando servicios...
call :down
call :up
goto end

:logs
docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% logs -f
goto end

:logs-todos
docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% logs -f todos-api
goto end

:status
echo 📊 Estado de los servicios:
docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% ps
goto end

:clean
echo 🧹 Limpiando Docker...
docker system prune -f
echo ✅ Limpieza completada
goto end

:test
echo 🧪 Testeando conectividad...
echo Redis: Ejecute 'docker-compose -f %COMPOSE_FILE% -p %PROJECT_NAME% exec redis redis-cli ping'
echo Todos API: Abra http://localhost:8082 en su navegador
echo Zipkin: Abra http://localhost:9411 en su navegador
goto end

:end