@echo off
setlocal

REM Helper: run setup-jenkins.cmd and verify that all-services-dev and all-services-stage jobs exist
echo Running Jenkins setup and verifying jobs...

for %%i in ("%~dp0") do set SCRIPT_DIR=%%~fi
set SETUP_CMD=%SCRIPT_DIR%setup-jenkins.cmd
set SETUP_DIR=%SCRIPT_DIR%jenkins-setup
set JENKINS_CLI=%SETUP_DIR%\jenkins-cli.jar
set JENKINS_URL=http://localhost:8081
set JENKINS_AUTH=admin:admin123

if not exist "%SETUP_CMD%" (
    echo setup-jenkins.cmd not found in %SCRIPT_DIR%
    exit /b 1
)

echo 1/2: Running setup-jenkins.cmd (this will download CLI, install plugins and create jobs)...
call "%SETUP_CMD%"
if errorlevel 1 (
    echo setup-jenkins.cmd failed. Check its output and the Jenkins logs (docker logs jenkins).
    exit /b 1
)

echo 2/2: Verifying jobs exist via jenkins-cli...
if not exist "%JENKINS_CLI%" (
    echo jenkins-cli.jar not found in %SETUP_DIR%. Attempting to download...
    curl -f -L -o "%JENKINS_CLI%" "%JENKINS_URL%/jnlpJars/jenkins-cli.jar"
    if errorlevel 1 (
        echo Failed to download jenkins-cli.jar. Ensure Jenkins is running at %JENKINS_URL% and try again.
        exit /b 1
    )
)

echo Listing jobs to temporary file...
set JOBS_FILE=%TEMP%\jenkins-jobs-list.txt
if exist "%JOBS_FILE%" del /f /q "%JOBS_FILE%" >nul 2>&1
java -jar "%JENKINS_CLI%" -s %JENKINS_URL% -auth %JENKINS_AUTH% list-jobs > "%JOBS_FILE%" 2>&1
if errorlevel 1 (
    echo Failed to list jobs via jenkins-cli. Check Jenkins availability at %JENKINS_URL% and jenkins-cli output.
    type "%JOBS_FILE%"
    exit /b 3
)

echo Jobs available:
type "%JOBS_FILE%"

set FOUND_DEV=0
set FOUND_STAGE=0
findstr /I /R "^all-services-dev$" "%JOBS_FILE%" >nul && set FOUND_DEV=1
findstr /I /R "^all-services-stage$" "%JOBS_FILE%" >nul && set FOUND_STAGE=1

if "%FOUND_DEV%"=="1" (
    echo all-services-dev: FOUND
) else (
    echo all-services-dev: MISSING
)

if "%FOUND_STAGE%"=="1" (
    echo all-services-stage: FOUND
) else (
    echo all-services-stage: MISSING
)

if "%FOUND_DEV%"=="1" if "%FOUND_STAGE%"=="1" (
    echo All required jobs are present.
    del /f /q "%JOBS_FILE%" >nul 2>&1
    exit /b 0
)

echo One or more required jobs are missing. Inspect %SETUP_DIR% for generated XML and check Jenkins logs: docker logs jenkins
del /f /q "%JOBS_FILE%" >nul 2>&1
exit /b 2
