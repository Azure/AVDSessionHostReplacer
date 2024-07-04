function Remove-SHRSessionHostAzureADDevice {
    <#
    .SYNOPSIS
        This is used to delete the VM object from Intune
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [String] $VMName
    )

    # Connect to Graph API
    Connect-SHRGraphAPI
    # Get device object
    
    #$device = Get-MgDevice -Filter "DisplayName eq '$VMName'"
    $IntuneDevice = Get-MgDeviceManagementManagedDevice -filter "deviceName eq '$VMName'"

    if($IntuneDevice){
        Write-PSFMessage -Level Host -Message "Retrieved Intune device object for VM {0} with Id: {1}" -StringValues $VMName, $IntuneDevice.Id
        # Delete VM
        #$null = Remove-MgDevice -DeviceId $device.Id -ErrorAction Stop
        $null = Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $IntuneDevice.id -ErrorAction Stop

        Write-PSFMessage -Level Host -Message "Deleted device object for VM {0} from Intune" -StringValues $VMName
    }
    else{
        Write-PSFMessage -Level Warning -Message "Could not find intune device object for VM {0}" -StringValues $VMName
    }
}