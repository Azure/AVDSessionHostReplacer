function Deploy-SHRSessionHost {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]] $ExistingSessionHostVMNames = @(),

        [Parameter(Mandatory = $true)]
        [int] $NewSessionHostsCount,

        [Parameter(Mandatory = $false)]
        [string] $HostPoolResourceGroupName = (Get-FunctionConfig _HostPoolResourceGroupName),

        [Parameter(Mandatory = $true)]
        [string] $SessionHostResourceGroupName,

        [Parameter()]
        [string] $HostPoolName = (Get-FunctionConfig _HostPoolName),

        [Parameter()]
        [string] $SessionHostNamePrefix = (Get-FunctionConfig _SessionHostNamePrefix),

        [Parameter()]
        [int] $SessionHostInstanceNumberPadding = (Get-FunctionConfig _SessionHostInstanceNumberPadding),

        [Parameter()]
        [string] $DeploymentPrefix = (Get-FunctionConfig _SHRDeploymentPrefix),

        [Parameter()]
        [string] $SessionHostTemplate = (Get-FunctionConfig _SessionHostTemplate),

        [Parameter()]
        [string] $SessionHostTemplateParametersPS1Uri = (Get-FunctionConfig _SessionHostTemplateParametersPS1Uri),

        [Parameter()]
        [string] $TagIncludeInAutomation = (Get-FunctionConfig _Tag_IncludeInAutomation),
        [Parameter()]
        [string] $TagDeployTimestamp = (Get-FunctionConfig _Tag_DeployTimestamp),

        [Parameter()]
        [hashtable] $SessionHostParameters = (Get-FunctionConfig _SessionHostParameters | ConvertTo-CaseInsensitiveHashtable), #TODO: Port this into AzureFunctionConfiguration module and make it ciHashtable type.

        [Parameter()]
        [string] $VMNamesTemplateParameterName = (Get-FunctionConfig _VMNamesTemplateParameterName)
    )
    Write-PSFMessage -Level Host -Message "Generating new token for the host pool {0} in Resource Group {1}" -StringValues $HostPoolName, $HostPoolResourceGroupName
    $hostPoolToken = New-AzWvdRegistrationInfo -ResourceGroupName $HostPoolResourceGroupName -HostPoolName $HostPoolName -ExpirationTime (Get-Date).AddHours(2) -ErrorAction Stop

    # Calculate Session Host Names
    Write-PSFMessage -Level Host -Message "Existing session host VM names: {0}" -StringValues ($ExistingSessionHostVMNames -join ',')
    [array] $sessionHostNames = for ($i = 0; $i -lt $NewSessionHostsCount; $i++) {
        $vmNumber = 1
        While (("$SessionHostNamePrefix-{0:d$SessionHostInstanceNumberPadding}" -f $vmNumber) -in $ExistingSessionHostVMNames) {
            $vmNumber++
        }
        $vmName = "$SessionHostNamePrefix-{0:d$SessionHostInstanceNumberPadding}" -f $vmNumber
        $ExistingSessionHostVMNames += $vmName
        $vmName
    }
    Write-PSFMessage -Level Host -Message "Creating session host(s) {0}" -StringValues ($sessionHostNames -join ',')

    # Update Session Host Parameters
    $sessionHostParameters[$VMNamesTemplateParameterName]   = $sessionHostNames
    $sessionHostParameters['HostPoolName']                  = $HostPoolName
    $sessionHostParameters['HostPoolToken']                 = $hostPoolToken.Token
    $sessionHostParameters['Tags'][$TagIncludeInAutomation] = $true
    $sessionHostParameters['Tags'][$TagDeployTimestamp]     = (Get-Date -AsUTC -Format 'o')

    $deploymentTimestamp = Get-Date -AsUTC -Format 'FileDateTime'
    $deploymentName = "{0}_{1}_Count_{2}_VMs" -f $DeploymentPrefix, $deploymentTimestamp, $sessionHostNames.count
    Write-PSFMessage -Level Host -Message "Deployment name: {0}" -StringValues $deploymentName
    $paramNewAzResourceGroupDeployment = @{
        Name                    = $deploymentName
        ResourceGroupName       = $sessionHostResourceGroupName
        TemplateParameterObject = $sessionHostParameters
    }

    # Check if using URI or Template Spec
    if ($SessionHostTemplate -like "http*") {
        #Using URIs
        Write-PSFMessage -Level Host -Message 'Deploying using URI: {0}' -StringValues $sessionHostTemplate
        $paramNewAzResourceGroupDeployment['TemplateUri'] = $SessionHostTemplate
    }
    else {
        #Using Template Spec
        Write-PSFMessage -Level Host -Message 'Deploying using Template Spec: {0}' -StringValues $sessionHostTemplate
        $templateSpecVersionResourceId = Get-SHRTemplateSpecVersionResourceId -ResourceId $SessionHostTemplate
        $paramNewAzResourceGroupDeployment['TemplateSpecId'] = $templateSpecVersionResourceId
    }

    Write-PSFMessage -Level Host -Message 'Deploying {0} session host(s) to resource group {1}' -StringValues  $NewSessionHostsCount,$sessionHostResourceGroupName
    $deploymentJob = New-AzResourceGroupDeployment @paramNewAzResourceGroupDeployment -ErrorAction Stop -AsJob

    #TODO: Add logic to test if deployment is running (aka template is accepted) then finish running the function and let the deployment run in the background.
    Write-PSFMessage -Level Host -Message 'Pausing for 30 seconds to allow deployment to start'
    Start-Sleep -Seconds 30

    # Check deployment status, if any has failed we report an error
    if ($deploymentJob.Error) {
        Write-PSFMessage -Level Error "DeploymentFailed" -EnableException $true
        throw $deploymentJob.Error
    }
}