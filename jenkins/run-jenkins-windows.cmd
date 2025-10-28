@echo off
REM Ejecutar Jenkins personalizado en Docker (Windows)
set JENKINS_HOME=%~dp0\jenkins_home
if not exist "%JENKINS_HOME%" mkdir "%JENKINS_HOME%"
echo Iniciando Jenkins con Docker y Maven...

docker run -d ^
  -p 8081:8080 -p 50000:50000 ^
  --name jenkins ^
  -u root ^
  -v "%JENKINS_HOME%:/var/jenkins_home" ^
  -v /var/run/docker.sock:/var/run/docker.sock ^
  -v "%~dp0\jenkins-config.xml:/var/jenkins_home/jenkins-config.xml" ^
  jenkins-docker-maven
