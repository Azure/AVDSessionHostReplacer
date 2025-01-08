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

Import-Module 'PSFrameWork' , 'Az.Resources' , 'Az.Compute' , 'Az.DesktopVirtualization', 'SessionHostReplacer', 'AzureFunctionConfiguration' -ErrorAction Stop

# Configure PSFramework settings
Set-PSFConfig -FullName PSFramework.Message.style.NoColor -Value $true #This is required for logs to look good in FunctionApp Logs

## Version Banner ## Updated by Build\Build-Zip-File.ps1

# This value is automatically maintanted using GitHub Actions.
Write-PSFMessage -Level Host -Message "This is SessionHostReplacer version {0}" -StringValues 'v0.3.3'

# Import Function Parameters
try {
    Import-FunctionConfig -FunctionParametersFilePath '.\FunctionParameters.psd1' -ErrorAction Stop
}
catch {
    Write-PSFMessage -Level Error -Message "Failed to import Function Parameters. Error: {0}" -StringValues $_.Exception.Message
    throw $_
}

# Authenticate with Azure PowerShell using MSI or user identity.

if ($env:MSI_SECRET) {
    Disable-AzContextAutosave -Scope Process | Out-Null
    if ([string]::IsNullOrEmpty( (Get-FunctionConfig _ClientId) ) ) {
        Write-PSFMessage -Level Host -Message "Authenticating with system assigned identity"
        Connect-AzAccount -Identity -SubscriptionId (Get-FunctionConfig _SubscriptionId) -ErrorAction Stop
        if (Get-FunctionConfig _RemoveEntraDevice) {
            Write-PSFMessage -Level Host -Message "Connecting to Graph API"
            Connect-MgGraph -Identity
        }
    }
    else {
        Write-PSFMessage -Level Host -Message "Connecting to Azure using User Managed Identity with Client ID: {0}" -StringValues (Get-FunctionConfig _ClientId)

        Connect-AzAccount -Identity -ErrorAction Stop -AccountId (Get-FunctionConfig _ClientId) -Tenant (Get-FunctionConfig _TenantId) -Subscription (Get-FunctionConfig _SubscriptionId) -Environment (Get-FunctionConfig _AzureEnvironmentName)

        if ((Get-FunctionConfig _RemoveEntraDevice) -or (Get-FunctionConfig _RemoveIntuneDevice) ) {
            Write-PSFMessage -Level Host -Message "Configured to remove devices from Entra ID and/or Intune. Connecting to Graph API using User Managed Identity with Client ID: {0}" -StringValues (Get-FunctionConfig _ClientId)
            Connect-MgGraph -Identity -ClientId (Get-FunctionConfig _ClientId) -ErrorAction Stop -NoWelcome -Environment (Get-FunctionConfig _GraphEnvironmentName)
        }
    }
}
else {
    # This is for testing locally
    Write-PSFMessage "MSI_Secret environment variable not found. This should only happen when testing locally. Otherwise confirm that a System or User Managed Identity is defined."
    Set-AzContext -SubscriptionId (Get-FunctionConfig _SubscriptionId)
}
$ErrorActionPreference = 'Stop'
