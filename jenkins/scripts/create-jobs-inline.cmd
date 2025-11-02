@echo off
setlocal enabledelayedexpansion

echo Creando Jenkins Pipeline Jobs (inline) desde archivos locales

rem Determine script directory and put jenkins-cli.jar there
for %%i in ("%~dp0") do set SCRIPT_DIR=%%~fi
rem ensure jenkins-setup directory exists under scripts
if not exist "%SCRIPT_DIR%jenkins-setup" mkdir "%SCRIPT_DIR%jenkins-setup"
set JENKINS_CLI=%SCRIPT_DIR%jenkins-setup\jenkins-cli.jar
set JENKINS_URL=http://localhost:8081
set JENKINS_AUTH=admin:admin123
rem Repository settings for SCM-based jobs (change if you use a mirror)
set REPO_URL=https://github.com/lolito996/ecommerce-microservice-backend-app.git
set BRANCH=pipelines

for %%i in ("%~dp0..") do set ROOT_DIR=%%~fi
set PIPELINES_DIR=%ROOT_DIR%\jenkins\pipelines

if not exist "%JENKINS_CLI%" (
    echo jenkins-cli.jar not found in %SCRIPT_DIR%, attempting to download from %JENKINS_URL%/jnlpJars/jenkins-cli.jar
    curl -f -L -o "%JENKINS_CLI%" "%JENKINS_URL%/jnlpJars/jenkins-cli.jar"
    if errorlevel 1 (
        echo Failed to download jenkins-cli.jar. Ensure Jenkins is running and accessible at %JENKINS_URL%.
        exit /b 1
    ) else (
        echo Downloaded jenkins-cli.jar to %JENKINS_CLI%
    )
)

REM Iterate Jenkinsfiles under pipelines directory
for /R "%PIPELINES_DIR%" %%F in (*.Jenkinsfile) do (
    set "REL=%%~pF"
    set "BASENAME=%%~nF"
    echo Found Jenkinsfile: %%F
    REM Build job name from relative path: replace \ with - and trim leading \ if present
    set "REL_SHORT=!REL:~1,-0!"
    set "REL_SHORT=!REL_SHORT:\=-!"
    if defined REL_SHORT (
        set JOB_NAME=!REL_SHORT!!BASENAME!
    ) else (
        set JOB_NAME=!BASENAME!
    )
    REM sanitize job name (remove trailing -)
    set JOB_NAME=!JOB_NAME:--=-!
    echo Calculated job name: !JOB_NAME!
    echo Creating job: !JOB_NAME!
    set TEMP_XML=%TEMP%\!BASENAME!-inline.xml
    if exist "!TEMP_XML!" del /f /q "!TEMP_XML!" >nul 2>&1
    REM Compute script path relative to repo root (use forward slashes for XML)
    set "REL_FULL=%%~fF"
    set "SCRIPT_PATH=!REL_FULL:%ROOT_DIR%\=!"
    set "SCRIPT_PATH=!SCRIPT_PATH:\=/!"
    echo Using script path: !SCRIPT_PATH!
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0create-job-xml.ps1" -TempXml "!TEMP_XML!" -ScriptPath "!SCRIPT_PATH!" -RepoUrl "%REPO_URL%" -Branch "%BRANCH%" -JobDesc "!JOB_NAME!"
    if errorlevel 1 (
        echo Failed to write temp XML for %%F
        exit /b 1
    )
    java -jar "%JENKINS_CLI%" -s %JENKINS_URL% -auth %JENKINS_AUTH% create-job "!JOB_NAME!" < "!TEMP_XML!"
    if errorlevel 1 (
        echo Failed creating job !JOB_NAME!. Check Jenkins logs.
    ) else (
        echo Job !JOB_NAME! creado.
    )
    if exist "!TEMP_XML!" del /f /q "!TEMP_XML!" >nul 2>&1
)

echo Todos los Jenkins jobs inline han sido creados!
echo Accede a Jenkins en: %JENKINS_URL%
endlocal
