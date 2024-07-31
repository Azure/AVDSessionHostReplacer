param acceleratedNetworking bool = true
param allowDownsizing bool = true
param applicationInsightsName string
param appServicePlanName string
param availabilityZones array = []
param azureBlobsPrivateDnsZoneResourceId string
param azureFilesPrivateDnsZoneResourceId string
param azureQueuesPrivateDnsZoneResourceId string
param azureTablesPrivateDnsZoneResourceId string
param delegatedSubnetResourceId string
@secure()
param domainJoinPassword string = ''
param domainJoinUserName string = ''
param domainName string = ''
param drainGracePeriodHours int = 24
param fixSessionHostTags bool = true
param functionAppName string
param functionAppNetworkInterfaceName string
param functionAppPrivateDnsZoneResourceId string
param functionAppPrivateEndpointName string
param functionAppScmPrivateDnsZoneResourceId string
param functionAppZipUrl string = 'https://github.com/Azure/AVDSessionHostReplacer/releases/download/v0.2.7/FunctionApp.zip'
param galleryImageId string = ''
param hostPoolResourceId string
param identityServiceProvider string
param intuneEnrollment bool = false
param keyVaultName string
param organizationUnitPath string = ''
param keyVaultNetworkInterfaceName string
param keyVaultPrivateDnsZoneResourceId string
param keyVaultPrivateEndpointName string
param localAdminUsername string
param location string = resourceGroup().location
param logAnalyticsWorkspaceResourceId string = ''
param marketPlaceImageOffer string
param marketPlaceImagePublisher string
param marketPlaceImageSku string
param privateLinkScopeResourceId string
param replaceSessionHostOnNewImageVersion bool = true
param replaceSessionHostOnNewImageVersionDelayDays int = 0
param securityType string = 'TrustedLaunch'
param sessionHostDiskType string = 'Premium_LRS'
param sessionHostInstanceNumberPadding int = 2
param sessionHostNamePrefix string
param sessionHostResourceGroupName string = ''
param sessionHostSize string
param sessionHostsRegion string
param shrDeploymentPrefix string = 'AVDSessionHostReplacer'
param storageAccountDiagnosticSettingName string
param storageAccountName string
param storageAccountNetworkInterfaceName string
param storageAccountPrivateEndpointName string
param subnetResourceId string
param tagDeployTimestamp string = 'AutoReplaceDeployTimestamp'
param tagIncludeInAutomation string = 'IncludeInAutoReplace'
param tagPendingDrainTimestamp string = 'AutoReplacePendingDrainTimestamp'
param tags object = {}
param tagScalingPlanExclusionTag string = 'ScalingPlanExclusion'
param targetSessionHostCount int
param targetVMAgeDays int = 45
param templateSpecName string
param timeStamp string = utcNow() // Used for unique deployment names. Do Not supply a value for this parameter.
param userAssignedIdentityName string
param vmNamesTemplateParameterName string = 'VMNames'

var imageReference = empty(galleryImageId) ? {
  publisher: marketPlaceImagePublisher
  offer: marketPlaceImageOffer
  sku: marketPlaceImageSku
  version: 'latest'
} : {
  Id: galleryImageId
}

var domainJoinObject = identityServiceProvider == 'EntraID' ? {
  DomainType: 'EntraID'
  IntuneJoin: intuneEnrollment
} : {
  DomainType: 'ActiveDirectory'
  DomainName: domainName
  DomainJoinUserName: domainJoinUserName
  ADOUPath: organizationUnitPath
}

var domainJoinPasswordReference = identityServiceProvider == 'EntraID' ? null : {
  reference: {
    keyVault: {
      id: keyVault.outputs.resourceId
    }
    secretName: 'DomainJoinPassword'
  }
}

var sessionHostTemplateParameters = {
  location: sessionHostsRegion
  availabilityZones: availabilityZones
  vmSize: sessionHostSize
  acceleratedNetworking: acceleratedNetworking
  diskType: sessionHostDiskType
  imageReference: imageReference
  securityProfile: {
    securityType: securityType
    uefiSettings: {
      secureBootEnabled: true
      vTpmEnabled: true
    }
  }
  subnetResourceId: subnetResourceId
  DomainJoinObject: domainJoinObject
  DomainJoinPassword: domainJoinPasswordReference
  AdminUsername: localAdminUsername
  tags: tags
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userAssignedIdentityName
  location: location
  tags: tags[?'Microsoft.ManagedIdentity/userAssignedIdentities'] ?? {}
}

module keyVault 'modules/keyVault.bicep' = {
  name: 'deploy-key-vault-${timeStamp}'
  params: {
    domainJoinPassword: domainJoinPassword
    keyVaultName: keyVaultName
    keyVaultNetworkInterfaceName: keyVaultNetworkInterfaceName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: keyVaultPrivateEndpointName
    subnetResourceId: subnetResourceId
    tags: tags
    userAssignedIdentityName: userAssignedIdentityName
    userAssignedIdentityPrincipalId: userAssignedIdentity.properties.principalId
  }
}

module storageAccount 'modules/storageAccount.bicep' = {
  name: 'deploy-storage-account-${timeStamp}'
  params: {
    azureBlobsPrivateDnsZoneResourceId: azureBlobsPrivateDnsZoneResourceId
    azureFilesPrivateDnsZoneResourceId: azureFilesPrivateDnsZoneResourceId
    azureQueuesPrivateDnsZoneResourceId: azureQueuesPrivateDnsZoneResourceId
    azureTablesPrivateDnsZoneResourceId: azureTablesPrivateDnsZoneResourceId
    keyName: keyVault.outputs.keyName
    keyVaultUri: keyVault.outputs.uri
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    storageAccountDiagnosticSettingName: storageAccountDiagnosticSettingName
    storageAccountName: storageAccountName
    storageAccountNetworkInterfaceName: storageAccountNetworkInterfaceName
    storageAccountPrivateEndpointName: storageAccountPrivateEndpointName
    subnetResourceId: subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity.id
  }
}

module applicationInsights 'modules/applicationInsights.bicep' = {
  name: 'deploy-application-insights-${timeStamp}'
  params: {
    applicationInsightsName: applicationInsightsName
    location: location
    privateLinkScopeResourceId: privateLinkScopeResourceId
    tags: tags
    timestamp: timeStamp
  }
}

module templateSpec 'modules/templateSpec.bicep' = {
  name: 'deploy-template-spec-${timeStamp}'
  params: {
    location: location
    name: templateSpecName
    tags: tags
  }
}

module functionApp 'modules/functionApp.bicep' = {
  name: 'deploy-function-app-${timeStamp}'
  params: {
    applicationInsightsName: applicationInsights.outputs.name
    appServicePlanName: appServicePlanName
    delegatedSubnetResourceId: delegatedSubnetResourceId
    functionAppName: functionAppName
    functionAppNetworkInterfaceName: functionAppNetworkInterfaceName
    functionAppPrivateDnsZoneResourceId: functionAppPrivateDnsZoneResourceId
    functionAppPrivateEndpointName: functionAppPrivateEndpointName
    functionAppScmPrivateDnsZoneResourceId: functionAppScmPrivateDnsZoneResourceId
    functionAppZipUrl: functionAppZipUrl
    location: location
    replacementPlanSettings: [
      // Required Parameters //
      {
        name: '_HostPoolResourceGroupName'
        value: split(hostPoolResourceId, '/')[4]
      }
      {
        name: '_HostPoolName'
        value: split(hostPoolResourceId, '/')[8]
      }
      {
        name: '_TargetSessionHostCount'
        value: targetSessionHostCount
      }
      {
        name: '_SessionHostNamePrefix'
        value: sessionHostNamePrefix
      }
      {
        name: '_SessionHostTemplate'
        value: templateSpec.outputs.resourceId
      }
      {
        name: '_SessionHostParameters'
        value: string(sessionHostTemplateParameters)
      }
      {
        name: '_RemoveAzureADDevice'
        value: identityServiceProvider == 'EntraID'
      }
      {
        name: '_ClientResourceId'
        value: userAssignedIdentity.id
      }
    
      // Optional Parameters //
      {
        name: '_Tag_IncludeInAutomation'
        value: tagIncludeInAutomation
      }
      {
        name: '_Tag_DeployTimestamp'
        value: tagDeployTimestamp
      }
      {
        name: '_Tag_PendingDrainTimestamp'
        value: tagPendingDrainTimestamp
      }
      {
        name: '_Tag_ScalingPlanExclusionTag'
        value: tagScalingPlanExclusionTag
      }
      {
        name: '_TargetVMAgeDays'
        value: targetVMAgeDays
      }
      {
        name: '_DrainGracePeriodHours'
        value: drainGracePeriodHours
      }
      {
        name: '_FixSessionHostTags'
        value: fixSessionHostTags
      }
      {
        name: '_SHRDeploymentPrefix'
        value: shrDeploymentPrefix
      }
      {
        name: '_AllowDownsizing'
        value: allowDownsizing
      }
      {
        name: '_SessionHostInstanceNumberPadding'
        value: sessionHostInstanceNumberPadding
      }
      {
        name: '_ReplaceSessionHostOnNewImageVersion'
        value: replaceSessionHostOnNewImageVersion
      }
      {
        name: '_ReplaceSessionHostOnNewImageVersionDelayDays'
        value: replaceSessionHostOnNewImageVersionDelayDays
      }
      {
        name: '_VMNamesTemplateParameterName'
        value: vmNamesTemplateParameterName
      }
      {
        name: '_SessionHostResourceGroupName'
        value: sessionHostResourceGroupName
      }
    ]
    storageAccountName: storageAccount.outputs.name
    subnetResourceId: subnetResourceId
    tags: tags
    timestamp: timeStamp
  }
}

module roleAssignment_TemplateSpec 'modules/roleAssignment_TemplateSpec.bicep' = {
  name: 'assign-rbac-template-spec-${timeStamp}'
  params: {
    functionAppPrincipalId: functionApp.outputs.principalId
    functionAppResourceId: functionApp.outputs.resourceId
    templateSpecName: templateSpec.outputs.name
  }
}

module roleAssignments_AVD 'modules/roleAssignment_AVD.bicep' = [for rg in [sessionHostResourceGroupName, split(hostPoolResourceId, '/')[4]] : {
  name: 'assign-rbac-AVD-${timeStamp}'
  scope: resourceGroup(rg)
  params: {
    functionAppPrincipalId: functionApp.outputs.principalId
    functionAppResourceId: functionApp.outputs.resourceId
    roleDefinitionId: 'a959dbd1-f747-45e3-8ba6-dd80f235f97c' // Desktop Virtualization Virtual Machine Contributor
  }
}]
