function Get-SHRSessionHost {
    <#
.SYNOPSIS
    This function gets Session Host details from a host pool.
.DESCRIPTION
    A longer description of the function, its purpose, common use cases, etc.
.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
.LINK
    Specify a URI to a help page, this will show when Get-Help -Online is used.
.EXAMPLE
    Test-MyTestFunction -Verbose
    Explanation of the function or its result. You can include multiple examples with additional .EXAMPLE lines
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $ResourceGroupName = (Get-FunctionConfig _HostPoolResourceGroupName),
        [Parameter()]
        [string] $HostPoolName = (Get-FunctionConfig _HostPoolName),
        [Parameter()]
        [string] $TagIncludeInAutomation = (Get-FunctionConfig _Tag_IncludeInAutomation),
        [Parameter()]
        [string] $TagDeployTimestamp = (Get-FunctionConfig _Tag_DeployTimestamp),
        [Parameter()]
        [string] $TagPendingDrainTimeStamp = (Get-FunctionConfig _Tag_PendingDrainTimestamp),


        [Parameter()]
        [switch] $FixSessionHostTags

    )

    # Get current session hosts
    Write-PSFMessage -Level Host -Message 'Getting current session hosts in host pool {0}' -StringValues $HostPoolName
    $sessionHosts = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ErrorAction Stop | Select-Object Name, ResourceId, Session, AllowNewSession, Status
    Write-PSFMessage -Level Host -Message 'Found {0} session hosts' -StringValues $sessionHosts.Count

    # For each session host, get the VM details
    $result = foreach ($item in $sessionHosts) {
        Write-PSFMessage -Level Host -Message 'Getting VM details for {0}' -StringValues $item.Name

        $vm = Get-AzVM -ResourceId $item.ResourceId | Select-Object Name, TimeCreated,StorageProfile
        Write-PSFMessage -Level Host -Message 'VM was created on {0}' -StringValues $vm.TimeCreated
        Write-PSFMessage -Level Host -Message 'VM exact version is {0}' -StringValues $vm.StorageProfile.ImageReference.ExactVersion

        Write-PSFMessage -Level Host -Message 'Getting VM tags' -StringValues $item.Name
        $vmTags = Get-AzTag -ResourceId $item.ResourceId
        #region: Tag DeployTimestamp
        $vmDeployTimeStamp = $vmTags.Properties.TagsProperty[$TagDeployTimestamp]
        try {
            $vmDeployTimeStamp = [DateTime]::Parse($vmDeployTimeStamp)
            Write-PSFMessage -Level Host -Message 'VM has a tag {0} with value {1}' -StringValues $TagDeployTimestamp, $vmDeployTimeStamp
        }
        catch {
            $value = if ($null -eq $vmDeployTimeStamp) { 'null' } else { $vmDeployTimeStamp }
            Write-PSFMessage -Level Host -Message 'VM tag {0} with value {1} is not a valid date' -StringValues $TagDeployTimestamp, $value
            if ($FixSessionHostTags) {
                Write-PSFMessage -Level Host -Message 'Copying VM CreateTime to tag {0} with value {1}' -StringValues $TagDeployTimestamp, $vm.TimeCreated.ToString('o')
                Update-AzTag -ResourceId $item.ResourceId -Tag @{ $TagDeployTimestamp = $vm.TimeCreated.ToString('o') } -Operation Merge
            }
            $vmDeployTimeStamp = $vm.TimeCreated
        }
        #endregion: Tag DeployTimestamp

        #region: Tag IncludeInAutomation
        $vmIncludeInAutomation = $vmTags.Properties.TagsProperty[$TagIncludeInAutomation]
        if ($vmIncludeInAutomation -eq "True") {
            Write-PSFMessage -Level Host -Message 'VM has a tag {0} with value {1}' -StringValues $TagIncludeInAutomation, $vmIncludeInAutomation
            $vmIncludeInAutomation = $true
        }
        elseif ($vmIncludeInAutomation -eq "False") {
            Write-PSFMessage -Level Host -Message 'VM has a tag {0} with value {1}' -StringValues $TagIncludeInAutomation, $vmIncludeInAutomation
            $vmIncludeInAutomation = $false
        }
        else {
            $value = if ($null -eq $vmIncludeInAutomation) { 'null' } else { $vmIncludeInAutomation }
            Write-PSFMessage -Level Host -Message 'VM tag {0} with value {1} is not set to True/False' -StringValues $TagIncludeInAutomation, $value
            if ($FixSessionHostTags) {
                Write-PSFMessage -Level Host -Message 'Setting tag {0} to False' -StringValues $TagIncludeInAutomation
                Update-AzTag -ResourceId $item.ResourceId -Tag @{ $TagIncludeInAutomation = 'False' } -Operation Merge
            }

            $vmIncludeInAutomation = $false
        }
        #endregion: Tag IncludeInAutomation

        #region: Tag PendingDrainTimeStamp
        $vmPendingDrainTimeStamp = $vmTags.Properties.TagsProperty[$TagPendingDrainTimeStamp]
        try {
            $vmPendingDrainTimeStamp = [DateTime]::Parse($vmPendingDrainTimeStamp)
            Write-PSFMessage -Level Host -Message 'VM has a tag {0} with value {1}' -StringValues $TagPendingDrainTimeStamp, $vmPendingDrainTimeStamp
        }
        catch {
            Write-PSFMessage -Level Host -Message "VM tag {0} is not set." -StringValues $TagPendingDrainTimeStamp
            $vmPendingDrainTimeStamp = $null
        }

        #endregion: Tag PendingDrainTimeStamp

        $vmOutput = @{ # We are combining the VM details and SessionHost objects into a single PS Custom Object
            VMName                = $vm.Name
            FQDN                  = $item.Name -replace ".+\/(.+)", '$1'
            DeployTimestamp       = $vmDeployTimeStamp
            IncludeInAutomation   = $vmIncludeInAutomation
            PendingDrainTimeStamp = $vmPendingDrainTimeStamp
            ImageVersion          = $vm.StorageProfile.ImageReference.ExactVersion
        }
        $item.PSObject.Properties.ForEach{ $vmOutput[$_.Name] = $_.Value }

        [PSCustomObject]$vmOutput

    }

    $result
}