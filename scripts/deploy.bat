@echo off
echo Desplegando servicios en Kubernetes...
echo.

echo Aplicando RabbitMQ...
kubectl apply -f k8s\rabbitmq-deploy.yaml
if %errorlevel% neq 0 (
    echo Error desplegando RabbitMQ
    pause
    exit /b 1
)

echo.
echo Esperando a que RabbitMQ este listo...
kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=300s
if %errorlevel% neq 0 (
    echo Timeout esperando RabbitMQ
    pause
    exit /b 1
)

echo.
echo Aplicando Auth Service...
kubectl apply -f k8s\auth-deploy.yaml
if %errorlevel% neq 0 (
    echo Error desplegando Auth Service
    pause
    exit /b 1
)

echo.
echo Aplicando Gateway Service...
kubectl apply -f k8s\gateway-deploy.yaml
if %errorlevel% neq 0 (
    echo Error desplegando Gateway Service
    pause
    exit /b 1
)

echo.
echo Aplicando Converter Service...
kubectl apply -f k8s\converter-deploy.yaml
if %errorlevel% neq 0 (
    echo Error desplegando Converter Service
    pause
    exit /b 1
)

echo.
echo Aplicando Notification Service...
kubectl apply -f k8s\notification-deploy.yaml
if %errorlevel% neq 0 (
    echo Error desplegando Notification Service
    pause
    exit /b 1
)

echo.
echo Aplicando Ingress...
kubectl apply -f k8s\ingress.yaml
if %errorlevel% neq 0 (
    echo Error desplegando Ingress
    pause
    exit /b 1
)

echo.
echo Verificando el estado de los deployments...
kubectl get deployments
kubectl get services
kubectl get pods

echo.
echo Despliegue completado!
echo Puedes verificar el estado con: kubectl get pods
pause
