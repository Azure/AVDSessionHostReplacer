function Get-SHRHostPoolDecision {
    <#
    .SYNOPSIS
        This function will decide how many session hosts to deploy and if we should decommission any session hosts.
    #>
    [CmdletBinding()]
    param (
        # Session hosts to consider
        [Parameter()]
        [array] $SessionHosts = @(),

        # Running deployments
        [Parameter()]
        $RunningDeployments,

        # Target age of session hosts in days - after this many days we consider a session host for replacement.
        [Parameter()]
        [int] $TargetVMAgeDays = (Get-FunctionConfig _TargetVMAgeDays),

        # Target number of session hosts in the host pool. If we have more than or equal to this number of session hosts we will decommission some.
        [Parameter()]
        [int] $TargetSessionHostCount = (Get-FunctionConfig _TargetSessionHostCount),

        [Parameter()]
        [int] $TargetSessionHostBuffer = (Get-FunctionConfig _TargetSessionHostBuffer),

        # Latest image version
        [Parameter()]
        [PSCustomObject] $LatestImageVersion,

        # Should we replace session hosts on new image version
        [Parameter()]
        [bool] $ReplaceSessionHostOnNewImageVersion = (Get-FunctionConfig _ReplaceSessionHostOnNewImageVersion),

        # Delay days before replacing session hosts on new image version
        [Parameter()]
        [int] $ReplaceSessionHostOnNewImageVersionDelayDays = (Get-FunctionConfig _ReplaceSessionHostOnNewImageVersionDelayDays)
    )
    # Basic Info
    Write-PSFMessage -Level Host -Message "We have {0} session hosts (included in Automation)" -StringValues $SessionHosts.Count

    # Identify Session hosts that should be replaced
    if ($TargetVMAgeDays -gt 0) {
        $targetReplacementDate = (Get-Date).AddDays(-$TargetVMAgeDays)
        [array] $sessionHostsOldAge = $SessionHosts | Where-Object { $_.DeployTimestamp -lt $targetReplacementDate }
        Write-PSFMessage -Level Host -Message "Found {0} session hosts to replace due to old age. {1}" -StringValues $sessionHostsOldAge.Count, ($sessionHostsOldAge.VMName -join ',')

    }

    if ($ReplaceSessionHostOnNewImageVersion) {
        $latestImageAge = (New-TimeSpan -Start $LatestImageVersion.Date -End (Get-Date -AsUTC)).TotalDays
        Write-PSFMessage -Level Host -Message "Latest Image {0} is {1:N0} days old." -StringValues $LatestImageVersion.Version, $latestImageAge
        if ($latestImageAge -ge $ReplaceSessionHostOnNewImageVersionDelayDays) {
            Write-PSFMessage -Level Host -Message "Latest Image age is older than (or equal) New Image Delay value {0}" -StringValues $ReplaceSessionHostOnNewImageVersionDelayDays
            [array] $sessionHostsOldVersion = $sessionHosts | Where-Object { $_.ImageVersion -ne $LatestImageVersion.Version }
            Write-PSFMessage -Level Host -Message "Found {0} session hosts to replace due to new image version. {1}" -StringValues $sessionHostsOldVersion.Count, ($sessionHostsOldVersion.VMName -Join ',')
        }
    }

    [array] $sessionHostsToReplace = ($sessionHostsOldAge + $sessionHostsOldVersion) | Select-Object -Property * -Unique
    Write-PSFMessage -Level Host -Message "Found {0} session hosts to replace in total. {1}" -StringValues $sessionHostsToReplace.Count, ($sessionHostsToReplace.VMName -join ',')

    # Good Session Hosts

    $goodSessionHosts = $SessionHosts | Where-Object { $_.VMName -notin $sessionHostsToReplace.VMName }
    $sessionHostsCurrentTotal = ([array]$goodSessionHosts.VMName + [array]$runningDeployments.SessionHostNames ) | Select-Object -Unique

    Write-PSFMessage -Level Host -Message "We have {0} good session hosts including {1} session hosts being deployed" -StringValues $sessionHostsCurrentTotal.Count, $runningDeployments.SessionHostNames.Count
    Write-PSFMessage -Level Host -Message "We target having {0} session hosts in good shape" -StringValues $TargetSessionHostCount
    Write-PSFMessage -Level Host -Message "We have a buffer of {0} session hosts more than the target." -StringValues $TargetSessionHostBuffer

    $weCanDeployUpTo = $TargetSessionHostCount + $TargetSessionHostBuffer - $SessionHosts.count - $RunningDeployments.SessionHostNames.Count
    if ($weCanDeployUpTo -ge 0) {
        Write-PSFMessage -Level Host -Message "We can deploy up to {0} session hosts" -StringValues $weCanDeployUpTo

        $weNeedToDeploy = $TargetSessionHostCount - $sessionHostsCurrentTotal.Count
        if ($weNeedToDeploy -gt 0) {
            Write-PSFMessage -Level Host -Message "We need to deploy {0} new session hosts" -StringValues $weNeedToDeploy
            $weCanDeploy = if ($weNeedToDeploy -gt $weCanDeployUpTo) { $weCanDeployUpTo } else { $weNeedToDeploy } # If we need to deploy 10 machines, and we can deploy 5, we should only deploy 5.
            Write-PSFMessage -Level Host -Message "Buffer allows deploying {0} session hosts" -StringValues $weCanDeploy
        }
        else {
            $weCanDeploy = 0
            Write-PSFMessage -Level Host -Message "We have enough session hosts in good shape."
        }
    }
    else {
        Write-PSFMessage -Level Host -Message "Buffer is full. We can not deploy more session hosts"
        $weCanDeploy = 0
    }


    $weCanDelete = $SessionHosts.Count - $TargetSessionHostCount
    if ($weCanDelete -gt 0) {
        Write-PSFMessage -Level Host -Message "We need to delete {0} session hosts" -StringValues $weCanDelete
        if ($weCanDelete -gt $sessionHostsToReplace.Count) {
            Write-PSFMessage -Level Host -Message "Host pool is over populated"

            $goodSessionHostsToDeleteCount = $weCanDelete - $sessionHostsToReplace.Count
            Write-PSFMessage -Level Host -Message "We will delete {0} good session hosts" -StringValues $goodSessionHostsToDeleteCount

            $selectedGoodHostsTotDelete = [array] ($goodSessionHosts | Sort-Object -Property Session | Select-Object -First $goodSessionHostsToDeleteCount)
            Write-PSFMessage -Level Host -Message "Selected the following good session hosts to delete: {0}" -StringValues ($selectedGoodHostsTotDelete.VMName -join ',')
        }
        else {
            $selectedGoodHostsTotDelete = @()
            Write-PSFMessage -Level Host -Message "Host pool is not over populated"
        }

        $sessionHostsPendingDelete = ($sessionHostsToReplace + $selectedGoodHostsTotDelete) | Select-Object -First $weCanDelete
        Write-PSFMessage -Level Host -Message "The following Session Hosts are now pending delete: {0}" -StringValues ($SessionHostsPendingDelete.VMName -join ',')

    }
    elseif ($sessionHostsToReplace.Count -gt 0) {
        Write-PSFMessage -Level Host -Message "We need to delete {0} session hosts but we don't have enough session hosts in the host pool." -StringValues ($sessionHostsToReplace.Count)
    }
    else { Write-PSFMessage -Level Host -Message "We do not need to delete any session hosts" }


    [PSCustomObject]@{
        PossibleDeploymentsCount       = $weCanDeploy
        PossibleSessionHostDeleteCount = $weCanDelete
        SessionHostsPendingDelete      = $sessionHostsPendingDelete
        ExistingSessionHostVMNames     = ([array]$SessionHosts.VMName + [array]$runningDeployments.SessionHostNames) | Select-Object -Unique
    }
}