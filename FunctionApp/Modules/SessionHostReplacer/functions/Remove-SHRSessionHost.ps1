function Remove-SHRSessionHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $SessionHostsPendingDelete,

        [Parameter()]
        [string] $ResourceGroupName = (Get-FunctionConfig _HostPoolResourceGroupName),

        [Parameter()]
        [string] $HostPoolName = (Get-FunctionConfig _HostPoolName),

        [Parameter()]
        [int] $DrainGracePeriodHours = (Get-FunctionConfig _DrainGracePeriodHours),

        [Parameter()]
        [string] $TagPendingDrainTimeStamp = (Get-FunctionConfig _Tag_PendingDrainTimestamp),

        [Parameter()]
        [string] $TagScalingPlanExclusionTag = (Get-FunctionConfig _Tag_ScalingPlanExclusionTag),

        [Parameter()]
        [bool] $RemoveAzureDevice
    )

    foreach ($sessionHost in $SessionHostsPendingDelete) {
        # Does the session host currently have sessions?
        # No sessions => Delete + Remove from host pool
        # Is the session host in drain mode?
        # Yes => Is the drain grace period tag old? => Delete + Remove from host pool
        # NO => Set drain mode + Message users + Set tag

        $drainSessionHost = $false
        $deleteSessionHost = $false

        if ($sessionHost.Session -eq 0) {
            #Does the session host currently have sessions?
            # No sessions => Delete + Remove from host pool
            Write-PSFMessage -Level Host -Message 'Session host {0} has no sessions.' -StringValues $sessionHost.FQDN
            $deleteSessionHost = $true
        }
        else {
            Write-PSFMessage -Level Host -Message 'Session host {0} has {1} sessions.' -StringValues $sessionHost.FQDN, $sessionHost.Session
            if (-Not $sessionHost.AllowNewSession) {
                # Is the session host in drain mode?
                Write-PSFMessage -Level Host -Message 'Session host {0} is in drain mode.' -StringValues $sessionHost.FQDN

                if ($sessionHost.PendingDrainTimeStamp) {
                    #Session host has a drain timestamp
                    Write-PSFMessage -Level Host -Message 'Session Host {0} drain timestamp is {1}' -StringValues $sessionHost.FQDN, $sessionHost.PendingDrainTimeStamp
                    $maxDrainGracePeriodDate = $sessionHost.PendingDrainTimeStamp.AddHours($DrainGracePeriodHours)
                    Write-PSFMessage -Level Host -Message 'Session Host {0} can stay in grace period until {1}' -StringValues $sessionHost.FQDN, $maxDrainGracePeriodDate.ToUniversalTime().ToString('o')
                    if ($maxDrainGracePeriodDate -lt (Get-Date)) {
                        Write-PSFMessage -Level Host -Message 'Session Host {0} has exceeded the drain grace period.' -StringValues $sessionHost.FQDN
                        $deleteSessionHost = $true
                    }
                    else {
                        Write-PSFMessage -Level Host -Message 'Session Host {0} has not exceeded the drain grace period.' -StringValues $sessionHost.FQDN
                    }
                }
                else {
                    Write-PSFMessage -Level Host -Message 'Session Host {0} does not have a drain timestamp.' -StringValues $sessionHost.FQDN
                    $drainSessionHost = $true
                }
            }
            else {
                Write-PSFMessage -Level Host -Message 'Session host {0} in not in drain mode. Turning on drain mode.' -StringValues $sessionHost.Name
                $drainSessionHost = $true
            }
        }

        if ($drainSessionHost) {
            Write-PSFMessage -Level Host -Message 'Turning on drain mode.'
            Update-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $sessionHost.FQDN -AllowNewSession:$false -ErrorAction Stop

            $drainTimestamp = (Get-Date).ToUniversalTime().ToString('o')
            Write-PSFMessage -Level Host -Message 'Setting drain timestamp on tag {0} to {1}.' -StringValues $TagPendingDrainTimeStamp, $drainTimestamp
            $null = Update-AzTag -ResourceId $sessionHost.ResourceId -Tag @{$TagPendingDrainTimeStamp = $drainTimestamp } -Operation Merge

            if ($TagScalingPlanExclusionTag -ne ' ') {
                # This is string with a single space.
                Write-PSFMessage -Level Host -Message 'Setting scaling plan exclusion tag {0} to {1}.' -StringValues $TagScalingPlanExclusionTag, $true
                $null = Update-AzTag -ResourceId $sessionHost.ResourceId -Tag @{$TagScalingPlanExclusionTag = $true } -Operation Merge
            }

            Write-PSFMessage -Level Host -Message 'Notifying Users'
            Send-SHRDrainNotification -SessionHostName ($sessionHost.FQDN)
        }

        if ($deleteSessionHost) {
            Write-PSFMessage -Level Host -Message 'Deleting session host {0}...' -StringValues $sessionHost.Name

            if ($RemoveAzureDevice) {
                Write-PSFMessage -Level Host -Message 'Deleting device from Azure AD and Intune'
                Remove-SHRSessionHostAzureADDevice -VMName $sessionHost.VMName
                #Write-PSFMessage -Level Host -Message 'Deleting device from Intune'
                #Remove-SHRSessionHostIntuneDevice -VMName $sessionHost.VMName 
                # TODO: Dedicated function. Removed due to Connect-SHRGraphAPI testing issues. 
                # Integrated into Remove-SHRSessionHostAzureADDevice.ps1 for now.
            }

            Write-PSFMessage -Level Host -Message 'Removing Session Host from Host Pool {0}' -StringValues $HostPoolName
            Remove-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $sessionHost.FQDN -Force -ErrorAction Stop

            Write-PSFMessage -Level Host -Message "Deleting VM: {0}..." -StringValues $sessionHost.ResourceId
            $null = Remove-AzVM -Id $sessionHost.ResourceId -ForceDeletion $true -Force -NoWait -ErrorAction Stop
            # We are not deleting Disk and NIC as the template should mark the delete option for these resources.
        }
    }
}