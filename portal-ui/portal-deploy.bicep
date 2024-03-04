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
param SessionHostDiskType string
param MarketPlaceOrCustomImage string
param MarketPlaceImage string = ''
param GalleryImageId string = ''
param SecurityType string
param SecureBootEnabled bool
param TpmEnabled bool
param SubnetId string
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

/////////////////

//---- Variables ----//
var varMarketPlaceImages = {
  win10_21h2: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-10'
    sku: 'win10-21h2-avd'
  }
  win10_21h2_office: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win10-21h2-avd-m365'
  }
  win10_22h2_g2: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-10'
    sku: 'win10-22h2-avd-g2'
  }
  win10_22h2_office_g2: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win10-22h2-avd-m365-g2'
  }
  win11_21h2: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-11'
    sku: 'win11-21h2-avd'
  }
  win11_21h2_office: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win11-21h2-avd-m365'
  }
  win11_22h2: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-11'
    sku: 'win11-22h2-avd'
  }
  win11_22h2_office: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win11-22h2-avd-m365'
  }
  win11_23h2: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-11'
    sku: 'win11-23h2-avd'
  }
  win11_23h2_office: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win11-23h2-avd-m365'
  }
  winServer_2022_Datacenter: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-g2'
  }
  winServer_2022_Datacenter_smalldisk_g2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-smalldisk-g2'
  }
  winServer_2022_datacenter_core: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-core-g2'
  }
  winServer_2022_Datacenter_core_smalldisk_g2: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-core-smalldisk-g2'
  }
}
var varImageReference = MarketPlaceOrCustomImage == 'MarketPlace' ? {
  publisher: varMarketPlaceImages[MarketPlaceImage].publisher
  offer: varMarketPlaceImages[MarketPlaceImage].offer
  sku: varMarketPlaceImages[MarketPlaceImage].sku
  version: 'latest'
} : {
  id: GalleryImageId
}

var varSecurityProfile = SecurityType == 'Standard' ? null: {    securityProfile: {
  securityType: SecurityType
  uefiSettings: {
    secureBootEnabled: SecureBootEnabled
    vTpmEnabled: TpmEnabled
  }
}}

var varDomainJoinObject = IdentityServiceProvider != 'EntraId' ? {
  DomainType: 'ActiveDirectory'
  DomainName: ADDomainName
  DomainJoinUserName: ADDomainJoinUserName
  ADOUPath: ADOUPath
} : {
  DomainType: 'EntraId'
  IntuneJoin: IntuneEnrollment
}

var varSessionHostTemplateParameters = {
  Location: SessionHostsRegion
  AvailabilityZones: AvailabilityZones
  VMSize: SessionHostSize
  AcceleratedNetworking: AcceleratedNetworking
  DiskType: SessionHostDiskType
  ImageType: MarketPlaceOrCustomImage
  imageReference: varImageReference
  SecurityProfile: varSecurityProfile
  SubnetId: SubnetId
  DomainJoinObject: varDomainJoinObject
  ADJoinUserPassword: 'Placeholder for Keyvault: ${ADJoinUserPassword}'
  AdminUsername: LocalAdminUsername
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

//---- Modules ----//
module FunctionApp 'modules/deployFunctionApp.bicep' = {
  name: 'deployFunctionApp'
  params: {
    Location: Location
    FunctionAppName: 'AVDSessionHostReplacer-${uniqueString(resourceGroup().id,HostPoolName)}'
    EnableMonitoring: EnableMonitoring
    UseExistingLAW: UseExistingLAW
    LogAnalyticsWorkspaceId: LogAnalyticsWorkspaceId
    ReplacementPlanSettings: varReplacementPlanSettings
  }
}

module deployStandardSessionHostTemplate 'modules/deployStandardTemplateSpec.bicep' = {
  name: 'deployStandardSessionHostTemplate'
  params: {
    Location: Location
    Name: '${HostPoolName}-Spec'
  }
}
