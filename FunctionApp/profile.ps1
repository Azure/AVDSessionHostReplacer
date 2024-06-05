# Azure Functions profile.ps1
#
# This profile.ps1 will get executed every "cold start" of your Function App.
# "cold start" occurs when:
#
# * A Function App starts up for the very first time
# * A Function App starts up after being de-allocated due to inactivity
#
# You can define helper functions, run commands, or specify environment variables
# NOTE: any variables defined that are not environment variables will get reset after the first execution

Import-Module 'PSFrameWork' ,'Az.Resources' ,'Az.Compute' ,'Az.DesktopVirtualization', 'SessionHostReplacer', 'AzureFunctionConfiguration' -ErrorAction Stop

# Configure PSFramework settings
Set-PSFConfig -FullName PSFramework.Message.style.NoColor -Value $true #This is required for logs to look good in FunctionApp Logs

## Version Banner ## Updated by Build\Build-Zip-File.ps1

Write-PSFMessage -Level Host -Message "This is SessionHostReplacer version {0}" -StringValues 'v0.2.6-beta.16'


# Import Function Parameters
try{
    Import-FunctionConfig -FunctionParametersFilePath '.\FunctionParameters.psd1' -ErrorAction Stop
}
catch{
    Write-PSFMessage -Level Error -Message "Failed to import Function Parameters. Error: {0}" -StringValues $_.Exception.Message
    throw $_
}

# Authenticate with Azure PowerShell using MSI or user identity.

if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    if([string]::IsNullOrEmpty($env:_ClientId)){
        Write-PSFMessage -Level Host -Message "Authenticating with system assigned identity"
        Connect-AzAccount -Identity -SubscriptionId (Get-FunctionConfig _SubscriptionId)
        if(Get-FunctionConfig _RemoveAzureADDevice){
            Write-PSFMessage -Level Host -Message "Connecting to Graph API"
            Connect-MGGraph -Identity
        }
    }
    else{
        Write-PSFMessage -Level Host -Message "Authenticating with user assigned identity - {0}" -StringValues $env:_ClientId
        Connect-AzAccount -Identity -SubscriptionId (Get-FunctionConfig _SubscriptionId) -AccountId $env:_ClientId
        if(Get-FunctionConfig _RemoveAzureADDevice){
            Write-PSFMessage -Level Host -Message "Connecting to Graph API"
            Connect-MGGraph -Identity -ClientId $env:_ClientId
        }
    }
}
else{
    # This is for testing locally
    Set-AzContext -SubscriptionId (Get-FunctionConfig _SubscriptionId)
}
$ErrorActionPreference = 'Stop'
