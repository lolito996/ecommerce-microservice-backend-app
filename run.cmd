@echo off
setlocal enabledelayedexpansion

REM Limpieza opcional de contenedores viejos con nombres fijos (si quedaron de intentos anteriores)
echo [run-all] Verificando contenedores previos (zipkin, service-discovery-container, cloud-config-container)...
for %%C in (zipkin service-discovery-container cloud-config-container) do (
  docker inspect %%C >nul 2>&1 && (
    echo [run-all] Eliminando contenedor previo: %%C
    docker rm -f %%C >nul 2>&1
  )
)

echo [run-all] Iniciando servicios core (Zipkin, Eureka, Config Server)...
docker-compose -f core.yml up -d
if errorlevel 1 (
  echo [run-all] ERROR: Fallo al levantar core.yml
  exit /b 1
)

REM Obtener IDs de contenedor reales creados por docker-compose
for /f %%i in ('docker-compose -f core.yml ps -q service-discovery-container') do set EUREKA_ID=%%i
for /f %%i in ('docker-compose -f core.yml ps -q cloud-config-container') do set CONFIG_ID=%%i

echo [run-all] Eureka ID: %EUREKA_ID%
echo [run-all] Config  ID: %CONFIG_ID%

REM Esperar a que Eureka este listo
call :wait_eureka 120

REM Esperar a que Config Server este listo
call :wait_config 120

REM Levantar primero el ORDER-SERVICE y esperar readiness
echo [run-all] Iniciando order-service-container primero...
docker-compose -f compose.yml up -d order-service-container
if errorlevel 1 (
  echo [run-all] ERROR: Fallo al levantar order-service-container
  exit /b 1
)
for /f %%i in ('docker-compose -f compose.yml ps -q order-service-container') do set ORDER_ID=%%i
call :wait_order 180

REM Levantar PRODUCT-SERVICE y esperar readiness
echo [run-all] Iniciando product-service-container...
docker-compose -f compose.yml up -d product-service-container
if errorlevel 1 (
  echo [run-all] ERROR: Fallo al levantar product-service-container
  exit /b 1
)
for /f %%i in ('docker-compose -f compose.yml ps -q product-service-container') do set PRODUCT_ID=%%i
call :wait_product 180

echo [run-all] Iniciando servicios de aplicacion restantes...
docker-compose -f compose.yml up -d
if errorlevel 1 (
  echo [run-all] ERROR: Fallo al levantar compose.yml
  exit /b 1
)

echo.
echo [run-all] Servicios levantados. Contenedores en ejecucion:
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
exit /b 0

:wait_eureka
REM Arguments: %1 = timeout (segundos)
set /a TIMEOUT=%~1
if "%TIMEOUT%"=="" set TIMEOUT=120
if not defined EUREKA_ID (
  echo [run-all] ADVERTENCIA: No se obtuvo el ID de Eureka; se usara el nombre del servicio
  set EUREKA_ID=service-discovery-container
)
echo [run-all] Esperando a Eureka (%EUREKA_ID%) hasta %TIMEOUT%s...
for /l %%i in (1,1,%TIMEOUT%) do (
  docker logs %EUREKA_ID% 2>&1 | findstr /C:"Finished initializing remote region registries" >nul && goto :eureka_ready
  docker logs %EUREKA_ID% 2>&1 | findstr /C:"Started" >nul && goto :eureka_ready
  if %%i lss %TIMEOUT% (
    >nul ping -n 2 127.0.0.1
  )
)
echo [run-all] AVISO: Timeout esperando Eureka; se continuara de todas formas.
goto :eureka_end
:eureka_ready
echo [run-all] Eureka listo.
:eureka_end
exit /b 0

:wait_config
REM Arguments: %1 = timeout (segundos)
set /a TIMEOUT=%~1
if "%TIMEOUT%"=="" set TIMEOUT=120
if not defined CONFIG_ID (
  echo [run-all] ADVERTENCIA: No se obtuvo el ID de Config Server; se usara el nombre del servicio
  set CONFIG_ID=cloud-config-container
)
echo [run-all] Esperando a Config Server (%CONFIG_ID%) hasta %TIMEOUT%s...
for /l %%i in (1,1,%TIMEOUT%) do (
  docker logs %CONFIG_ID% 2>&1 | findstr /C:"Tomcat started on port(s): 9296" >nul && goto :config_ready
  docker logs %CONFIG_ID% 2>&1 | findstr /C:"Started" >nul && goto :config_ready
  if %%i lss %TIMEOUT% (
    >nul ping -n 2 127.0.0.1
  )
)
echo [run-all] AVISO: Timeout esperando Config Server; se continuara de todas formas.
goto :config_end
:config_ready
echo [run-all] Config Server listo.
:config_end
exit /b 0

:wait_order
REM Arguments: %1 = timeout (segundos)
set /a TIMEOUT=%~1
if "%TIMEOUT%"=="" set TIMEOUT=180
if not defined ORDER_ID (
  echo [run-all] ADVERTENCIA: No se obtuvo el ID de Order Service; se usara el nombre del servicio
  set ORDER_ID=order-service-container
)
echo [run-all] Esperando a Order Service (%ORDER_ID%) hasta %TIMEOUT%s...
for /l %%i in (1,1,%TIMEOUT%) do (
  docker logs %ORDER_ID% 2>&1 | findstr /C:"Tomcat started on port(s): 8300" >nul && goto :order_ready
  docker logs %ORDER_ID% 2>&1 | findstr /C:"Started" >nul && goto :order_ready
  if %%i lss %TIMEOUT% (
    >nul ping -n 2 127.0.0.1
  )
)
echo [run-all] AVISO: Timeout esperando Order Service; se continuara de todas formas.
goto :order_end
:order_ready
echo [run-all] Order Service listo.
:order_end
exit /b 0

:wait_product
REM Arguments: %1 = timeout (segundos)
set /a TIMEOUT=%~1
if "%TIMEOUT%"=="" set TIMEOUT=180
if not defined PRODUCT_ID (
  echo [run-all] ADVERTENCIA: No se obtuvo el ID de Product Service; se usara el nombre del servicio
  set PRODUCT_ID=product-service-container
)
echo [run-all] Esperando a Product Service (%PRODUCT_ID%) hasta %TIMEOUT%s...
for /l %%i in (1,1,%TIMEOUT%) do (
  docker logs %PRODUCT_ID% 2>&1 | findstr /C:"Tomcat started on port(s): 8500" >nul && goto :product_ready
  docker logs %PRODUCT_ID% 2>&1 | findstr /C:"Started" >nul && goto :product_ready
  if %%i lss %TIMEOUT% (
    >nul ping -n 2 127.0.0.1
  )
)
echo [run-all] AVISO: Timeout esperando Product Service; se continuara de todas formas.
goto :product_end
:product_ready
echo [run-all] Product Service listo.
:product_end
exit /b 0