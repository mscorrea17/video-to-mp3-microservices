@echo off
setlocal enabledelayedexpansion

echo ====================================
echo    DESPLEGANDO EN KUBERNETES
echo ====================================
echo.

REM Verificar kubectl
kubectl version --client >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: kubectl no está instalado o no está en el PATH
    pause
    exit /b 1
)

REM Verificar conexión al cluster
kubectl cluster-info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: No se puede conectar al cluster de Kubernetes
    echo Verifica que Minikube esté corriendo: minikube start
    pause
    exit /b 1
)

echo ✓ Conexión a Kubernetes establecida
echo.

REM Verificar que los manifests existen
if not exist "k8s\rabbitmq-deploy.yaml" (
    echo ERROR: No se encontró k8s\rabbitmq-deploy.yaml
    pause
    exit /b 1
)

if not exist "k8s\auth-deploy.yaml" (
    echo ERROR: No se encontró k8s\auth-deploy.yaml
    pause
    exit /b 1
)

if not exist "k8s\gateway-deploy.yaml" (
    echo ERROR: No se encontró k8s\gateway-deploy.yaml
    pause
    exit /b 1
)

if not exist "k8s\converter-deploy.yaml" (
    echo ERROR: No se encontró k8s\converter-deploy.yaml
    pause
    exit /b 1
)

if not exist "k8s\notification-deploy.yaml" (
    echo ERROR: No se encontró k8s\notification-deploy.yaml
    pause
    exit /b 1
)

if not exist "k8s\ingress.yaml" (
    echo ERROR: No se encontró k8s\ingress.yaml
    pause
    exit /b 1
)

echo [1/6] Desplegando RabbitMQ...
kubectl apply -f k8s\rabbitmq-deploy.yaml
if %errorlevel% neq 0 (
    echo ERROR: Falló el despliegue de RabbitMQ
    pause
    exit /b 1
)
echo ✓ RabbitMQ desplegado

echo.
echo Esperando a que RabbitMQ esté listo...
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=300s
if %errorlevel% neq 0 (
    echo ERROR: Timeout esperando RabbitMQ
    echo Verificando estado de los pods...
    kubectl get pods -l app=rabbitmq
    pause
    exit /b 1
)
echo ✓ RabbitMQ está listo

echo.
echo [2/6] Desplegando Auth Service...
kubectl apply -f k8s\auth-deploy.yaml
if %errorlevel% neq 0 (
    echo ERROR: Falló el despliegue de Auth Service
    pause
    exit /b 1
)
echo ✓ Auth Service desplegado

echo.
echo [3/6] Desplegando Gateway Service...
kubectl apply -f k8s\gateway-deploy.yaml
if %errorlevel% neq 0 (
    echo ERROR: Falló el despliegue de Gateway Service
    pause
    exit /b 1
)
echo ✓ Gateway Service desplegado

echo.
echo [4/6] Desplegando Converter Service...
kubectl apply -f k8s\converter-deploy.yaml
if %errorlevel% neq 0 (
    echo ERROR: Falló el despliegue de Converter Service
    pause
    exit /b 1
)
echo ✓ Converter Service desplegado

echo.
echo [5/6] Desplegando Notification Service...
kubectl apply -f k8s\notification-deploy.yaml
if %errorlevel% neq 0 (
    echo ERROR: Falló el despliegue de Notification Service
    pause
    exit /b 1
)
echo ✓ Notification Service desplegado

echo.
echo [6/6] Desplegando Ingress...
kubectl apply -f k8s\ingress.yaml
if %errorlevel% neq 0 (
    echo ERROR: Falló el despliegue de Ingress
    pause
    exit /b 1
)
echo ✓ Ingress desplegado

echo.
echo ====================================
echo    VERIFICANDO DESPLIEGUE
echo ====================================
echo.

echo Estado de los deployments:
kubectl get deployments
echo.

echo Estado de los servicios:
kubectl get services
echo.

echo Estado de los pods:
kubectl get pods
echo.

echo Esperando a que todos los pods estén listos...
timeout /t 30 /nobreak >nul

echo.
echo Estado final de los pods:
kubectl get pods

echo.
echo ====================================
echo    DESPLIEGUE COMPLETADO
echo ====================================
echo.

REM Obtener la URL del servicio si es Minikube
minikube service gateway --url >nul 2>&1
if %errorlevel% equ 0 (
    echo Para acceder a la aplicación:
    for /f %%i in ('minikube service gateway --url') do echo URL: %%i
    echo.
    echo O usando el ingress:
    echo 1. Ejecuta: minikube addons enable ingress
    echo 2. Agrega a tu archivo hosts: 
    for /f %%i in ('minikube ip') do echo    %%i mp3converter.com
    echo 3. Accede a: http://mp3converter.com
)

echo.
echo Comandos útiles:
echo   Ver logs:           kubectl logs -f deployment/^<service-name^>
echo   Ver pods:           kubectl get pods
echo   Reiniciar servicio: kubectl rollout restart deployment/^<service-name^>
echo   Eliminar todo:      kubectl delete -f k8s\
echo.
pause