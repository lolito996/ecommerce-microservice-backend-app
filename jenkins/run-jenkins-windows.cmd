@echo off
REM Ejecutar Jenkins en Docker (Windows)
set JENKINS_HOME=%~dp0\jenkins_home
if not exist "%JENKINS_HOME%" mkdir "%JENKINS_HOME%"
echo Iniciando Jenkins en Docker...
docker run -d -p 8081:8080 -p 50000:50000 --name jenkins -v "%JENKINS_HOME%:/var/jenkins_home" -v "%~dp0\jenkins-config.xml:/var/jenkins_home/jenkins-config.xml" jenkins/jenkins:lts
