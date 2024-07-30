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

Import-Module 'PSFrameWork' ,'Az.Resources' ,'Az.Compute' ,'Az.DesktopVirtualization', 'SessionHostReplacer', 'AzureFunctionConfiguration' -ErrorAction 'Stop'

# Configure PSFramework settings
Set-PSFConfig -FullName PSFramework.Message.style.NoColor -Value $true #This is required for logs to look good in FunctionApp Logs

## Version Banner ## Updated by Build\Build-Zip-File.ps1

Write-PSFMessage -Level Host -Message "This is SessionHostReplacer version {0}" -StringValues 'v0.2.7'


# Import Function Parameters
try{
    Import-FunctionConfig -FunctionParametersFilePath '.\FunctionParameters.psd1' -ErrorAction 'Stop'
}
catch{
    Write-PSFMessage -Level Error -Message "Failed to import Function Parameters. Error: {0}" -StringValues $_.Exception.Message
    throw $_
}

# Authenticate with Azure PowerShell using MSI or user identity.

if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    if([string]::IsNullOrEmpty($env:_ClientResourceId)){
        Write-PSFMessage -Level Host -Message "Authenticating with system assigned identity"
        Connect-AzAccount -Environment $env:_EnvironmentName -Tenant $env:_TenantId -SubscriptionId (Get-FunctionConfig _SubscriptionId) -Identity -ErrorAction 'Stop'
        if(Get-FunctionConfig _RemoveAzureADDevice){
            Write-PSFMessage -Level Host -Message "Connecting to Graph API"
            Connect-MGGraph -Identity
        }
    }
    else{
        Write-PSFMessage -Level Host -Message "Connecting to Azure using User Managed Identity with Resource ID: $env:_ClientResourceId"

        $entraAzureConnection = Connect-EntraService -Identity -IdentityType 'ResourceID' -IdentityID $env:_ClientResourceId -Service 'Azure' -PassThru
        Connect-AzAccount -Environment $env:_EnvironmentName -Tenant $env:_TenantId -Subscription (Get-FunctionConfig _SubscriptionId) -AccountId $env:_ClientResourceId -AccessToken $entraAzureConnection.AccessToken -ErrorAction 'Stop'


        if(Get-FunctionConfig _RemoveAzureADDevice){
            Write-PSFMessage -Level Host -Message "Configured to remove devices from Entra ID. Connecting to Graph API using User Managed Identity with Resource ID: $env:_ClientResourceId"
            $entraGraphConnection = Connect-EntraService -Identity -IdentityType 'ResourceID' -IdentityID $env:_ClientResourceId -Service 'Graph' -PassThru
            Connect-MGGraph -AccessToken (ConvertTo-SecureString $entraGraphConnection.AccessToken -AsPlainText -Force) -ErrorAction 'Stop'
        }
    }
}
else{
    # This is for testing locally
    Write-PSFMessage "MSI_Secret environment variable not found. This should only happen when testing locally. Otherwise confirm that a System or User Managed Identity is defined."
    Set-AzContext -SubscriptionId (Get-FunctionConfig _SubscriptionId)
}
$ErrorActionPreference = 'Stop'
