@echo off
setlocal enabledelayedexpansion

echo ====================================
echo    CONFIGURACIÓN INICIAL
echo ====================================
echo.

echo Verificando prerequisitos...

REM Verificar Docker
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no está instalado o no está corriendo
    echo Instala Docker Desktop desde: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)
echo ✓ Docker está disponible

REM Verificar kubectl
kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: kubectl no está instalado
    echo Instala kubectl desde: https://kubernetes.io/docs/tasks/tools/
    pause
    exit /b 1
)
echo ✓ kubectl está disponible

REM Verificar Minikube
minikube version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Minikube no está instalado
    echo Instala Minikube desde: https://minikube.sigs.k8s.io/docs/start/
    pause
    exit /b 1
)
echo ✓ Minikube está disponible

echo.
echo ====================================
echo    INICIANDO MINIKUBE
echo ====================================

REM Verificar si Minikube ya está corriendo
minikube status >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Minikube ya está corriendo
) else (
    echo Iniciando Minikube...
    minikube start --driver=docker --memory=4096 --cpus=2
    if %errorlevel% neq 0 (
        echo ERROR: No se pudo iniciar Minikube
        pause
        exit /b 1
    )
    echo ✓ Minikube iniciado exitosamente
)

echo.
echo ====================================
echo    HABILITANDO ADDONS
echo ====================================

echo Habilitando ingress addon...
minikube addons enable ingress
if %errorlevel% neq 0 (
    echo WARNING: No se pudo habilitar ingress addon
)

echo Habilitando dashboard addon...
minikube addons enable dashboard
if %errorlevel% neq 0 (
    echo WARNING: No se pudo habilitar dashboard addon
)

echo.
echo ====================================
echo    CONFIGURANDO BASES DE DATOS
echo ====================================

echo Iniciando servicios de base de datos con Docker Compose...
docker-compose up -d mysql mongodb rabbitmq
if %errorlevel% neq 0 (
    echo ERROR: No se pudieron iniciar las bases de datos
    pause
    exit /b 1
)

echo Esperando a que las bases de datos estén listas...
timeout /t 30 /nobreak >nul

echo.
echo ====================================
echo    INICIALIZANDO RABBITMQ
echo ====================================

echo Configurando colas de RabbitMQ...
python scripts\init-rabbitmq.py
if %errorlevel% neq 0 (
    echo WARNING: No se pudieron crear las colas de RabbitMQ automáticamente
    echo Puedes crearlas manualmente desde: http://localhost:15672
    echo Usuario: auth_user, Contraseña: Auth123
)

echo.
echo ====================================
echo    CONFIGURACIÓN COMPLETADA
echo ====================================
echo.

echo Estado de los contenedores:
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo.
echo Estado de Minikube:
minikube status

echo.
echo ====================================
echo    SIGUIENTE PASOS
echo ====================================
echo.
echo 1. Construir las imágenes:
echo    scripts\build.bat
echo.
echo 2. Desplegar en Kubernetes:
echo    scripts\deploy.bat
echo.
echo 3. O usar Docker Compose para desarrollo:
echo    docker-compose up -d
echo.
echo URLs útiles:
echo   RabbitMQ Management: http://localhost:15672
echo   Minikube Dashboard:  minikube dashboard
echo.
pause