function Remove-SHRSessionHostAzureADDevice {
    <#
    .SYNOPSIS
        This is used to delete the VM object from Azure AD
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [String] $VMName
    )

    # Connect to Graph API
    Connect-SHRGraphAPI
    # Get device object
    $device = Get-MgDevice -Filter "DisplayName eq '$VMName'"
    if($device){
        Write-PSFMessage -Level Host -Message "Retrieved device object for VM {0} with Id: {1}" -StringValues $VMName, $device.Id
        # Delete VM
        Remove-MgDevice -DeviceId $device.Id
        Write-PSFMessage -Level Host -Message "Deleted device object for VM {0} from Azure AD" -StringValues $VMName
    }
    else{
        Write-PSFMessage -Level Warning -Message "Could not find device object for VM {0}" -StringValues $VMName
    }
    
    Write-PSFMessage -Level Host -Message "Checking for intune object for VM {0}" -StringValues $VMName
    
    $IntuneDevice = Get-MgDeviceManagementManagedDevice -filter "deviceName eq '$VMName'"    
    if($IntuneDevice){
        Write-PSFMessage -Level Host -Message "Retrieved Intune device object for VM {0} with Id: {1}" -StringValues $VMName, $IntuneDevice.Id
        # Delete Intune Object
        Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $IntuneDevice.id
        Write-PSFMessage -Level Host -Message "Deleted device object for VM {0} from Intune" -StringValues $VMName
    }
    else{
        Write-PSFMessage -Level Warning -Message "Could not find intune device object for VM {0}" -StringValues $VMName
    }
    
}