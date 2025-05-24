@echo off
echo ====================================
echo    PRUEBAS BASICAS MP3 CONVERTER
echo ====================================
echo.

echo [1/5] Verificando Minikube...
minikube status >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Minikube no esta corriendo
    echo Ejecuta: minikube start
    pause
    exit /b 1
)
echo ✓ Minikube esta corriendo

echo.
echo [2/5] Verificando pods de Kubernetes...
kubectl get pods --no-headers >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: No se puede conectar a Kubernetes
    pause
    exit /b 1
)
echo ✓ Kubernetes accesible

echo.
echo [3/5] Verificando servicios...
kubectl get services auth gateway rabbitmq >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Algunos servicios no estan disponibles
    kubectl get services
    pause
    exit /b 1
)
echo ✓ Servicios disponibles

echo.
echo [4/5] Obteniendo URL del Gateway...
for /f %%i in ('minikube service gateway --url 2^>nul') do set GATEWAY_URL=%%i

if "%GATEWAY_URL%"=="" (
    echo ERROR: No se pudo obtener la URL del Gateway
    pause
    exit /b 1
)
echo ✓ Gateway URL: %GATEWAY_URL%

echo.
echo [5/5] Probando conexion al Gateway...
curl -s %GATEWAY_URL%/health >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Gateway no responde
    echo Verificando estado de pods:
    kubectl get pods
    pause
    exit /b 1
)
echo ✓ Gateway responde

echo.
echo ====================================
echo    TODAS LAS PRUEBAS BASICAS PASARON
echo ====================================
echo.
echo Gateway URL: %GATEWAY_URL%
echo.
echo Comandos para probar manualmente:
echo.
echo 1. Login:
echo    curl -X POST %GATEWAY_URL%/login -u admin@email.com:admin123
echo.
echo 2. Health check:
echo    curl %GATEWAY_URL%/health
echo.
echo 3. Ver estado de pods:
echo    kubectl get pods
echo.
pause