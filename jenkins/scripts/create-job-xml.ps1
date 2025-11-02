param(
    [Parameter(Mandatory=$true)][string]$TempXml,
    [Parameter(Mandatory=$true)][string]$ScriptPath,
    [Parameter(Mandatory=$true)][string]$RepoUrl,
    [Parameter(Mandatory=$true)][string]$Branch,
    [Parameter(Mandatory=$true)][string]$JobDesc
)

# Write the Jenkins job XML with UTF8 encoding
$xml = @"
<?xml version="1.1" encoding="UTF-8"?>
<flow-definition plugin="workflow-job@2.42">
  <description>Pipeline job for $JobDesc</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.8.3">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>$RepoUrl</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/$Branch</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"></submoduleCfg>
      <extensions/>
    </scm>
    <scriptPath>$ScriptPath</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
"@

try {
    $xml | Out-File -FilePath $TempXml -Encoding UTF8 -Force
    exit 0
} catch {
    Write-Error "Failed to write XML to $TempXml: $_"
    exit 1
}
