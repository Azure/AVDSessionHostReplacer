//------ Parameters ------//
@description('Required: No | Region of the Function App. This does not need to be the same as the location of the Azure Virtual Desktop Host Pool. | Default: Location of the resource group.')
param Location string = resourceGroup().location

//Monitoring
param EnableMonitoring bool = true
param UseExistingLAW bool = false
@description('Required: Yes | Name of the Log Analytics Workspace used by the Function App Insights.')
param LogAnalyticsWorkspaceId string = 'none'

// Session Host Template
param SessionHostsRegion string
param AvailabilityZones array = []
param SessionHostSize string
param AcceleratedNetworking bool

@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
])
param SessionHostDiskType string = 'Premium_LRS'

@allowed([
  'Marketplace'
  'Gallery'
])
param MarketPlaceOrCustomImage string

@allowed([ '2022-datacenter-smalldisk-g2'
  'win10-21h2-avd'
  '2022-datacenter-core-g2'
  'win10-22h2-avd-m365-g2'
  'win11-21h2-avd'
  'win10-21h2-avd-m365'
  'win11-22h2-avd-m365'
  '2022-datacenter-core-smalldisk-g2'
  'win11-21h2-avd-m365'
  'win11-23h2-avd'
  'win11-23h2-avd-m365'
  'win11-22h2-avd'
  '2022-datacenter-g2'
  'win10-22h2-avd-g2' ])
param MarketPlaceImage string = 'win11-23h2-avd-m365'
param GalleryImageId string = ''

@allowed([
  'Standard'
  'TrustedLaunch'
  'ConfidentialVM'
])
param SecurityType string
param SecureBootEnabled bool
param TpmEnabled bool
param SubnetId string

@allowed([
  'EntraID'
  'ActiveDirectory'
  'EntraDS'
])
param IdentityServiceProvider string
param IntuneEnrollment bool
param ADDomainName string = ''
param ADDomainJoinUserName string = ''
@secure()
param ADJoinUserPassword string = ''
param ADOUPath string = ''
param LocalAdminUsername string

//Required Parameters
@description('Required: No | Name of the resource group containing the Azure Virtual Desktop Host Pool. | Default: The resource group of the Function App.')
param HostPoolResourceGroupName string = resourceGroup().name

@description('Required: Yes | Name of the Azure Virtual Desktop Host Pool.')
param HostPoolName string

@description('Required: Yes | Prefix used for the name of the session hosts.')
@maxLength(12)
param SessionHostNamePrefix string

@description('Required: Yes | Number of session hosts to maintain in the host pool.')
param TargetSessionHostCount int

// Optional Parameters
@description('Required: No | Tag name used to indicate that a session host should be included in the automatic replacement process. | Default: IncludeInAutoReplace.')
param TagIncludeInAutomation string = 'IncludeInAutoReplace'

@description('Required: No | Tag name used to indicate the timestamp of the last deployment of a session host. | Default: AutoReplaceDeployTimestamp.')
param TagDeployTimestamp string = 'AutoReplaceDeployTimestamp'

@description('Required: No | Tag name used to indicate drain timestamp of session host pending deletion. | Default: AutoReplacePendingDrainTimestamp.')
param TagPendingDrainTimestamp string = 'AutoReplacePendingDrainTimestamp'

@description('Required: No | Tag name used to exclude session host from Scaling Plan activities. | Default: ScalingPlanExclusion')
param TagScalingPlanExclusionTag string = 'ScalingPlanExclusion'

@description('Required: No | Target age of session hosts in days. | Default:  45 days.')
param TargetVMAgeDays int = 45

@description('Required: No | Grace period in hours for session hosts to drain before deletion. | Default: 24 hours.')
param DrainGracePeriodHours int = 24

@description('Required: No | If true, will apply tags for Include In Auto Replace and Deployment Timestamp to existing session hosts. This will not enable automatic deletion of existing session hosts. | Default: True.')
param FixSessionHostTags bool = true

@description('Required: No | Prefix used for the deployment name of the session hosts. | Default: AVDSessionHostReplacer')
param SHRDeploymentPrefix string = 'AVDSessionHostReplacer'

@description('Required: No | Allow deleting session hosts if count exceeds target. | Default: true')
param AllowDownsizing bool = true

@description('Required: No | Number of digits to use for the instance number of the session hosts (eg. AVDVM-01). | Default: 2')
param SessionHostInstanceNumberPadding int = 2

@description('Required: No | If true, will replace session hosts when a new image version is detected. | Default: true')
param ReplaceSessionHostOnNewImageVersion bool = true

@description('Required: No | Delay in days before replacing session hosts when a new image version is detected. | Default: 0 (no delay).')
param ReplaceSessionHostOnNewImageVersionDelayDays int = 0

@description('Required: No | The name of the parameter in the template that specifies the VM Names array.')
param VMNamesTemplateParameterName string = 'VMNames'

@description('Required: No | Leave this empty to deploy to same resource group as the host pool.')
param SessionHostResourceGroupName string = ''

param TimeStamp string = utcNow() // Used for unique deployment names. Do Not supply a value for this parameter.

/////////////////

//---- Variables ----//
var varMarketPlaceImages = {
  '2022-datacenter-smalldisk-g2': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-smalldisk-g2'
  }
  'win10-21h2-avd': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-10'
    sku: 'win10-21h2-avd'
  }
  '2022-datacenter-core-g2': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-core-g2'
  }
  'win10-22h2-avd-m365-g2': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win10-22h2-avd-m365-g2'
  }
  'win11-21h2-avd': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-11'
    sku: 'win11-21h2-avd'
  }
  'win10-21h2-avd-m365': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win10-21h2-avd-m365'
  }
  'win11-22h2-avd-m365': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win11-22h2-avd-m365'
  }
  '2022-datacenter-core-smalldisk-g2': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-core-smalldisk-g2'
  }
  'win11-21h2-avd-m365': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win11-21h2-avd-m365'
  }
  'win11-23h2-avd': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-11'
    sku: 'win11-23h2-avd'
  }
  'win11-23h2-avd-m365': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win11-23h2-avd-m365'
  }
  'win11-22h2-avd': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-11'
    sku: 'win11-22h2-avd'
  }
  '2022-datacenter-g2': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-g2'
  }
  'win10-22h2-avd-g2': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-10'
    sku: 'win10-22h2-avd-g2'
  }
}
var varImageReference = MarketPlaceOrCustomImage == 'Marketplace' ? {
  publisher: varMarketPlaceImages[MarketPlaceImage].publisher
  offer: varMarketPlaceImages[MarketPlaceImage].offer
  sku: varMarketPlaceImages[MarketPlaceImage].sku
  version: 'latest'
} : {
  Id: GalleryImageId
}

var varSecurityProfile = SecurityType == 'Standard' ? null : {
  securityType: SecurityType
  uefiSettings: {
    secureBootEnabled: SecureBootEnabled
    vTpmEnabled: TpmEnabled
  }
}

var varDomainJoinObject = IdentityServiceProvider == 'EntraID' ? {
  DomainType: 'EntraID'
  IntuneJoin: IntuneEnrollment
} : {
  DomainType: 'ActiveDirectory'
  DomainName: ADDomainName
  DomainJoinUserName: ADDomainJoinUserName
  ADOUPath: ADOUPath
}

var varDomainJoinPasswordReference = IdentityServiceProvider == 'EntraID' ? null : {
  reference: {
    keyVault: {
      id: deployKeyVault.outputs.keyVaultId
    }
    secretName: 'DomainJoinPassword'
  }
}
var varSessionHostTemplateParameters = {
  Location: SessionHostsRegion
  AvailabilityZones: AvailabilityZones
  VMSize: SessionHostSize
  AcceleratedNetworking: AcceleratedNetworking
  DiskType: SessionHostDiskType
  ImageReference: varImageReference
  SecurityProfile: varSecurityProfile
  SubnetId: SubnetId
  DomainJoinObject: varDomainJoinObject
  DomainJoinPassword: varDomainJoinPasswordReference
  AdminUsername: LocalAdminUsername
  tags: {}
}
var varReplacementPlanSettings = [
  // Required Parameters //
  {
    name: '_HostPoolResourceGroupName'
    value: HostPoolResourceGroupName
  }
  {
    name: '_HostPoolName'
    value: HostPoolName
  }
  {
    name: '_TargetSessionHostCount'
    value: TargetSessionHostCount
  }
  {
    name: '_SessionHostNamePrefix'
    value: SessionHostNamePrefix
  }
  {
    name: '_SessionHostTemplate'
    value: deployStandardSessionHostTemplate.outputs.TemplateSpecResourceId
  }
  {
    name: '_SessionHostParameters'
    value: string(varSessionHostTemplateParameters)
  }
  {
    name: '_SubscriptionId'
    value: subscription().subscriptionId
  }
  {
    name: '_RemoveAzureADDevice'
    value: IdentityServiceProvider == 'EntraID'
  }

  // Optional Parameters //
  {
    name: '_Tag_IncludeInAutomation'
    value: TagIncludeInAutomation
  }
  {
    name: '_Tag_DeployTimestamp'
    value: TagDeployTimestamp
  }
  {
    name: '_Tag_PendingDrainTimestamp'
    value: TagPendingDrainTimestamp
  }
  {
    name: '_Tag_ScalingPlanExclusionTag'
    value: TagScalingPlanExclusionTag
  }
  {
    name: '_TargetVMAgeDays'
    value: TargetVMAgeDays
  }
  {
    name: '_DrainGracePeriodHours'
    value: DrainGracePeriodHours
  }
  {
    name: '_FixSessionHostTags'
    value: FixSessionHostTags
  }
  {
    name: '_SHRDeploymentPrefix'
    value: SHRDeploymentPrefix
  }
  {
    name: '_AllowDownsizing'
    value: AllowDownsizing
  }
  {
    name: '_SessionHostInstanceNumberPadding'
    value: SessionHostInstanceNumberPadding
  }
  {
    name: '_ReplaceSessionHostOnNewImageVersion'
    value: ReplaceSessionHostOnNewImageVersion
  }
  {
    name: '_ReplaceSessionHostOnNewImageVersionDelayDays'
    value: ReplaceSessionHostOnNewImageVersionDelayDays
  }
  {
    name: '_VMNamesTemplateParameterName'
    value: VMNamesTemplateParameterName
  }
  {
    name: '_SessionHostResourceGroupName'
    value: SessionHostResourceGroupName
  }
]

var varUniqueString = uniqueString(resourceGroup().id, HostPoolName)
var varFunctionAppName = 'AVDSessionHostReplacer-${uniqueString(resourceGroup().id, HostPoolName)}'



// Outputs for verification

//---- Resources ----//


module deployFunctionApp 'modules/deployFunctionApp.bicep' = {
  name: 'deployFunctionApp'
  params: {
    Location: Location
    FunctionAppName: varFunctionAppName
    EnableMonitoring: EnableMonitoring
    UseExistingLAW: UseExistingLAW
    LogAnalyticsWorkspaceId: LogAnalyticsWorkspaceId
    ReplacementPlanSettings: varReplacementPlanSettings
  }
}

module deployKeyVault 'modules/deployKeyVault.bicep' = if (IdentityServiceProvider != 'EntraID') {
  name: 'deployKeyVault'
  params: {
    Location: Location
    KeyVaultName: 'kv-AVDSHR-${varUniqueString}'
    DomainJoinPassword: ADJoinUserPassword
  }
}
module deployStandardSessionHostTemplate 'modules/deployStandardTemplateSpec.bicep' = {
  name: 'deployStandardSessionHostTemplate'
  params: {
    Location: Location
    Name: '${HostPoolName}-Spec'
  }
}
//---- Role Assignments ----//
module RoleAssignmentsVdiVMContributor 'modules/RBACRoleAssignment.bicep' = {
  name: 'RBAC-vdiVMContributor-${TimeStamp}'
  scope: subscription()
  params: {
    PrinicpalId: deployFunctionApp.outputs.functionAppPrincipalId
    RoleDefinitionId: 'a959dbd1-f747-45e3-8ba6-dd80f235f97c' // Desktop Virtualization Virtual Machine Contributor
    Scope: subscription().id
  }
}
module RBACTemplateSpec 'modules/RBACRoleAssignment.bicep' = {
  name: 'RBAC-TemplateSpecReader-${TimeStamp}'
  scope: subscription()
  params: {
    PrinicpalId: deployFunctionApp.outputs.functionAppPrincipalId
    RoleDefinitionId: '392ae280-861d-42bd-9ea5-08ee6d83b80e' // Template Spec Reader
    Scope: deployStandardSessionHostTemplate.outputs.TemplateSpecResourceId
  }
}
