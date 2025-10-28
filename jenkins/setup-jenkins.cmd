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
set plugins=docker-workflow kubernetes kubernetes-cli kubernetes-client-api pipeline-stage-view workflow-aggregator git maven-plugin htmlpublisher junit email-ext build-timeout credentials-binding timestamper ws-cleanup ant gradle pipeline-github-lib pipeline-stage-view pipeline-graph-analysis pipeline-input-step pipeline-milestone-step pipeline-model-definition pipeline-rest-api pipeline-stage-tags-metadata pipeline-utility-steps ssh-slaves matrix-auth pam-auth ldap mailer slack discord-notifier telegram-notifications matrix-project resource-disposer ssh-credentials plain-credentials credentials credentials-binding
for %%p in (%plugins%) do (
    echo Installing plugin: %%p
    java -jar jenkins-cli.jar -s http://localhost:8081 -auth admin:admin123 install-plugin "%%p" -deploy
)
echo All plugins installed successfully!
echo Please restart Jenkins to complete the installation if required.

REM Crear jobs centralizados de dev y stage
REM ================================================
set "JENKINSFILE_DEV=..\pipelines\dev\all-services-dev.Jenkinsfile"
set "XML_FILE_DEV=all-services-dev-job.xml"
if exist %JENKINSFILE_DEV% (
    echo Generando XML para all-services-dev ...
    echo ^<?xml version="1.0" encoding="UTF-8"?^>^<flow-definition plugin="workflow-job@2.42"^>^<description^>Pipeline job for all-services-dev^</description^>^<keepDependencies^>false^</keepDependencies^>^<properties/^>^<definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90"^>^<scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3"^>^<configVersion^>2^</configVersion^>^<userRemoteConfigs^>^<hudson.plugins.git.UserRemoteConfig^>^<url^>https://github.com/lolito996/ecommerce-microservice-backend-app.git^</url^>^</hudson.plugins.git.UserRemoteConfig^>^</userRemoteConfigs^>^<branches^>^<hudson.plugins.git.BranchSpec^>^<name^>*/kubernetes^</name^>^</hudson.plugins.git.BranchSpec^>^</branches^>^<doGenerateSubmoduleConfigurations^>false^</doGenerateSubmoduleConfigurations^>^<submoduleCfg class="list"^>^</submoduleCfg^>^<extensions/^>^</scm^>^<scriptPath^>jenkins/pipelines/dev/all-services-dev.Jenkinsfile^</scriptPath^>^<lightweight^>true^</lightweight^>^</definition^>^<triggers/^>^<disabled^>false^</disabled^>^</flow-definition^> > %XML_FILE_DEV%
    echo Creando job all-services-dev en Jenkins ...
    java -jar jenkins-cli.jar -s http://localhost:8081 -auth admin:admin123 create-job "all-services-dev" < %XML_FILE_DEV%
) else (
    echo El archivo %JENKINSFILE_DEV% no existe, se omite all-services-dev
)

set "JENKINSFILE_STAGE=..\pipelines\stage\all-services-stage.Jenkinsfile"
set "XML_FILE_STAGE=all-services-stage-job.xml"
if exist %JENKINSFILE_STAGE% (
    echo Generando XML para all-services-stage ...
    echo ^<?xml version="1.0" encoding="UTF-8"?^>^<flow-definition plugin="workflow-job@2.42"^>^<description^>Pipeline job for all-services-stage^</description^>^<keepDependencies^>false^</keepDependencies^>^<properties/^>^<definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90"^>^<scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3"^>^<configVersion^>2^</configVersion^>^<userRemoteConfigs^>^<hudson.plugins.git.UserRemoteConfig^>^<url^>https://github.com/lolito996/ecommerce-microservice-backend-app.git^</url^>^</hudson.plugins.git.UserRemoteConfig^>^</userRemoteConfigs^>^<branches^>^<hudson.plugins.git.BranchSpec^>^<name^>*/kubernetes^</name^>^</hudson.plugins.git.BranchSpec^>^</branches^>^<doGenerateSubmoduleConfigurations^>false^</doGenerateSubmoduleConfigurations^>^<submoduleCfg class="list"^>^</submoduleCfg^>^<extensions/^>^</scm^>^<scriptPath^>jenkins/pipelines/stage/all-services-stage.Jenkinsfile^</scriptPath^>^<lightweight^>true^</lightweight^>^</definition^>^<triggers/^>^<disabled^>false^</disabled^>^</flow-definition^> > %XML_FILE_STAGE%
    echo Creando job all-services-stage en Jenkins ...
    java -jar jenkins-cli.jar -s http://localhost:8081 -auth admin:admin123 create-job "all-services-stage" < %XML_FILE_STAGE%
) else (
    echo El archivo %JENKINSFILE_STAGE% no existe, se omite all-services-stage
)

REM ================================================
echo Jenkins setup completed!
echo ================================================
echo Access Jenkins at: http://localhost:8081
echo Username: admin
echo Password: admin123
echo ================================================
