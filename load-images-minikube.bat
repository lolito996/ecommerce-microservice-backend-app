@echo off
echo ============================================
echo CARGANDO IMAGENES EN MINIKUBE
echo ============================================
echo.

echo Verificando que Minikube esté funcionando...
minikube status
if %errorlevel% neq 0 (
    echo Error: Minikube no está funcionando correctamente
    exit /b 1
)

echo.
echo ============================================
echo CARGANDO IMAGENES DE MICROSERVICIOS
echo ============================================
echo.

echo 1. Cargando API Gateway...
call :load_or_pull selimhorri/api-gateway-ecommerce-boot 0.1.0 "API Gateway"

echo.
echo 2. Cargando Service Discovery...
call :load_or_pull selimhorri/service-discovery-ecommerce-boot 0.1.0 "Service Discovery"

echo.
echo 3. Cargando Cloud Config...
call :load_or_pull selimhorri/cloud-config-ecommerce-boot 0.1.0 "Cloud Config"

echo.
echo 4. Cargando User Service...
call :load_or_pull selimhorri/user-service-ecommerce-boot 0.1.0 "User Service"

echo.
echo 5. Cargando Proxy Client...
call :load_or_pull selimhorri/proxy-client-ecommerce-boot 0.1.0 "Proxy Client"

echo.
echo 6. Cargando Zipkin...
call :load_or_pull openzipkin/zipkin latest "Zipkin"

echo.
echo ============================================
echo VERIFICANDO IMAGENES CARGADAS
echo ============================================
echo.

echo Listando todas las imágenes en Minikube:
minikube image ls | findstr -E "(selimhorri|zipkin)"

echo.
echo ============================================
echo ¡TODAS LAS IMAGENES CARGADAS EXITOSAMENTE!
echo ============================================
echo.
echo Imágenes disponibles para despliegue:
echo - API Gateway (selimhorri/api-gateway-ecommerce-boot:0.1.0)
echo - Service Discovery (selimhorri/service-discovery-ecommerce-boot:0.1.0)
echo - Cloud Config (selimhorri/cloud-config-ecommerce-boot:0.1.0)
echo - User Service (selimhorri/user-service-ecommerce-boot:0.1.0)
echo - Proxy Client (selimhorri/proxy-client-ecommerce-boot:0.1.0)
echo - Zipkin (openzipkin/zipkin:latest)
echo.
echo Ahora puedes desplegar con: kubectl apply -f k8s-all-in-one.yaml

rem -------------------------
rem Helper: load_or_pull <repo> <tag> <description>
rem Searches for a local image matching <repo> and loads it into minikube.
rem If none found, attempts docker pull <repo>:<tag> and then loads it.
rem -------------------------
:load_or_pull
setlocal EnableDelayedExpansion
set REPO=%1
set TAG=%2
set DESC=%~3

rem Validate arguments to avoid empty invocations
if "%REPO%"=="" (
    echo [WARN] Skipping load: repository argument is missing.
    endlocal
    exit /b 0
)
if "%TAG%"=="" (
    echo [WARN] Skipping load: tag argument is missing for %REPO%.
    endlocal
    exit /b 0
)

set EXPECTED=%REPO%:%TAG%
set "FOUND_IMAGE="

rem First try exact expected tag
for /f "delims=" %%I in ('docker images --format "{{.Repository}}:{{.Tag}}" ^| findstr /I /C:"%EXPECTED%"') do (
    set "FOUND_IMAGE=%%I"
    goto :after_find
)
rem If not found, fall back to any tag for the repo
for /f "delims=" %%I in ('docker images --format "{{.Repository}}:{{.Tag}}" ^| findstr /I /C:"%REPO%:"') do (
    set "FOUND_IMAGE=%%I"
    goto :after_find
)
:after_find
if defined FOUND_IMAGE (
    echo Using local image !FOUND_IMAGE! for %EXPECTED% - %DESC%
    minikube image load !FOUND_IMAGE!
    if %errorlevel% neq 0 (
        echo Error cargando %DESC%
        endlocal
        exit /b 1
    )
    echo ✓ %DESC% cargado (from !FOUND_IMAGE!)
) else (
    echo Local image not found, trying docker pull %EXPECTED% for %DESC%
    docker pull %EXPECTED%
    if %errorlevel% neq 0 (
        echo Error pulling %EXPECTED%
        endlocal
        exit /b 1
    )
    minikube image load %EXPECTED%
    if %errorlevel% neq 0 (
        echo Error cargando %DESC% after pull
        endlocal
        exit /b 1
    )
    echo ✓ %DESC% cargado (pulled %EXPECTED%)
)
endlocal
exit /b 0
