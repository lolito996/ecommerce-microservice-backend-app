param(
    [Parameter(Mandatory=$true)][string]$TempXml,
    [Parameter(Mandatory=$true)][string]$JobName,
    [Parameter(Mandatory=$true)][string]$JenkinsfilePath,
    [Parameter()][string]$JobDesc = "local-inline-job"
)

if (-not (Test-Path $JenkinsfilePath)) {
    Write-Error "Jenkinsfile not found at path: $JenkinsfilePath"
    exit 1
}

try {
    $scriptContent = Get-Content -Path $JenkinsfilePath -Raw -Encoding UTF8
} catch {
    Write-Error "Failed to read Jenkinsfile: $_"
    exit 1
}

# Replace common 'checkout scm' patterns with a local copy step that uses /srv/repo inside the Jenkins container
$pattern = '(?m)\bcheckout\s+scm\b'
if ($scriptContent -match $pattern) {
    Write-Host "Detected 'checkout scm' in Jenkinsfile; replacing with local copy from /srv/repo"
    $copySnippet = "sh 'echo \"Copying local repo into workspace from /srv/repo...\"'`nsh 'cp -a /srv/repo/. \$WORKSPACE/\'"
    $scriptContent = [System.Text.RegularExpressions.Regex]::Replace($scriptContent, $pattern, [System.Text.RegularExpressions.Regex]::Escape($copySnippet), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    # The previous Replace escaped characters; unescape back to literal
    $scriptContent = $scriptContent -replace '\\Q','' -replace '\\E',''
}

$xml = @'
<?xml version="1.1" encoding="UTF-8"?>
<flow-definition plugin="workflow-job@2.42">
  <description>Pipeline job for PLACEHOLDER_JOBDESC</description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsFlowDefinition" plugin="workflow-cps@2.90">
    <script><![CDATA[
PLACEHOLDER_SCRIPT
    ]]></script>
    <sandbox>true</sandbox>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
'@

# Inject values
$xml = $xml -replace 'PLACEHOLDER_SCRIPT', [System.Web.HttpUtility]::HtmlEncode($scriptContent) -replace 'PLACEHOLDER_JOBDESC', [System.Web.HttpUtility]::HtmlEncode($JobDesc)

try {
    # Write raw XML (script is HTML-encoded to be safe inside CDATA); then unencode CDATA area
    $xml | Out-File -FilePath $TempXml -Encoding UTF8 -Force
    # Now replace the encoded CDATA section with raw script inside CDATA
    $fileText = Get-Content -Path $TempXml -Raw -Encoding UTF8
    $fileText = $fileText -replace '&lt;!\[CDATA\[', '<![CDATA[' -replace '\]\]&gt;', ']]>'
    # Undo HTML encoding inside CDATA area
    $fileText = $fileText -replace 'PLACEHOLDER_SCRIPT', [System.Text.RegularExpressions.Regex]::Escape($scriptContent)
    Set-Content -Path $TempXml -Value $fileText -Encoding UTF8
    exit 0
} catch {
    Write-Error "Failed to write XML to $TempXml: $_"
    exit 1
}
