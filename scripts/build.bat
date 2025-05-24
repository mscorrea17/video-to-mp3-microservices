@echo off
setlocal enabledelayedexpansion

echo ================================
echo    CONSTRUYENDO IMAGENES DOCKER
echo ================================
echo.

REM Verificar que Docker está corriendo
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no está corriendo o no está instalado
    echo Por favor, inicia Docker Desktop
    pause
    exit /b 1
)

REM Verificar que los Dockerfiles existen
if not exist "src\auth\Dockerfile" (
    echo ERROR: No se encontró src\auth\Dockerfile
    pause
    exit /b 1
)

if not exist "src\gateway\Dockerfile" (
    echo ERROR: No se encontró src\gateway\Dockerfile
    pause
    exit /b 1
)

if not exist "src\converter\Dockerfile" (
    echo ERROR: No se encontró src\converter\Dockerfile
    pause
    exit /b 1
)

if not exist "src\notification\Dockerfile" (
    echo ERROR: No se encontró src\notification\Dockerfile
    pause
    exit /b 1
)

echo [1/4] Construyendo Auth Service...
docker build -t auth:latest ./src/auth
if %errorlevel% neq 0 (
    echo ERROR: Falló la construcción de Auth Service
    pause
    exit /b 1
)
echo ✓ Auth Service construido exitosamente

echo.
echo [2/4] Construyendo Gateway Service...
docker build -t gateway:latest ./src/gateway
if %errorlevel% neq 0 (
    echo ERROR: Falló la construcción de Gateway Service
    pause
    exit /b 1
)
echo ✓ Gateway Service construido exitosamente

echo.
echo [3/4] Construyendo Converter Service...
docker build -t converter:latest ./src/converter
if %errorlevel% neq 0 (
    echo ERROR: Falló la construcción de Converter Service
    pause
    exit /b 1
)
echo ✓ Converter Service construido exitosamente

echo.
echo [4/4] Construyendo Notification Service...
docker build -t notification:latest ./src/notification
if %errorlevel% neq 0 (
    echo ERROR: Falló la construcción de Notification Service
    pause
    exit /b 1
)
echo ✓ Notification Service construido exitosamente

echo.
echo ================================
echo    VERIFICANDO MINIKUBE
echo ================================

REM Verificar si Minikube está disponible
minikube status >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Minikube está corriendo
    echo.
    echo Cargando imágenes en Minikube...
    
    minikube image load auth:latest
    if %errorlevel% neq 0 (
        echo WARNING: No se pudo cargar auth:latest en Minikube
    ) else (
        echo ✓ auth:latest cargada
    )
    
    minikube image load gateway:latest
    if %errorlevel% neq 0 (
        echo WARNING: No se pudo cargar gateway:latest en Minikube
    ) else (
        echo ✓ gateway:latest cargada
    )
    
    minikube image load converter:latest
    if %errorlevel% neq 0 (
        echo WARNING: No se pudo cargar converter:latest en Minikube
    ) else (
        echo ✓ converter:latest cargada
    )
    
    minikube image load notification:latest
    if %errorlevel% neq 0 (
        echo WARNING: No se pudo cargar notification:latest en Minikube
    ) else (
        echo ✓ notification:latest cargada
    )
    
    echo.
    echo ✓ Todas las imágenes cargadas en Minikube
) else (
    echo WARNING: Minikube no está corriendo
    echo Las imágenes están disponibles localmente para Docker Compose
    echo Para usar Kubernetes, inicia Minikube primero con: minikube start
)

echo.
echo ================================
echo    BUILD COMPLETADO
echo ================================
echo.
echo Imágenes creadas:
docker images auth:latest gateway:latest converter:latest notification:latest --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

echo.
echo Siguiente paso: ejecutar scripts\deploy.bat para desplegar en Kubernetes
echo O usar docker-compose up -d para desarrollo local
pause