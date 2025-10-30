@echo off
REM ================================================
echo Starting Jenkins for Ecommerce Microservices
REM ================================================

REM Verificar que Docker está corriendo
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not running. Please start Docker first.
    exit /b 1
)

REM Crear directorio de Jenkins si no existe
if not exist jenkins-data mkdir jenkins-data

REM Levantar Jenkins con Docker Compose
echo 🚀 Starting Jenkins...
docker-compose up -d

REM Esperar a que Jenkins esté listo
echo ⏳ Waiting for Jenkins to start...
timeout /t 30 /nobreak >nul

REM Verificar que Jenkins está corriendo
curl -s http://localhost:8081 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Jenkins is running at http://localhost:8081
    echo ================================================
    echo Next steps:
    echo 1. Access Jenkins at http://localhost:8081
    echo 2. Run: setup-jenkins.cmd
    echo ================================================
) else (
    echo ❌ Jenkins failed to start. Check logs with: docker logs jenkins
    exit /b 1
)
