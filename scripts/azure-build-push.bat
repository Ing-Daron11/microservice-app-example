@echo off
REM Script para build y push de imágenes a Azure Container Registry
REM Autor: DevOps Team para Azure for Students

set ACR_NAME=microappdevacryckctn
set ACR_LOGIN_SERVER=microappdevacryckctn.azurecr.io
set RESOURCE_GROUP=rg-microapp-dev-student

echo 🐳 Azure Container Registry - Build ^& Push
echo ==========================================

if "%1"=="" goto help
if "%1"=="help" goto help
if "%1"=="login" goto login
if "%1"=="build-all" goto build_all
if "%1"=="push-all" goto push_all
if "%1"=="build-push-all" goto build_push_all
if "%1"=="images" goto images
goto help

:help
echo Uso: %0 [COMANDO]
echo.
echo Comandos:
echo   login              - Login a ACR
echo   build-all          - Construir todas las imagenes
echo   push-all           - Subir todas las imagenes
echo   build-push-all     - Construir y subir todas las imagenes
echo   images             - Ver imagenes en ACR
echo.
goto end

:login
echo 🔐 Logging in to Azure Container Registry...
az login
az acr login --name %ACR_NAME%
echo ✅ Successfully logged in to %ACR_LOGIN_SERVER%
goto end

:build_all
echo 🔨 Building frontend...
docker build -t %ACR_LOGIN_SERVER%/frontend:latest ./frontend/

echo 🔨 Building auth-api...
docker build -t %ACR_LOGIN_SERVER%/auth-api:latest ./auth-api/

echo 🔨 Building users-api...
docker build -t %ACR_LOGIN_SERVER%/users-api:latest ./users-api/

echo 🔨 Building todos-api...
docker build -t %ACR_LOGIN_SERVER%/todos-api:latest ./todos-api/

echo 🔨 Building log-message-processor...
docker build -t %ACR_LOGIN_SERVER%/log-message-processor:latest ./log-message-processor/

echo ✅ All images built successfully!
goto end

:push_all
echo 📤 Pushing frontend...
docker push %ACR_LOGIN_SERVER%/frontend:latest

echo 📤 Pushing auth-api...
docker push %ACR_LOGIN_SERVER%/auth-api:latest

echo 📤 Pushing users-api...
docker push %ACR_LOGIN_SERVER%/users-api:latest

echo 📤 Pushing todos-api...
docker push %ACR_LOGIN_SERVER%/todos-api:latest

echo 📤 Pushing log-message-processor...
docker push %ACR_LOGIN_SERVER%/log-message-processor:latest

echo ✅ All images pushed successfully!
goto end

:build_push_all
call :login
call :build_all
call :push_all
echo 🚀 All microservices are now in Azure Container Registry!
echo 📋 Next step: Create Container Apps
goto end

:images
echo 📋 Images in ACR:
az acr repository list --name %ACR_NAME% --output table
goto end

:end