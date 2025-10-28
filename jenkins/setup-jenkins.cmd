@echo off
REM ================================================
echo Setting up Jenkins for Ecommerce Microservices
REM ================================================

REM Crear directorio de trabajo
if not exist jenkins-setup mkdir jenkins-setup
cd jenkins-setup

REM Descargar Jenkins CLI
echo Downloading Jenkins CLI...
curl -o jenkins-cli.jar http://localhost:8081/jnlpJars/jenkins-cli.jar

REM Instalar plugins necesarios
echo Installing Jenkins plugins...
set plugins=docker-workflow kubernetes kubernetes-cli kubernetes-client-api pipeline-stage-view workflow-aggregator git maven-plugin htmlpublisher junit email-ext build-timeout credentials-binding timestamper ws-cleanup ant gradle pipeline-github-lib pipeline-stage-view pipeline-graph-analysis pipeline-input-step pipeline-milestone-step pipeline-model-definition pipeline-rest-api pipeline-stage-tags-metadata pipeline-utility-steps ssh-slaves matrix-auth pam-auth ldap email-ext mailer slack discord-notifier telegram-notifications matrix-project resource-disposer ssh-credentials plain-credentials credentials credentials-binding ssh-slaves matrix-auth pam-auth ldap email-ext mailer slack discord-notifier telegram-notifications
for %%p in (%plugins%) do (
    echo Installing plugin: %%p
    java -jar jenkins-cli.jar -s http://localhost:8081 -auth admin:admin123 install-plugin "%%p" -deploy
)
echo All plugins installed successfully!
echo Please restart Jenkins to complete the installation if required.



REM Crear jobs de pipeline usando XML mínimo
echo Creating Jenkins jobs...

setlocal enabledelayedexpansion
set SERVICES=user-service product-service order-service payment-service favourite-service proxy-client
set ENVIRONMENTS=dev stage

for %%S in (%SERVICES%) do (
    for %%E in (%ENVIRONMENTS%) do (
        set "JOB_NAME=%%S-%%E"
        set "JENKINSFILE=..\pipelines\%%E\%%S-%%E.Jenkinsfile"
        set "XML_FILE=%%S-%%E-job.xml"
        if exist !JENKINSFILE! (
            echo Generando XML para !JOB_NAME! ...
            echo ^<?xml version="1.0" encoding="UTF-8"?^>^<flow-definition plugin="workflow-job@2.42"^>^<description^>Pipeline job for !JOB_NAME!^</description^>^<keepDependencies^>false^</keepDependencies^>^<properties/^>^<definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.90"^>^<scriptPath^>pipelines/%%E/%%S-%%E.Jenkinsfile^</scriptPath^>^<sandbox^>true^</sandbox^>^</definition^>^<triggers/^>^<disabled^>false^</disabled^>^</flow-definition^> > !XML_FILE!
            echo Creando job !JOB_NAME! en Jenkins ...
            java -jar jenkins-cli.jar -s http://localhost:8081 -auth admin:admin123 create-job "!JOB_NAME!" < !XML_FILE!
        ) else (
            echo El archivo !JENKINSFILE! no existe, se omite !JOB_NAME!
        )
    )
)

REM All Services Job (solo dev)
set "JENKINSFILE=..\pipelines\dev\all-services-dev.Jenkinsfile"
set "XML_FILE=all-services-dev-job.xml"
if exist !JENKINSFILE! (
    echo Generando XML para all-services-dev ...
    echo ^<?xml version="1.0" encoding="UTF-8"?^>^<flow-definition plugin="workflow-job@2.42"^>^<description^>Pipeline job for all-services-dev^</description^>^<keepDependencies^>false^</keepDependencies^>^<properties/^>^<definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.90"^>^<scriptPath^>pipelines/dev/all-services-dev.Jenkinsfile^</scriptPath^>^<sandbox^>true^</sandbox^>^</definition^>^<triggers/^>^<disabled^>false^</disabled^>^</flow-definition^> > !XML_FILE!
    echo Creando job all-services-dev en Jenkins ...
    java -jar jenkins-cli.jar -s http://localhost:8081 -auth admin:admin123 create-job "all-services-dev" < !XML_FILE!
) else (
    echo El archivo !JENKINSFILE! no existe, se omite all-services-dev
)
endlocal

REM ================================================
echo Jenkins setup completed!
echo ================================================
echo Access Jenkins at: http://localhost:8081
echo Username: admin
echo Password: admin123
echo ================================================
