@echo off
REM ================================================
echo Eliminando todos los jobs de Jenkins
REM ================================================

REM Descargar Jenkins CLI si no existe
if not exist jenkins-setup\jenkins-cli.jar curl -o jenkins-setup\jenkins-cli.jar http://localhost:8081/jnlpJars/jenkins-cli.jar

REM Listar todos los jobs
for /f "delims=" %%J in ('java -jar jenkins-setup\jenkins-cli.jar -s http://localhost:8081 -auth admin:admin123 list-jobs') do (
    echo Eliminando job: %%J
    java -jar jenkins-setup\jenkins-cli.jar -s http://localhost:8081 -auth admin:admin123 delete-job "%%J"
)

echo Todos los jobs han sido eliminados.
echo ================================================
