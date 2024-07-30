function Remove-SHRSessionHostIntuneDevice {
    <#
    .SYNOPSIS
        This is used to delete the VM object from Intune
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [String] $VMName
    )

    # Get device object
    $device = Get-MgDeviceManagementManagedDevice -Filter "DeviceName eq '$VMName'"
    if($device){
        Write-PSFMessage -Level Host -Message "Retrieved device object for VM {0} with Id: {1}" -StringValues $VMName, ($device.Id -join ",")
        # Delete VM, deletes multiple entries if found in Intune
        $null = $device | ForEach-Object {Remove-MgDeviceManagementManagedDevice   -ManagedDeviceId $_.Id  -ErrorAction Stop}
        Write-PSFMessage -Level Host -Message "Deleted device object for VM {0} from Intune" -StringValues $VMName
    }
    else{
        Write-PSFMessage -Level Warning -Message "Could not find device object for VM {0}" -StringValues $VMName
    }
}