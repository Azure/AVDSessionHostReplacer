targetScope = 'subscription'

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
@allowed([
  'China'
  'Global'
  'USGov'
  'USGovDoD'
])
param entraTenantType string = 'Global'
param fixSessionHostTags bool = true
param functionAppName string
param functionAppNetworkInterfaceName string
param functionAppPrivateDnsZoneResourceId string
param functionAppPrivateEndpointName string
param functionAppScmPrivateDnsZoneResourceId string
param functionAppZipUrl string = 'https://github.com/jamasten/AVDSessionHostReplacer/raw/main/FunctionApp.zip'
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
param location string = deployment().location
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
param userAssignedIdentityResourceId string
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

resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'Key Vault Deployment Operator')
  properties: {
    roleName: 'Key Vault Deployment Operator'
    description: 'Deploy a resource manager template with the access to the secrets in the Key Vault.'
    assignableScopes: [
      subscription().id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.KeyVault/vaults/deploy/action'
        ]
      }
    ]
  }
}

module userAssignedIdentity_Encryption 'modules/userAssignedIdentity.bicep' = {
  name: 'deploy-user-assigned-identity-encryption-${timeStamp}'
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
  params: {
    location: location
    tags: tags
    userAssignedIdentityName: '${userAssignedIdentityName}-Encryption'
  }
}

resource userAssignedIdentity_FunctionApp 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
  name: split(userAssignedIdentityResourceId, '/')[8]
}

module keyVault 'modules/keyVault.bicep' = {
  name: 'deploy-key-vault-${timeStamp}'
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
  params: {
    domainJoinPassword: domainJoinPassword
    keyVaultName: keyVaultName
    keyVaultNetworkInterfaceName: keyVaultNetworkInterfaceName
    keyVaultPrivateDnsZoneResourceId: keyVaultPrivateDnsZoneResourceId
    keyVaultPrivateEndpointName: keyVaultPrivateEndpointName
    deployActionRoleDefinitionId: roleDefinition.id
    subnetResourceId: subnetResourceId
    tags: tags
    userAssignedIdentityResourceId: userAssignedIdentity_Encryption.outputs.resourceId
    userAssignedIdentityPrincipalId: userAssignedIdentity_Encryption.outputs.principalId
  }
}

module storageAccount 'modules/storageAccount.bicep' = {
  name: 'deploy-storage-account-${timeStamp}'
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
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
    userAssignedIdentityResourceId_Encryption: userAssignedIdentity_Encryption.outputs.resourceId
    userAssignedIdentityResourceId_FunctionApp: userAssignedIdentity_FunctionApp.id
  }
}

module applicationInsights 'modules/applicationInsights.bicep' = {
  name: 'deploy-application-insights-${timeStamp}'
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
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
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
  params: {
    location: location
    name: templateSpecName
    tags: tags
  }
}

module functionApp 'modules/functionApp.bicep' = {
  name: 'deploy-function-app-${timeStamp}'
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
  params: {
    applicationInsightsName: applicationInsights.outputs.name
    appServicePlanName: appServicePlanName
    delegatedSubnetResourceId: delegatedSubnetResourceId
    entraTenantType: entraTenantType
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
        name: '_ClientId'
        value: userAssignedIdentity_FunctionApp.properties.clientId
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
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

module roleAssignment_TemplateSpec 'modules/roleAssignment_TemplateSpec.bicep' = {
  name: 'assign-rbac-template-spec-${timeStamp}'
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
  params: {
    principalId: userAssignedIdentity_FunctionApp.properties.principalId
    resourceId: userAssignedIdentityResourceId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '392ae280-861d-42bd-9ea5-08ee6d83b80e') // Template Spec Reader
    templateSpecName: templateSpec.outputs.name
  }
}

module roleAssignments_AVD 'modules/roleAssignment_AVD.bicep' = [for rg in [sessionHostResourceGroupName, split(hostPoolResourceId, '/')[4]] : {
  name: 'assign-rbac-AVD-${timeStamp}'
  scope: resourceGroup(rg)
  params: {
    principalId: userAssignedIdentity_FunctionApp.properties.principalId
    resourceId: userAssignedIdentityResourceId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'a959dbd1-f747-45e3-8ba6-dd80f235f97c') // Desktop Virtualization Virtual Machine Contributor
  }
}]
