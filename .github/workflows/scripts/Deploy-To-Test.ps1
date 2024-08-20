param (
    [string]$DomJoinUserName,
    [securestring]$DomJoinUserPassword,
    [string]$OUName,
    [string]$SubnetId,
    [string]$LogAnalyticsWorkspaceId,
    [string]$IdentityDomainName,
    [string]$ResourceGroupName,
    [string]$SessionHostResourceGroupName,
    [string]$HostPoolName,
    [string]$LocalAdminUserName
)

#$ResourceGroupName = '' # Same as the Host Pool RG

$TemplateParameters = @{
    EnableMonitoring                             = $true
    UseExistingLAW                               = $true
    LogAnalyticsWorkspaceId = $LogAnalyticsWorkspaceId # Only required if UseExistingLAW is $true. Use ResourceID

    ## Required Parameters ##
    HostPoolName                                 = $HostPoolName
    HostPoolResourceGroupName                    = $ResourceGroupName
    #SessionHostNamePrefix                        = 'avdshr' # Will be appended by '-XX'
    SessionHostNamePrefix                        = 'arpah' # Will be appended by '-XX'
    TargetSessionHostCount                       = 10 # How many session hosts to maintain in the Host Pool
    TargetSessionHostBuffer                      = 5 # The maximum number of session hosts to add during a replacement process
    IncludePreExistingSessionHosts               = $false # Include existing session hosts in automation

    # Identity
    # Using a User Managed Identity is recommended. You can assign the same identity to different instances of session host replacer instances. The identity should have the proper permissions in Azure and Entra.
    # The identity can be in a different Azure Subscription. If not used, a system assigned identity will be created and assigned permissions against the current subscription.
    UseUserAssignedManagedIdentity               = $false
    UserAssignedManagedIdentityResourceId        = '<Resource Id of the User Assigned Managed Identity>'

    ## Session Host Template Parameters ##
    SessionHostsRegion                           = 'eastus2' # Does not have to be the same as Host Pool
    AvailabilityZones                            = @("1", "3") # Set to empty array if not using AZs
    SessionHostSize                              = 'Standard_D4ads_v5' # Make sure its available in the region / AZs
    AcceleratedNetworking                        = $true # Make sure the size supports it
    SessionHostDiskType                          = 'Premium_LRS' #  STandard_LRS, StandardSSD_LRS, or Premium_LRS

    MarketPlaceOrCustomImage                     = 'Marketplace' # MarketPlace or Gallery
    MarketPlaceImage                             = 'win11_23h2_office'
    # If the Compute Gallery is in a different subscription assign the function app "Desktop Virtualization Virtual Machine Contributor" after deployment
    # GalleryImageId = '' # Only required for 'CustomImage'. Use ResourceId of an Image Definition.

    SecurityType                                 = 'TrustedLaunch' # Standard, TrustedLaunch, or ConfidentialVM
    SecureBootEnabled                            = $true
    TpmEnabled                                   = $true

    SubnetId                                     = $SubnetId

    IdentityServiceProvider                      = 'ActiveDirectory' # EntraID / ActiveDirectory / EntraDS
    IntuneEnrollment                             = $false # This is only used when IdentityServiceProvider is EntraID

    # Only used when IdentityServiceProvider is ActiveDirectory or EntraDS
    ADDomainName = $IdentityDomainName
    ADDomainJoinUserName = $DomJoinUserName
    ADJoinUserPassword = $DomJoinUserPassword # We will store this password in a key vault
    ADOUPath = $OUName  # OU DN where the session hosts will be joined

    LocalAdminUserName                           = $LocalAdminUserName # The password is randomly generated. Please use LAPS or reset from Azure Portal.


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
    SessionHostResourceGroupName                 = $SessionHostResourceGroupName # Leave empty if same as HostPoolResourceGroupName
}

$paramNewAzResourceGroupDeployment = @{
    Name = 'AVDSessionHostReplacer'
    ResourceGroupName = $ResourceGroupName
    #TemplateUri = 'https://raw.githubusercontent.com/Azure/AVDSessionHostReplacer/v0.0.1-beta.0/deploy/arm/DeployAVDSessionHostReplacer.json'

    # If you cloned the repo and want to deploy using the bicep file use this instead of the above line
    TemplateFile = '.\deploy\bicep\DeployAVDSessionHostReplacer-arpah.bicep'
    TemplateParameterObject = $TemplateParameters
}

#New-AzResourceGroupDeployment @paramNewAzResourceGroupDeployment

Write-Output $paramNewAzResourceGroupDeployment
Write-Output $TemplateParameters

#$output = 'DomJoinUserName={0}, DomJoinUserPassword={1}, OUName={2}, SubnetId={3}, LogAnalyticsWorkspaceId={4}, IdentityDomainName{5}' -f $DomJoinUserName, $DomJoinUserPassword, $OUName, $SubnetId, $LogAnalyticsWorkspaceId, $IdentityDomainName
#Write-Output $output
