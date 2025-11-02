@echo off
setlocal enabledelayedexpansion

REM ===============================
echo Creando Jenkins Pipeline Jobs con XML
REM ===============================

REM Configura la ruta de Jenkins CLI y credenciales
set JENKINS_CLI=jenkins-cli.jar
set JENKINS_URL=http://localhost:8081
set JENKINS_AUTH=admin:admin123
REM Use the public repo URL so Jenkins agents can clone it. Change if you use a private mirror.
set REPO_URL=https://github.com/lolito996/ecommerce-microservice-backend-app.git
REM Default branch used by the Jenkins jobs. Update if your pipeline branch differs.
set BRANCH=pipelines

REM Ensure we have jenkins-cli.jar available locally (download from Jenkins if needed)
if not exist "%JENKINS_CLI%" (
    echo jenkins-cli.jar not found, attempting to download from %JENKINS_URL%/jnlpJars/jenkins-cli.jar
    curl -f -L -o "%JENKINS_CLI%" "%JENKINS_URL%/jnlpJars/jenkins-cli.jar"
    if errorlevel 1 (
        echo Failed to download jenkins-cli.jar. Ensure Jenkins is running and accessible at %JENKINS_URL%.
        exit /b 1
    )
)

REM Carpetas y servicios
REM Compute absolute paths relative to this script so the script can be executed from any CWD
set "SCRIPT_DIR=%~dp0"
for %%i in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fi"
set DEV_DIR=%ROOT_DIR%\pipelines\dev
set SERVICE_DIR=%ROOT_DIR%\pipelines\service
set SERVICES=api-gateway cloud-config favourite-service order-service payment-service product-service proxy-client service-discovery shipping-service user-service zipkin

REM Crear jobs para cada servicio en dev usando XML por echo y pipe
for %%S in (%SERVICES%) do (
    set JOB_NAME=%%S-dev
    set JENKINSFILE_DEV=%DEV_DIR%\%%S-dev.Jenkinsfile
    set JENKINSFILE_SERVICE=%SERVICE_DIR%\%%S-dev.Jenkinsfile
    set SCRIPT_PATH=
    if exist "!JENKINSFILE_DEV!" (
        set SCRIPT_PATH=pipelines/dev/%%S-dev.Jenkinsfile
    ) else if exist "!JENKINSFILE_SERVICE!" (
        set SCRIPT_PATH=pipelines/service/%%S-dev.Jenkinsfile
    )

        if defined SCRIPT_PATH (
                echo Creando !JOB_NAME! usando !SCRIPT_PATH! ...
                set TEMP_XML=%TEMP%\%%S-job.xml
                if exist "!TEMP_XML!" del /f /q "!TEMP_XML!" >nul 2>&1
                REM Use a PowerShell helper script to write the XML safely (avoids complex quoting in cmd)
                if not exist "%SCRIPT_DIR%create-job-xml.ps1" (
                    echo PowerShell helper script not found: %SCRIPT_DIR%create-job-xml.ps1
                    exit /b 1
                )
                powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%create-job-xml.ps1" -TempXml "!TEMP_XML!" -ScriptPath "!SCRIPT_PATH!" -RepoUrl "%REPO_URL%" -Branch "%BRANCH%" -JobDesc "%%S-dev"
                if errorlevel 1 (
                    echo Failed to write temporary XML for %%S
                    exit /b 1
                )

                    java -jar %JENKINS_CLI% -s %JENKINS_URL% -auth %JENKINS_AUTH% create-job "!JOB_NAME!" < "!TEMP_XML!"
                    if errorlevel 1 (
                            echo Failed creating job !JOB_NAME!. Check Jenkins logs.
                    ) else (
                            echo Job !JOB_NAME! creado.
                    )
                    if exist "!TEMP_XML!" del /f /q "!TEMP_XML!" >nul 2>&1
            ) else (
                    echo El archivo para %%S no existe en %DEV_DIR% ni en %SERVICE_DIR%, se omite !JOB_NAME!
            )
)

REM ===============================
echo Todos los Jenkins jobs han sido creados!
echo Accede a Jenkins en: %JENKINS_URL%
echo Usuario: admin
 echo Password: admin123
REM ===============================
endlocal