function Get-SHRRunningDeployment {
    <#
    .SYNOPSIS
        This function gets status of all AVD Session Host Replacer deployments in the target resource group.
    .DESCRIPTION
        The function will fail if there are any failed deployments. These should be cleaned up before automation can resume.
        This behavior is to avoid compounding issues due to failing deployments.
        Ideally, the AVD administrator should setup a notification (alert action) when there are failing deployments. # TODO: Add alert setup.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,

        [Parameter()]
        [string] $DeploymentPrefix = (Get-FunctionConfig _SHRDeploymentPrefix),

        [Parameter()]
        [string] $VMNamesTemplateParameterName = (Get-FunctionConfig _VMNamesTemplateParameterName)
    )

    Write-PSFMessage -Level Host -Message "Getting deployments for resource group {0}" -StringValues $ResourceGroupName
    $deployments = Get-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -ErrorAction Stop
    $deployments = $deployments | Where-Object { $_.DeploymentName -like "$DeploymentPrefix*" }
    Write-PSFMessage -Level Host -Message "Found {0} deployments marked with {1}." -StringValues $deployments.Count, $DeploymentPrefix

    # Check for failed deployments
    $failedDeployments = $deployments | Where-Object { $_.ProvisioningState -eq 'Failed' }
    # Terminate if there are any failed deployments
    if ($failedDeployments) {

        Write-PSFMessage -Level Error -Message "Found {0} failed deployments. These should be cleaned up before automation can resume." -StringValues $failedDeployments.Count -EnableException $true
        throw "Found {0} failed deployments. These should be cleaned up before automation can resume." -f $failedDeployments.Count
    }

    # Check for running deployments
    $runningDeployments = $deployments | Where-Object { $_.ProvisioningState -eq 'Running' }
    Write-PSFMessage -Level Host -Message "Found {0} running deployments." -StringValues $runningDeployments.Count

    # Check for long running deployments
    $warningThreshold = (Get-Date -AsUTC).AddHours(-2)
    $longRunningDeployments = $runningDeployments | Where-Object { $_.Timestamp -lt $warningThreshold }
    if ($longRunningDeployments) {
        Write-PSFMessage -Level Warning -Message "Found {0} deployments that have been running for more than 2 hours. This could block future deployments" -StringValues $longRunningDeployments.Count
    }

    # Parse deployment names to get VM name
    $output = foreach ($item in $runningDeployments) {
        $parameters = $item.Parameters | ConvertTo-CaseInsensitiveHashtable
        Write-PSFMessage -Level Host -Message "Deployment {0} is running and deploying: {1}" -StringValues $item.DeploymentName, ($parameters[$VMNamesTemplateParameterName].Value -join ",")
        [PSCustomObject]@{
            DeploymentName   = $item.DeploymentName
            SessionHostNames = $parameters[$VMNamesTemplateParameterName].Value
            Timestamp        = $item.Timestamp
            Status           = $item.ProvisioningState
        }
    }

    $output
}