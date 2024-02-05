function Get-SHRHostPoolDecision {
    <#
    .SYNOPSIS
        This function will decide how many session hosts to deploy and if we should decommission any session hosts.
    #>
    [CmdletBinding()]
    param (
        # Session hosts to consider
        [Parameter()]
        $SessionHosts =@(),

        # Running deployments
        [Parameter()]
        $RunningDeployments,

        # Target age of session hosts in days - after this many days we consider a session host for replacement.
        [Parameter()]
        [int] $TargetVMAgeDays = (Get-FunctionConfig _TargetVMAgeDays),

        # Target number of session hosts in the host pool. If we have more than or equal to this number of session hosts we will decommission some.
        [Parameter()]
        [int] $TargetSessionHostCount = (Get-FunctionConfig _TargetSessionHostCount),

        # Max number of session hosts to deploy at the same time
        [Parameter()]
        [int] $MaxSimultaneousDeployments = (Get-FunctionConfig _MaxSimultaneousDeployments),

        # Latest image version
        [Parameter()]
        [PSCustomObject] $LatestImageVersion,

        # Should we replace session hosts on new image version
        [Parameter()]
        [bool] $ReplaceSessionHostOnNewImageVersion = (Get-FunctionConfig _ReplaceSessionHostOnNewImageVersion),

        # Delay days before replacing session hosts on new image version
        [Parameter()]
        [int] $ReplaceSessionHostOnNewImageVersionDelayDays = (Get-FunctionConfig _ReplaceSessionHostOnNewImageVersionDelayDays),

        # Allow downsizing of session hosts if we exceed target session host count.
        [Parameter()]
        [bool] $AllowDownsizing = [bool](Get-FunctionConfig _AllowDownsizing)
    )

    # Identify Session hosts that should be replaced
    if($TargetVMAgeDays -gt 0){
        $targetReplacementDate = (Get-Date).AddDays(-$TargetVMAgeDays)
        [array] $sessionHostsOldAge = $SessionHosts | Where-Object {$_.DeployTimestamp -lt $targetReplacementDate}
        Write-PSFMessage -Level Host -Message "Found {0} session hosts to replace due to old age: {1}" -StringValues $sessionHostsOldAge.Count,($sessionHostsOldAge.VMName -join ',')

    }

    if($ReplaceSessionHostOnNewImageVersion){
        $latestImageAge =  (New-TimeSpan -Start $LatestImageVersion.Date -End (Get-Date -AsUTC)).TotalDays
        Write-PSFMessage -Level Host -Message "Latest Image {0} is {1:N0} days old." -StringValues $LatestImageVersion.Version,$latestImageAge
        if($latestImageAge -ge $ReplaceSessionHostOnNewImageVersionDelayDays){
            Write-PSFMessage -Level Host -Message "Latest Image age is bigger than (or equal) New Image Delay value {0}" -StringValues $ReplaceSessionHostOnNewImageVersionDelayDays
            [array] $sessionHostsOldVersion = $sessionHosts | Where-Object {$_.ImageVersion -ne $LatestImageVersion.Version}
            Write-PSFMessage -Level Host -Message "Found {0} session hosts to replace due to new image version {1}" -StringValues $sessionHostsOldVersion.Count,($sessionHostsOldVersion.VMName -Join ',')
        }
    }

    $sessionHostsToReplace = ($sessionHostsOldAge + $sessionHostsOldVersion) | Select-Object -Property * -Unique
    Write-PSFMessage -Level Host -Message "Found {0} session hosts to replace in total. {1}" -StringValues $sessionHostsToReplace.Count,($sessionHostsToReplace.VMName -join ',')

    # Do some math
    Write-PSFMessage -Level Host -Message "We have {0} session hosts (included in Automation)" -StringValues $SessionHosts.Count
    Write-PSFMessage -Level Host -Message "We have {0} session hosts that needs to be replaced" -StringValues $sessionHostsToReplace.Count

    $sessionHostsToKeep = $SessionHosts | Where-Object { $_.VMName -notin $sessionHostsToReplace.VMName }
    $sessionHostsCurrentTotal = ([array]$sessionHostsToKeep.VMName + [array]$runningDeployments.SessionHostNames ) | Select-Object -Unique

    Write-PSFMessage -Level Host -Message "We have {0} good session hosts including {1} session hosts being deployed" -StringValues $sessionHostsCurrentTotal.Count, $runningDeployments.SessionHostNames.Count
    Write-PSFMessage -Level Host -Message "We target having {0} session hosts in in good shape" -StringValues $TargetSessionHostCount

    $sessionHostsToDeployCount = $TargetSessionHostCount - $sessionHostsCurrentTotal.Count

    if ($sessionHostsToDeployCount -gt 0) {
        Write-PSFMessage -Level Host -Message "We need to deploy {0} session hosts" -StringValues $sessionHostsToDeployCount
        Write-PSFMessage -Level Host -Message "Maximum number of simultaneous deployment allowed is {0}" -StringValues $MaxSimultaneousDeployments
        $possibleDeploymentsCount = [int]$MaxSimultaneousDeployments - $runningDeployments.SessionHostNames.Count
        if ($possibleDeploymentsCount -gt $sessionHostsToDeployCount) {
            $possibleDeploymentsCount = $sessionHostsToDeployCount
        }
        Write-PSFMessage -Level Host -Message "We can start deployment of {0} session hosts" -StringValues $possibleDeploymentsCount
    }
    elseif($sessionHostsToDeployCount -lt 0 -and $AllowDownsizing){
        Write-PSFMessage -Level Host -Message "We have too many session hosts. We need to decommission {0} session hosts" -StringValues $sessionHostsToDeployCount
        #Sorting by lowest number of sessions and descending vm name
        $sessionHostsToReplace = $sessionHostsToKeep | Sort-Object -Property Session,VMName -Descending | Select-Object -First (-$sessionHostsToDeployCount)
        Write-PSFMessage -Level Host -Message "We need to {0} extra session hosts: {1}" -StringValues $sessionHostsToReplace.Count,($sessionHostsToReplace.VMName -join ',')
    }
    else{
        Write-PSFMessage -Level Host -Message "We have enough session hosts in good shape."
    }

    # Decide if we should delete decommission session hosts if we have enough good ones in the pool
    if(($sessionHostsCurrentTotal.Count - $RunningDeployments.SessionHostNames.Count) -ge $TargetSessionHostCount){
        Write-PSFMessage -Level Host -Message "Current state allows deletion of old or extra session hosts."
        $allowSessionHostDelete = $true
    }
    else{
        Write-PSFMessage -Level Host -Message "Current state does NOT allow deletion of old session hosts."
        $allowSessionHostDelete = $false
    }

    [PSCustomObject]@{
        PossibleDeploymentsCount = $possibleDeploymentsCount
        AllowSessionHostDelete = $allowSessionHostDelete
        SessionHostsPendingDelete = $sessionHostsToReplace
        ExistingSessionHostVMNames = ([array]$SessionHosts.VMName + [array]$runningDeployments.SessionHostNames) | Select-Object -Unique
    }
}