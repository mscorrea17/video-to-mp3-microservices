@echo off
echo Construyendo imagenes Docker...
echo.

echo Construyendo Auth Service...
docker build -t auth:latest ./src/auth
if %errorlevel% neq 0 (
    echo Error construyendo Auth Service
    pause
    exit /b 1
)

echo.
echo Construyendo Gateway Service...
docker build -t gateway:latest ./src/gateway
if %errorlevel% neq 0 (
    echo Error construyendo Gateway Service
    pause
    exit /b 1
)

echo.
echo Construyendo Converter Service...
docker build -t converter:latest ./src/converter
if %errorlevel% neq 0 (
    echo Error construyendo Converter Service
    pause
    exit /b 1
)

echo.
echo Construyendo Notification Service...
docker build -t notification:latest ./src/notification
if %errorlevel% neq 0 (
    echo Error construyendo Notification Service
    pause
    exit /b 1
)

echo.
echo Todas las imagenes han sido construidas exitosamente!

echo.
echo Verificando si Minikube esta disponible...
minikube status >nul 2>&1
if %errorlevel% equ 0 (
    echo Cargando imagenes en Minikube...
    minikube image load auth:latest
    minikube image load gateway:latest
    minikube image load converter:latest
    minikube image load notification:latest
    echo Imagenes cargadas en Minikube!
) else (
    echo Minikube no esta corriendo. Las imagenes estan disponibles localmente.
)

echo.
echo Build completado!
pause
