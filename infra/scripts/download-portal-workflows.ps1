# ------------------------------------------------------------------------------------------------------------------------
# Script to download Logic App changes from the Azure Portal
# ------------------------------------------------------------------------------------------------------------------------
# This script is called from the Pipeline: './.azdo/pipelines/design-refresh-workflows-pipeline.yml'
# This script is designed to be run in a batch mode and just downloads and overwrites everything
# ------------------------------------------------------------------------------------------------------------------------
# Example Execution:
#   cd "<yourRootFolder>"
#   ./infra/scripts/download-portal-workflows.ps1 -resourceGroupName "rg-logappstd-demo" -logicAppName "lll-logic-app-std-demo"
# ------------------------------------------------------------------------------------------------------------------------

param (
  [string]$resourceGroupName="yourResourceGroupName",
  [string]$logicAppName= "yourLogicAppName"
)

Clear-Host
$baseTargetUri = "https://" + $logicAppName + ".scm.azurewebsites.net/api/vfs/site/wwwroot/"
$curDir = Get-Location
$baseOutputPath = $curDir.tostring()
$baseOutputPath = $baseOutputPath + "\src\Workflows\"

Write-Host "******** Download Logic App Definitions ********" -Foregroundcolor Green
Write-Host "Resource Group: $resourceGroupName" -Foregroundcolor Cyan
Write-Host "App Name: $logicAppName" -Foregroundcolor Cyan
Write-Host "Scanning app at $baseTargetUri ..." -Foregroundcolor Cyan
Write-Host "Saving files to $baseOutputPath ..." -Foregroundcolor Cyan

Write-Host ""
Write-Host "Getting deployment profile..." -Foregroundcolor Blue
$profiles = az webapp deployment list-publishing-profiles -g $resourceGroupName -n $logicAppName | Convertfrom-json
if ($profiles.Count -eq 0) {
    Write-Host "Error! No deployment profiles found for $logicAppName" -Foregroundcolor Red
    exit
}
# Create Base64 authorization header
$username = $profiles[0].userName
$password = $profiles[0].userPWD
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

Write-Host "Scanning $logicAppName ..." -Foregroundcolor Blue
Write-Host ""
# try running as SP - get token from pipeline variable, change auth header to "Bearer {0}"
$jsonObj = Invoke-RestMethod -Uri $baseTargetUri  -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } -Method GET -ContentType "application/json"
$jsonObj | Select-Object -Property Name, Mime | ForEach-Object {
    if ($_.mime -eq 'application/json') {
        $thisName = $_.name
        if ($thisName -eq "global.json" -or $thisName -eq "host.json") {
            Write-Host "Skipping $thisName ..." -Foregroundcolor Magenta
        }
        else {
            $outputName = $_.name
            $t = $baseTargetUri + $_.name
            if ($thisName -eq "connections.json" -or $thisName -eq "parameters.json") {
                $outputName = "azure.$outputName"
            } 
            $o = $baseOutputPath + $outputName
            Write-Host "Downloading Config: $thisName to $outputName ..." -Foregroundcolor Green
            Write-Host "  Writing to $o ..." -Foregroundcolor Green
            Invoke-WebRequest -Uri $t -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } -Method GET -OutFile $o -ContentType "multipart/form-data"
        }
    }

    if ($_.mime -eq 'inode/directory' -and $_.name -ne "workflow-designtime") {
        $thisName = $_.name
        $outputName = $_.name
        Write-Host "Downloading Workflow: $thisName ..." -Foregroundcolor Green
        $t = $baseTargetUri + $_.name + '/workflow.json'
        $o = $baseOutputPath + $_.name + '/workflow.json'
        $d = $baseOutputPath + $_.name
        Write-Host "  Writing to $o ..." -Foregroundcolor Green
        New-Item -ItemType Directory -Force -Path $d
        Invoke-WebRequest -Uri $t -Headers @{Authorization = ("Basic {0}" -f $base64AuthInfo) } -Method GET -OutFile $o -ContentType "multipart/form-data"
    }
}