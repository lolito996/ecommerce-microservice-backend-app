@echo off
setlocal enabledelayedexpansion

REM ===============================
echo Creando Jenkins Pipeline Jobs con XML
REM ===============================

REM Configura la ruta de Jenkins CLI y credenciales
set JENKINS_CLI=jenkins-cli.jar
set JENKINS_URL=http://localhost:8081
set JENKINS_AUTH=admin:admin123
set REPO_URL=file:///C:/Users/alejo/OneDrive/Documentos/SEMESTRE%20VIII/ingesoft%205/backend%20ecommerce/ecommerce-microservice-backend-app
set BRANCH=kubectl

REM Carpetas y servicios
set DEV_DIR=pipelines\dev
set SERVICES=api-gateway cloud-config favourite-service order-service payment-service product-service proxy-client service-discovery shipping-service user-service zipkin

REM Crear jobs para cada servicio en dev usando XML por echo y pipe
for %%S in (%SERVICES%) do (
    set JOB_NAME=%%S-dev
    set JENKINSFILE=%DEV_DIR%\%%S-dev.Jenkinsfile
    if exist !JENKINSFILE! (
        echo Creando !JOB_NAME! ...
        echo ^<?xml version='1.1' encoding='UTF-8'?^>^<flow-definition plugin="workflow-job@2.42"^>^<description^>Pipeline job for %%S-dev^</description^>^<keepDependencies^>false^</keepDependencies^>^<properties/^>^<definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90"^>^<scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3"^>^<configVersion^>2^</configVersion^>^<userRemoteConfigs^>^<hudson.plugins.git.UserRemoteConfig^>^<url^>%REPO_URL%^</url^>^</hudson.plugins.git.UserRemoteConfig^>^</userRemoteConfigs^>^<branches^>^<hudson.plugins.git.BranchSpec^>^<name^>*/%BRANCH%^</name^>^</hudson.plugins.git.BranchSpec^>^</branches^>^<doGenerateSubmoduleConfigurations^>false^</doGenerateSubmoduleConfigurations^>^<submoduleCfg class="list"^>^</submoduleCfg^>^<extensions/^>^</scm^>^<scriptPath^>pipelines/dev/%%S-dev.Jenkinsfile^</scriptPath^>^<lightweight^>true^</lightweight^>^</definition^>^<triggers/^>^<disabled^>false^</disabled^>^</flow-definition^> | java -jar %JENKINS_CLI% -s %JENKINS_URL% -auth %JENKINS_AUTH% create-job "!JOB_NAME!"
    ) else (
        echo El archivo !JENKINSFILE! no existe, se omite !JOB_NAME!
    )
)

REM ===============================
echo Todos los Jenkins jobs han sido creados!
echo Accede a Jenkins en: %JENKINS_URL%
echo Usuario: admin
 echo Password: admin123
REM ===============================
endlocal