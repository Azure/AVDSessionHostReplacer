//------ Parameters ------//
@description('Required: No | Region of the Function App. This does not need to be the same as the location of the Azure Virtual Desktop Host Pool. | Default: Location of the resource group.')
param Location string = resourceGroup().location

// FunctionApp
@description('Required: No | Boolean to enable offline deployment of the Function App. | Default: false')
param OfflineDeploy bool = false

@description('Required: No | URL of the FunctionApp.zip file. This is the zip file containing the Function App code. Must be provided when OfflineDeploy is set to false | Default: The latest release of the Function App code.')
param FunctionAppZipUrl string = 'https://github.com/Azure/AVDSessionHostReplacer/releases/download/v0.3.2/FunctionApp.zip'

//Monitoring
param EnableMonitoring bool = true
param UseExistingLAW bool = false
@description('Required: Yes | Name of the Log Analytics Workspace used by the Function App Insights.')
param LogAnalyticsWorkspaceId string = 'none'

// Template
param UseStandardTemplate bool = true

// Standard Session Host Template
param SessionHostsRegion string = ''
param AvailabilityZones array = []
param SessionHostSize string = ''
param AcceleratedNetworking bool = false

@allowed([
  'Standard_LRS' // Standard HDD
  'StandardSSD_LRS' // Standard SSD
  'Premium_LRS' // Premium SSD
])
param SessionHostDiskType string = 'Premium_LRS'

@allowed([
  'Marketplace'
  'Gallery'
])
param MarketPlaceOrCustomImage string = 'Marketplace'

@allowed([
  '2022-datacenter-smalldisk-g2'
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
  'win10-22h2-avd-g2'
])
param MarketPlaceImage string = 'win11-23h2-avd-m365'
param GalleryImageId string = ''

@allowed([
  'Standard'
  'TrustedLaunch'
  'ConfidentialVM'
])
param SecurityType string = 'TrustedLaunch'
param SecureBootEnabled bool = true
param TpmEnabled bool = true
param SubnetId string = ''

@allowed([
  'EntraID'
  'ActiveDirectory'
  'EntraDS'
])
param IdentityServiceProvider string = 'EntraID'
param IntuneEnrollment bool = false
param ADDomainName string = ''
param ADDomainJoinUserName string = ''
@secure()
param ADJoinUserPassword string = ''
param ADOUPath string = ''
param LocalAdminUsername string = ''

// Custom Session Host Template
param CustomTemplateSpecResourceId string = ''

@description('Required: No | The name of the parameter in the template that specifies the VM Names array.')
param VMNamesTemplateParameterName string = 'VMNames'

param CustomTemplateSpecParameters string = '{}' // This is a JSON string

//Required Parameters
@description('Required: No | Name of the resource group containing the Azure Virtual Desktop Host Pool. | Default: The resource group of the Function App.')
param HostPoolResourceGroupName string = resourceGroup().name

@description('Required: Yes | Name of the Azure Virtual Desktop Host Pool.')
param HostPoolName string

@description('Required: Yes | Prefix used for the name of the session hosts.')
@maxLength(12)
param SessionHostNamePrefix string

@description('Required: NO | Separator between prefix and number. | Default: -')
@maxLength(1)
param SessionHostNameSeparator string = '-'

@description('Required: Yes | Number of session hosts to maintain in the host pool.')
@minValue(0)
param TargetSessionHostCount int

@description('Required: Yes | The maximum number of session hosts to add during a replacement process')
@minValue(1)
param TargetSessionHostBuffer int

@description('Required: No | Switches to using the US Governmment DoD graph endpoints for the Function App. | Default: false')
param UseGovDodGraph bool = false

@description('Required: No | Resource Id of the User Assigned Managed Identity to use for the Function App. | Default: System Identity')
param UseUserAssignedManagedIdentity bool = false
param UserAssignedManagedIdentityResourceId string = ''

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

@description('Required: No | When enabled, the Session Host Replacer will automatically consider pre-existing VMs for replacement if they meet the criteria | Default: False.')
param IncludePreExistingSessionHosts bool = false

@description('Required: No | Prefix used for the deployment name of the session hosts. | Default: AVDSessionHostReplacer')
param SHRDeploymentPrefix string = 'AVDSessionHostReplacer'

@description('Required: No | Number of digits to use for the instance number of the session hosts (eg. AVDVM-01). | Default: 2')
param SessionHostInstanceNumberPadding int = 2

@description('Required: No | If true, will replace session hosts when a new image version is detected. | Default: true')
param ReplaceSessionHostOnNewImageVersion bool = true

@description('Required: No | Delay in days before replacing session hosts when a new image version is detected. | Default: 0 (no delay).')
param ReplaceSessionHostOnNewImageVersionDelayDays int = 0

@description('Required: No | Leave this empty to deploy to same resource group as the host pool.')
param SessionHostResourceGroupName string = ''

param TimeStamp string = utcNow() // Used for unique deployment names. Do Not supply a value for this parameter.

/////////////////

//---- Variables ----//
var varMarketPlaceImages = {
  'win10-21h2-avd': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-10'
    sku: 'win10-21h2-avd'
  }
  'win10-21h2-avd-g2': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-10'
    sku: 'win10-21h2-avd-g2'
  }
  'win10-21h2-avd-m365': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win10-21h2-avd-m365'
  }
  'win10-21h2-avd-m365-g2': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win10-21h2-avd-m365-g2'
  }
  'win10-22h2-avd': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-10'
    sku: 'win10-22h2-avd'
  }
  'win10-22h2-avd-g2': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-10'
    sku: 'win10-22h2-avd-g2'
  }
  'win10-22h2-avd-m365': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win10-22h2-avd-m365'
  }
  'win10-22h2-avd-m365-g2': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win10-22h2-avd-m365-g2'
  }
  'win11-21h2-avd': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-11'
    sku: 'win11-21h2-avd'
  }
  'win11-21h2-avd-m365': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win11-21h2-avd-m365'
  }
  'win11-22h2-avd': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-11'
    sku: 'win11-22h2-avd'
  }
  'win11-22h2-avd-m365': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win11-22h2-avd-m365'
  }
  'win11-23h2-avd': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'windows-11'
    sku: 'win11-23h2-avd'
  }
  'win11-23h2-avd-m365': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'office-365'
    sku: 'win11-23h2-avd-m365'
  }
}
var varImageReference = MarketPlaceOrCustomImage == 'Marketplace'
  ? {
      publisher: varMarketPlaceImages[MarketPlaceImage].publisher
      offer: varMarketPlaceImages[MarketPlaceImage].offer
      sku: varMarketPlaceImages[MarketPlaceImage].sku
      version: 'latest'
    }
  : {
      Id: GalleryImageId
    }

var varSecurityProfile = SecurityType == 'Standard'
  ? null
  : {
      securityType: SecurityType
      uefiSettings: {
        secureBootEnabled: SecureBootEnabled
        vTpmEnabled: TpmEnabled
      }
    }

var varDomainJoinObject = IdentityServiceProvider == 'EntraID'
  ? {
      DomainType: 'EntraID'
      IntuneJoin: IntuneEnrollment
    }
  : {
      DomainType: 'ActiveDirectory'
      DomainName: ADDomainName
      DomainJoinUserName: ADDomainJoinUserName
      ADOUPath: ADOUPath
    }

var varDomainJoinPasswordReference = IdentityServiceProvider == 'EntraID'
  ? null
  : {
      reference: {
        keyVault: {
          id: deployKeyVault.outputs.keyVaultId
        }
        secretName: 'DomainJoinPassword'
      }
    }
var varSessionHostTemplateParameters = UseStandardTemplate
  ? {
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
      VMNamePrefixLength: length(SessionHostNamePrefix) + length(SessionHostNameSeparator) //This is used when deploying in multiple availability zones.
      tags: {}
    }
  : CustomTemplateSpecParameters
// This variable calculates the Entra Environment Name based on the Azure Environment Name in environment()
// Define  mapping arrays for environment names and their corresponding Graph name
var varAzureEnvironments = [
  'AzureCloud' // Global
  'AzureUSGovernment' // USGov
  'AzureChinaCloud' // China
]
var varGraphEnvironmentNames = UseGovDodGraph
  ? [
      'Global' // AzureCloud
      'USGovDod' // AzureUSGovernment
      'China' // AzureChinaCloud
    ]
  : [
      'Global' // AzureCloud
      'USGov' // AzureUSGovernment
      'China' // AzureChinaCloud
    ]
var varGraphEnvironmentName = varGraphEnvironmentNames[indexOf(varAzureEnvironments, environment().name)]

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
    name: '_TargetSessionHostBuffer'
    value: TargetSessionHostBuffer
  }
  {
    name: '_SessionHostNamePrefix'
    value: SessionHostNamePrefix
  }
  {
    name: '_SessionHostNameSeparator'
    value: SessionHostNameSeparator
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
    name: '_RemoveEntraDevice'
    value: IdentityServiceProvider == 'EntraID'
  }
  {
    name: '_RemoveIntuneDevice'
    value: IntuneEnrollment
  }
  {
    name: '_ClientId'
    value: UseUserAssignedManagedIdentity ? userAssignedIdentity.properties.clientId : ''
  }
  {
    name: '_TenantId'
    value: UseUserAssignedManagedIdentity ? userAssignedIdentity.properties.tenantId : ''
  }
  {
    name: '_GraphEnvironmentName'
    value: varGraphEnvironmentName
  }
  {
    name: '_AzureEnvironmentName'
    value: environment().name
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
    name: '_IncludePreExistingSessionHosts'
    value: IncludePreExistingSessionHosts
  }
  {
    name: '_SHRDeploymentPrefix'
    value: SHRDeploymentPrefix
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

var varFunctionAppIdentity = UseUserAssignedManagedIdentity
  ? {
      type: 'UserAssigned'
      userAssignedIdentities: {
        '${UserAssignedManagedIdentityResourceId}': {}
      }
    }
  : {
      type: 'SystemAssigned'
    }

// Outputs for verification

//---- Resources ----//

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = if (UseUserAssignedManagedIdentity) {
  scope: resourceGroup(
    split(UserAssignedManagedIdentityResourceId, '/')[2],
    split(UserAssignedManagedIdentityResourceId, '/')[4]
  )
  name: split(UserAssignedManagedIdentityResourceId, '/')[8]
}

module deployFunctionApp 'modules/deployFunctionApp.bicep' = {
  name: 'deployFunctionApp'
  params: {
    Location: Location
    OfflineDeploy: OfflineDeploy
    FunctionAppZipUrl: FunctionAppZipUrl
    FunctionAppName: varFunctionAppName
    EnableMonitoring: EnableMonitoring
    UseExistingLAW: UseExistingLAW
    LogAnalyticsWorkspaceId: LogAnalyticsWorkspaceId
    ReplacementPlanSettings: varReplacementPlanSettings
    FunctionAppIdentity: varFunctionAppIdentity
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
// These roles are only assigned if the FunctionApp is using a System Managed Identity (MSI). Please manually assign when using a User Assigned Managed Identity.
module RoleAssignmentsVdiVMContributor 'modules/RBACRoleAssignment.bicep' = if (!UseUserAssignedManagedIdentity) {
  name: 'RBAC-vdiVMContributor-${TimeStamp}'
  scope: subscription()
  params: {
    PrinicpalId: deployFunctionApp.outputs.functionAppPrincipalId
    RoleDefinitionId: 'a959dbd1-f747-45e3-8ba6-dd80f235f97c' // Desktop Virtualization Virtual Machine Contributor
    Scope: subscription().id
  }
}
module RBACTemplateSpec 'modules/RBACRoleAssignment.bicep' = if (!UseUserAssignedManagedIdentity) {
  name: 'RBAC-TemplateSpecReader-${TimeStamp}'
  scope: subscription()
  params: {
    PrinicpalId: deployFunctionApp.outputs.functionAppPrincipalId
    RoleDefinitionId: '392ae280-861d-42bd-9ea5-08ee6d83b80e' // Template Spec Reader
    Scope: deployStandardSessionHostTemplate.outputs.TemplateSpecResourceId
  }
}

//---- Outputs ----//
output functionAppName string = varFunctionAppName
