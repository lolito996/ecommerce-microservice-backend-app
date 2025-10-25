@echo off
REM Detener y eliminar todos los contenedores del proyecto
echo [stop-all] Deteniendo todos los servicios de core.yml y compose.yml...
docker-compose -f core.yml down
docker-compose -f compose.yml down
echo [stop-all] Listo.