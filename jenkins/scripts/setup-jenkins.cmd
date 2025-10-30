@echo off
setlocal

REM Jenkins bootstrap for ecommerce stack
echo Setting up Jenkins for Ecommerce Microservices

set "JENKINS_URL=http://localhost:8081"
set "JENKINS_AUTH=admin:admin123"

REM Resolve absolute paths regardless of invocation point
set "SCRIPT_DIR=%~dp0"
for %%i in ("%SCRIPT_DIR%..") do set "ROOT_DIR=%%~fi"
set "SETUP_DIR=%SCRIPT_DIR%jenkins-setup"
set "DEV_JOB_NAME=all-services-dev"
set "STAGE_JOB_NAME=all-services-stage"
set "DEV_JENKINSFILE=%ROOT_DIR%\pipelines\dev\all-services-dev.Jenkinsfile"
set "STAGE_JENKINSFILE=%ROOT_DIR%\pipelines\stage\all-services-stage.Jenkinsfile"
set "DEV_XML=%SETUP_DIR%\%DEV_JOB_NAME%-job.xml"
set "STAGE_XML=%SETUP_DIR%\%STAGE_JOB_NAME%-job.xml"

if not exist "%SETUP_DIR%" mkdir "%SETUP_DIR%"
pushd "%SETUP_DIR%"

echo Downloading Jenkins CLI...
curl -f -L -o jenkins-cli.jar "%JENKINS_URL%/jnlpJars/jenkins-cli.jar"
if errorlevel 1 (
	echo Failed to download Jenkins CLI from %JENKINS_URL%.
	popd
	exit /b 1
)

echo Installing Jenkins plugins...
set plugins=docker-workflow kubernetes kubernetes-cli kubernetes-client-api pipeline-stage-view workflow-aggregator git maven-plugin junit email-ext build-timeout credentials-binding timestamper ws-cleanup pipeline-graph-analysis pipeline-input-step pipeline-milestone-step pipeline-model-definition pipeline-rest-api pipeline-stage-tags-metadata pipeline-utility-steps ssh-slaves matrix-auth pam-auth ldap mailer matrix-project resource-disposer ssh-credentials plain-credentials credentials
for %%p in (%plugins%) do (
	echo Installing plugin: %%p
	java -jar "%SETUP_DIR%\jenkins-cli.jar" -s %JENKINS_URL% -auth %JENKINS_AUTH% install-plugin "%%p" -deploy
	if errorlevel 1 (
		echo Failed installing plugin %%p. Check connectivity to updates.jenkins.io.
		popd
		exit /b 1
	)
)

REM Remove optional plugins that generate security warnings
set removePlugins=htmlpublisher slack discord-notifier telegram-notifications ant gradle pipeline-github-lib
for %%p in (%removePlugins%) do (
	echo Removing optional plugin: %%p
	java -jar "%SETUP_DIR%\jenkins-cli.jar" -s %JENKINS_URL% -auth %JENKINS_AUTH% uninstall-plugin "%%p" || echo "Plugin %%p could not be removed (may not be installed)."
)

REM Generate and post pipeline jobs
if exist "%DEV_JENKINSFILE%" (
	(
		echo ^<?xml version="1.0" encoding="UTF-8"?^>
		echo ^<flow-definition plugin="workflow-job@2.42"^>
		echo   ^<description^>Pipeline job for %DEV_JOB_NAME%^</description^>
		echo   ^<keepDependencies^>false^</keepDependencies^>
		echo   ^<properties/^>
		echo   ^<definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90"^>
		echo     ^<scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3"^>
		echo       ^<configVersion^>2^</configVersion^>
		echo       ^<userRemoteConfigs^>
		echo         ^<hudson.plugins.git.UserRemoteConfig^>
		echo           ^<url^>https://github.com/lolito996/ecommerce-microservice-backend-app.git^</url^>
		echo         ^</hudson.plugins.git.UserRemoteConfig^>
		echo       ^</userRemoteConfigs^>
		echo       ^<branches^>
		echo         ^<hudson.plugins.git.BranchSpec^>
		echo           ^<name^>*/kubernetes^</name^>
		echo         ^</hudson.plugins.git.BranchSpec^>
		echo       ^</branches^>
		echo       ^<doGenerateSubmoduleConfigurations^>false^</doGenerateSubmoduleConfigurations^>
		echo       ^<submoduleCfg class="list"/^>
		echo       ^<extensions/^>
		echo     ^</scm^>
		echo     ^<scriptPath^>jenkins/pipelines/dev/all-services-dev.Jenkinsfile^</scriptPath^>
		echo     ^<lightweight^>true^</lightweight^>
		echo   ^</definition^>
		echo   ^<triggers/^>
		echo   ^<disabled^>false^</disabled^>
		echo ^</flow-definition^>
	) > "%DEV_XML%"
	echo Creating job %DEV_JOB_NAME% ...
	java -jar "%SETUP_DIR%\jenkins-cli.jar" -s %JENKINS_URL% -auth %JENKINS_AUTH% create-job "%DEV_JOB_NAME%" < "%DEV_XML%"
) else (
	echo Jenkinsfile not found: %DEV_JENKINSFILE%
)

if exist "%STAGE_JENKINSFILE%" (
	(
		echo ^<?xml version="1.0" encoding="UTF-8"?^>
		echo ^<flow-definition plugin="workflow-job@2.42"^>
		echo   ^<description^>Pipeline job for %STAGE_JOB_NAME%^</description^>
		echo   ^<keepDependencies^>false^</keepDependencies^>
		echo   ^<properties/^>
		echo   ^<definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90"^>
		echo     ^<scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3"^>
		echo       ^<configVersion^>2^</configVersion^>
		echo       ^<userRemoteConfigs^>
		echo         ^<hudson.plugins.git.UserRemoteConfig^>
		echo           ^<url^>https://github.com/lolito996/ecommerce-microservice-backend-app.git^</url^>
		echo         ^</hudson.plugins.git.UserRemoteConfig^>
		echo       ^</userRemoteConfigs^>
		echo       ^<branches^>
		echo         ^<hudson.plugins.git.BranchSpec^>
		echo           ^<name^>*/kubernetes^</name^>
		echo         ^</hudson.plugins.git.BranchSpec^>
		echo       ^</branches^>
		echo       ^<doGenerateSubmoduleConfigurations^>false^</doGenerateSubmoduleConfigurations^>
		echo       ^<submoduleCfg class="list"/^>
		echo       ^<extensions/^>
		echo     ^</scm^>
		echo     ^<scriptPath^>jenkins/pipelines/stage/all-services-stage.Jenkinsfile^</scriptPath^>
		echo     ^<lightweight^>true^</lightweight^>
		echo   ^</definition^>
		echo   ^<triggers/^>
		echo   ^<disabled^>false^</disabled^>
		echo ^</flow-definition^>
	) > "%STAGE_XML%"
	echo Creating job %STAGE_JOB_NAME% ...
	java -jar "%SETUP_DIR%\jenkins-cli.jar" -s %JENKINS_URL% -auth %JENKINS_AUTH% create-job "%STAGE_JOB_NAME%" < "%STAGE_XML%"
) else (
	echo Jenkinsfile not found: %STAGE_JENKINSFILE%
)

popd
echo Jenkins setup finished.
exit /b 0
