# Code Deployment
## AVD Session Host Replacer with all parameters
### PowerShell
```PowerShell
$ResourceGroupName = '<Target Resource Group Name>' # Same as the Host Pool RG

$TemplateParameters = @{
    EnableMonitoring                             = $true
    UseExistingLAW                               = $false
    # LogAnalyticsWorkspaceId = '' # Only required if UseExistingLAW is $true. Use ResourceID

    ## Required Parameters ##
    HostPoolName                                 = '<Target Host Pool Name>'
    HostPoolResourceGroupName                    = $ResourceGroupName
    SessionHostNamePrefix                        = 'avdshr' # Will be appended by '-XX'
    TargetSessionHostCount                       = 2 # How many session hosts to maintain in the Host Pool

    ## Session Host Template Parameters ##
    SessionHostsRegion                           = 'NorthEurope' # Does not have to be the same as Host Pool
    AvailabilityZones                            = @("1", "3") # Set to empty array if not using AZs
    SessionHostSize                              = 'Standard_D4ds_v5' # Make sure its available in the region / AZs
    AcceleratedNetworking                        = $true # Make sure the size supports it
    SessionHostDiskType                          = 'Premium_LRS' # Premium_LRS or StandardSSD_LRS

    MarketPlaceOrCustomImage                     = 'Marketplace' # MarketPlace or CustomImage
    MarketPlaceImage                             = 'win11-23h2-avd-m365'
    # If the Compute Gallery is in a different subscription assign the function app "Desktop Virtualization Virtual Machine Contributor" after deployment
    # GalleryImageId = '' # Only required for 'CustomImage'. Use ResourceId of an Image Definition.

    SecurityType                                 = 'TrustedLaunch' # Standard, TrustedLaunch, or ConfidentialVM
    SecureBootEnabled                            = $true
    TpmEnabled                                   = $true

    SubnetId                                     = '/subscriptions/2a5d0771-685c-4101-a8bd-3b0ceb1691a3/resourceGroups/rg-avd-app1-dev-eun-network/providers/Microsoft.Network/virtualNetworks/vnet-app1-dev-eun-001/subnets/snet-avd-app1-dev-eun-001' # Resource Id, make sure it ends with /subnets/<subnetName>

    IdentityServiceProvider                      = 'EntraID' # EntraID / ActiveDirectory / EntraDS
    IntuneEnrollment                             = $false # This is only used when IdentityServiceProvider is EntraID

    # Only used when IdentityServiceProvider is ActiveDirectory or EntraDS
    #ADDomainName = 'contoso.com'
    #ADDomainJoinUserName = 'DomainJoin'
    #ADJoinUserPassword = 'P@ssw0rd' # We will store this password in a key vault
    #ADOUPath = '' # OU DN where the session hosts will be joined

    LocalAdminUserName                           = 'AVDAdmin' # The password is randomly generated. Please use LAPS or reset from Azure Portal.


    ## Optional Parameters ##
    TagIncludeInAutomation                       = 'IncludeInAutoReplace'
    TagDeployTimestamp                           = 'AutoReplaceDeployTimestamp'
    TagPendingDrainTimestamp                     = 'AutoReplacePendingDrainTimestamp'
    TagScalingPlanExclusionTag                   = 'ScalingPlanExclusion' # This is used to disable scaling plan on session hosts pending delete.
    TargetVMAgeDays                              = 45 # Set this to 0 to never consider hosts to be old. Not recommended as you may use it to force replace.

    DrainGracePeriodHours                        = 24
    FixSessionHostTags                           = $true
    SHRDeploymentPrefix                          = 'AVDSessionHostReplacer'
    AllowDownsizing                              = $true
    SessionHostInstanceNumberPadding             = 2 # this controls the name, 2=> -01 or 3=> -001
    ReplaceSessionHostOnNewImageVersion          = $true #Set this to false when you only want to replace when the hosts are old (see TargetVMAgeDays)
    ReplaceSessionHostOnNewImageVersionDelayDays = 0
    VMNamesTemplateParameterName                 = 'VMNames' # Do not change this unless using a custom Template to deploy
    SessionHostResourceGroupName                 = '' # Leave empty if same as HostPoolResourceGroupName
}

$paramNewAzResourceGroupDeployment = @{
    Name = 'AVDSessionHostReplacer'
    ResourceGroupName = $ResourceGroupName
    TemplateFile = 'https://raw.githubusercontent.com/Azure/AVDSessionHostReplacer/main/deploy/arm/DeployAVDSessionHostReplacer.json'
    # If you cloned the repo and want to deploy using the bicep file use this instead of the above line
    #TemplateFile = '.\deploy\bicep\DeployAVDSessionHostReplacer.bicep'
    TemplateParameterObject = $TemplateParameters
}
New-AzResourceGroupDeployment @paramNewAzResourceGroupDeployment

```
### Assign permissions
#### Active Directory Domain Joined
If your session hosts are joining domain using a secret stored in a Key Vault, the FucntionApp requires the following permissions,
- **Key Vault Secrets User**, this is required on the secret item.
- **Key Vault resource manager template deployment operator**, this is required at the Key Vault level.
> This role is not built-in so you will need to create a custom role following the instructions [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/key-vault-parameter?tabs=azure-cli#grant-deployment-access-to-the-secrets).

#### Entra Joined
If your session hosts are Entra Joined (not hybrid), the FunctionApp requires permissions in Entra ID in order to delete the devices when deleting session hosts.
Without this cleanup, creating a new session host with the same name will fail.
- **Graph API: Device.Read.All**, this is required to query Entra ID for devices.
- **Cloud Device Administrator Role**, this role is required to delete the devices from Entra ID. Assigning Graph API permissions to a system managed identity cannot be done from the portal.

You use the script below to configure the permissions. Make sure to run them with a Global Admin account.
```PowerShell
$FunctionAppSP = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' # The ID of the system managed identity of the function app

# Connect to Graph with requires scopes.
Connect-MgGraph -Scopes Application.ReadWrite.All, Directory.ReadWrite.All, AppRoleAssignment.ReadWrite.All,  RoleManagement.ReadWrite.Directory

#region: Assign Device.Read.All
$graphAppId = "00000003-0000-0000-c000-000000000000"
$graphSP = Get-MgServicePrincipal -Search "AppId:$graphAppId" -ConsistencyLevel eventual
$msGraphPermissions = @(
    'Device.Read.All', #Used to read user and group permissions
    'DeviceManagementManagedDevices.ReadWrite.All' #Used to remove Devices from Intune
)
$msGraphAppRoles = $graphSP.AppRoles | Where-Object { $_.Value -in $msGraphPermissions }

$msGraphAppRoles | ForEach-Object {
    $params = @{
        PrincipalId = $FunctionAppSP
        ResourceId  = $graphSP.Id
        AppRoleId   = $_.Id
    }
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $FunctionAppSP -BodyParameter $params -Verbose
}

# Assign Cloud Device Administrator
$directoryRole = Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Cloud Device Administrator'"
New-MgRoleManagementDirectoryRoleAssignment -RoleDefinitionId $directoryRole.Id -PrincipalId $FunctionAppSP  -DirectoryScopeId '/'
```