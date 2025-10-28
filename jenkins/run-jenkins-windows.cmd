@echo off
echo ================================================
echo   Starting Jenkins with Docker Access (Windows)
echo ================================================

REM Crear volumen para Jenkins
docker volume create jenkins_home

REM Iniciar Jenkins con acceso al socket de Docker Desktop
docker run -d ^
  --name jenkins ^
  -u root ^
  -p 8081:8080 ^
  -p 50000:50000 ^
  -v jenkins_home:/var/jenkins_home ^
  -v /var/run/docker.sock:/var/run/docker.sock ^
  jenkins-docker

echo.
echo Jenkins started successfully!
echo Access Jenkins at: http://localhost:8081
echo.

:waitloop
docker exec jenkins sh -c "test -f /var/jenkins_home/secrets/initialAdminPassword" >nul 2>&1
if %errorlevel% neq 0 (
    timeout /t 5 >nul
    goto waitloop
)

echo Initial admin password:
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
