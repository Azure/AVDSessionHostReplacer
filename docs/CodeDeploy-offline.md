# Code Deployment
## AVD Session Host Replacer with all parameters
This code deploys the AVD Session Host Replacer without dependency on GitHub. Remember to assign the [needed permissions](Permissions.md).

Required Files:
* [DeployAVDSessionHostReplacer.json](https://github.com/Azure/AVDSessionHostReplacer/releases/download/v0.3.2/DeployAVDSessionHostReplacer.json)
* [FunctionApp.zip](https://github.com/Azure/AVDSessionHostReplacer/releases/download/v0.3.2/FunctionApp.zip)

### PowerShell
```PowerShell
$ResourceGroupName = '<Target Resource Group Name>' # Same as the Host Pool RG

$TemplateParameters = @{
    OfflineDeploy = $true

    EnableMonitoring                             = $true
    UseExistingLAW                               = $false
    # LogAnalyticsWorkspaceId = '' # Only required if UseExistingLAW is $true. Use ResourceID

    ## Required Parameters ##
    HostPoolName                                 = '<Target Host Pool Name>'
    HostPoolResourceGroupName                    = $ResourceGroupName
    SessionHostNamePrefix                        = 'avdshr' # Will be appended by '-XX'
    TargetSessionHostCount                       = 10 # How many session hosts to maintain in the Host Pool
    TargetSessionHostBuffer                      = 5 # The maximum number of session hosts to add during a replacement process
    IncludePreExistingSessionHosts               = $false # Include existing session hosts in automation

    # Identity
    # Using a User Managed Identity is recommended. You can assign the same identity to different instances of session host replacer instances. The identity should have the proper permissions in Azure and Entra.
    # The identity can be in a different Azure Subscription. If not used, a system assigned identity will be created and assigned permissions against the current subscription.
    UseUserAssignedManagedIdentity               = $true
    UserAssignedManagedIdentityResourceId        = '<Resource Id of the User Assigned Managed Identity>'

    ## Session Host Template Parameters ##
    SessionHostsRegion                           = 'NorthEurope' # Does not have to be the same as Host Pool
    AvailabilityZones                            = @("1", "3") # Set to empty array if not using AZs
    SessionHostSize                              = 'Standard_D4ds_v5' # Make sure its available in the region / AZs
    AcceleratedNetworking                        = $true # Make sure the size supports it
    SessionHostDiskType                          = 'Premium_LRS' #  STandard_LRS, StandardSSD_LRS, or Premium_LRS

    MarketPlaceOrCustomImage                     = 'Marketplace' # MarketPlace or Gallery
    MarketPlaceImage                             = 'win11-23h2-avd-m365'
    # If the Compute Gallery is in a different subscription assign the function app "Desktop Virtualization Virtual Machine Contributor" after deployment
    # GalleryImageId = '' # Only required for 'CustomImage'. Use ResourceId of an Image Definition.

    SecurityType                                 = 'TrustedLaunch' # Standard, TrustedLaunch, or ConfidentialVM
    SecureBootEnabled                            = $true
    TpmEnabled                                   = $true

    SubnetId                                     = '<Resource Id, make sure it ends with /subnets/<subnetName>>'

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
    SessionHostInstanceNumberPadding             = 2 # this controls the name, 2=> -01 or 3=> -001
    ReplaceSessionHostOnNewImageVersion          = $true #Set this to false when you only want to replace when the hosts are old (see TargetVMAgeDays)
    ReplaceSessionHostOnNewImageVersionDelayDays = 0
    VMNamesTemplateParameterName                 = 'VMNames' # Do not change this unless using a custom Template to deploy
    SessionHostResourceGroupName                 = '' # Leave empty if same as HostPoolResourceGroupName
}

$paramNewAzResourceGroupDeployment = @{
    Name = 'AVDSessionHostReplacer'
    ResourceGroupName = $ResourceGroupName
    TemplateFile = '<Path_TO_DeployAVDSessionHostReplacer.json>'

    TemplateParameterObject = $TemplateParameters
}
$deploy = New-AzResourceGroupDeployment @paramNewAzResourceGroupDeployment

$null = Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $deploy.Outputs.functionAppName.Value -ArchivePath "<PATH_TO_FunctionApp.zip>" -Force


```
