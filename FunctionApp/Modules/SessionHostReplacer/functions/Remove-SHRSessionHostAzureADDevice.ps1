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

    # Get device object
    $device = Get-MgDevice -Filter "DisplayName eq '$VMName'"
    if($device){
        Write-PSFMessage -Level Host -Message "Retrieved device object for VM {0} with Id: {1}" -StringValues $VMName, $device.Id
        # Delete VM
        $null = Remove-MgDevice -DeviceId $device.Id -ErrorAction Stop
        Write-PSFMessage -Level Host -Message "Deleted device object for VM {0} from Azure AD" -StringValues $VMName
    }
    else{
        Write-PSFMessage -Level Warning -Message "Could not find device object for VM {0}" -StringValues $VMName
    }
}