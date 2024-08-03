targetScope = 'subscription'

@description('Required: No | Enable accelerated networking on the AVD session hosts.')
param acceleratedNetworking bool = true

@description('Required: No | Allow the session hosts to be downsized to a smaller VM size.')
param allowDownsizing bool = true

@description('Required: Yes | Name of the Application Insights resource.')
param applicationInsightsName string

@description('Required: Yes | Name of the app service plan resource.')
param appServicePlanName string

@description('Required: No | Zones for the AVD session hosts.')
param availabilityZones array = []

@description('Required: Yes | Resource ID of the Azure Blobs private DNS zone.')
param azureBlobsPrivateDnsZoneResourceId string

@description('Required: Yes | Resource ID of the Azure Files private DNS zone.')
param azureFilesPrivateDnsZoneResourceId string

@description('Required: Yes | Resource ID of the Azure Queues private DNS zone.')
param azureQueuesPrivateDnsZoneResourceId string

@description('Required: Yes | Resource ID of the Azure Tables private DNS zone.')
param azureTablesPrivateDnsZoneResourceId string

@description('Required: Yes | Resource ID of the delegated subnet for the function app.')
param delegatedSubnetResourceId string

@secure()
@description('Required: No | Password for the domain join account in Active Directory Domain Services.')
param domainJoinPassword string = ''

@description('Required: No | Username for the domain join account in Active Directory Domain Services.')
param domainJoinUserName string = ''

@description('Required: No | Name of the domain to join in Active Directory Domain Services.')
param domainName string = ''

@description('Required: No | Number of hours to wait before draining a session host.')
param drainGracePeriodHours int = 24

@allowed([
  'China'
  'Global'
  'USGov'
  'USGovDoD'
])
@description('Required: No | The environment name of the Entra ID tenant for connecting to Microsoft Graph.')
param entraEnvironmentName string = 'Global'

@description('Required: No | Choose whether to fix the session host tags.')
param fixSessionHostTags bool = true

@description('Required: Yes | Name of the function app resource.')
param functionAppName string

@description('Required: Yes | Name of the network interface resource for the function app.')
param functionAppNetworkInterfaceName string

@description('Required: Yes | Resource ID of the private DNS zone for the function app.')
param functionAppPrivateDnsZoneResourceId string

@description('Required: Yes | Name of the private endpoint resource for the function app.')
param functionAppPrivateEndpointName string

@description('Required: Yes | Resource ID of the private DNS zone for the SCM endpoint of the function app.')
param functionAppScmPrivateDnsZoneResourceId string

@description('Required: No | URL to the zip file for the function app. Ideally, this ZIP file should be hosted in Azure Blobs in a private container.')
param functionAppZipUrl string = 'https://github.com/Azure/AVDSessionHostReplacer/releases/download/v0.2.7/FunctionApp.zip'

@description('Required: No | Resource ID of the compute gallery image definition to use for the session hosts.')
param galleryImageId string = ''

@description('Required: Yes | Resource ID of the AVD host pool.')
param hostPoolResourceId string

@allowed([
  'EntraID'
  'ActiveDirectory'
  'EntraDS'
])
@description('Required: Yes | Identity service provider for the AVD session hosts.')
param identityServiceProvider string

@description('Required: No | Enroll the session hosts in Intune. This only applies if the identity service provider is EntraID.')
param intuneEnrollment bool = false

@description('Required: Yes | Name of the key vault resource. This value must be globally unique.')
param keyVaultName string

@description('Required: No | Distinguished name of the organization unit to join in Active Directory Domain Services.')
param organizationUnitPath string = ''

@description('Required: Yes | Name of the network interface resource for the key vault.')
param keyVaultNetworkInterfaceName string

@description('Required: Yes | Resource ID of the private DNS zone for the key vault.')
param keyVaultPrivateDnsZoneResourceId string

@description('Required: Yes | Name of the private endpoint resource for the key vault.')
param keyVaultPrivateEndpointName string

@description('Required: Yes | Username for the local admin account on the AVD session hosts.')
param localAdminUsername string

@description('Required: No | Region of the Function App. This does not need to be the same as the location of the Azure Virtual Desktop Host Pool. | Default: Location of the resource group.')
param location string = deployment().location

@description('Required: No | Resource ID of the Log Analytics Workspace used by Application Insights to monitor the Function App.')
param logAnalyticsWorkspaceResourceId string = ''

@description('Required: No | Offer of the Azure Marketplace image to use for the AVD session hosts.')
param marketPlaceImageOffer string = ''

@description('Required: No | Publisher of the Azure Marketplace image to use for the AVD session hosts.')
param marketPlaceImagePublisher string = ''

@description('Required: No | SKU of the Azure Marketplace image to use for the AVD session hosts.')
param marketPlaceImageSku string = ''

@description('Required: Yes | Resource ID of the private DNS zone for the private link scope.')
param privateLinkScopeResourceId string

@description('Required: No | Choose whether to replace the AVD session host when a new image version is available.')
param replaceSessionHostOnNewImageVersion bool = true

@description('Required: No | Number of days to wait before replacing the AVD session host when a new image version is available.')
param replaceSessionHostOnNewImageVersionDelayDays int = 0

@allowed([
  'Standard'
  'TrustedLaunch'
  'ConfidentialVM'
])
@description('Required: No | Security type of the AVD session hosts.')
param securityType string = 'TrustedLaunch'

@allowed([
  'Standard_LRS' // Standard HDD
  'StandardSSD_LRS' // Standard SSD
  'Premium_LRS' // Premium SSD
])
@description('The SKU of the AVD session host OS disk.')
param sessionHostDiskType string = 'Premium_LRS'

@description('Required: No | Number of digits to pad the AVD session host instance number for the resource names.')
param sessionHostInstanceNumberPadding int = 2

@description('Required: Yes | Prefix for the AVD session host resource names.')
param sessionHostNamePrefix string

@description('Required: Yes | Resource group name for the AVD session hosts.')
param sessionHostResourceGroupName string

@description('Required: Yes | Virtual machine size for the AVD session hosts.')
param sessionHostSize string

@description('Required: Yes | Location for the AVD session hosts.')
param sessionHostsRegion string

@description('Required: No | Deployment prefix for the AVD session host deployments.')
param shrDeploymentPrefix string = 'AVDSessionHostReplacer'

@description('Required: No | Name of the diagnostic setting for the storage account resource. This value is only required when a log analytics workspace resource ID is specified.')
param storageAccountDiagnosticSettingName string = ''

@description('Required: Yes | Name of the storage account resource. This resource is required for the function app.')
param storageAccountName string

@description('Required: Yes | Name of the network interface resource for the storage account.')
param storageAccountNetworkInterfaceName string

@description('Required: Yes | Name of the private endpoint resource for the storage account.')
param storageAccountPrivateEndpointName string

@description('Required: Yes | Resource ID of the subnet for the AVD session hosts.')
param subnetResourceId string

@description('')
param tagDeployTimestamp string = 'AutoReplaceDeployTimestamp'

@description('')
param tagIncludeInAutomation string = 'IncludeInAutoReplace'

@description('')
param tagPendingDrainTimestamp string = 'AutoReplacePendingDrainTimestamp'

@description('Required: No | Tags to apply to the resources.')
param tags object = {}

@description('Required: No | Exclusion tag for the AVD scaling plan')
param tagScalingPlanExclusionTag string = 'ScalingPlanExclusion'

@description('Required: Yes | Number of AVD session hosts to deploy.')
param targetSessionHostCount int

@description('Required: No | Number of days to wait before replacing the AVD session host when a new image version is available.')
param targetVMAgeDays int = 45

@description('Required: Yes | Name of the template spec resource.')
param templateSpecName string

@description('Required: No | Value used to generate unique names for the deployments. Do not supply a value for this parameter.')
param timeStamp string = utcNow()

@description('Required: No | Name of the user assigned identity to support customer managed keys on the storage account.')
param userAssignedIdentityName string

@description('Required: Yes | Resource ID of the user assigned identity to support the function app. The resource group name in this value is used as the deployment scope for all resources.')
param userAssignedIdentityResourceId string

@description('The name of the array parameter used in the Session Host deployment template to define the VM names. Default is "VMNames"')
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
  AcceleratedNetworking: acceleratedNetworking
  AdminUsername: localAdminUsername
  AvailabilityZones: availabilityZones
  DiskType: sessionHostDiskType
  DomainJoinObject: domainJoinObject
  DomainJoinPassword: domainJoinPasswordReference
  ImageReference: imageReference
  Location: sessionHostsRegion
  SecurityProfile: {
    securityType: securityType
    uefiSettings: {
      secureBootEnabled: true
      vTpmEnabled: true
    }
  }
  SubnetId: subnetResourceId
  tags: tags
  VMSize: sessionHostSize
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
    deployActionRoleDefinitionId: roleDefinition.name
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
    entraEnvironmentName: entraEnvironmentName
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

module roleAssignment_HostPool 'modules/roleAssignments/hostPool.bicep' = {
  name: 'assign-rbac-hostPool-${timeStamp}'
  scope: resourceGroup(split(hostPoolResourceId, '/')[4])
  params: {
    hostPoolResourceId: hostPoolResourceId
    userAssignedIdentityPrincipalId: userAssignedIdentity_FunctionApp.properties.principalId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

module roleAssignment_SessionHosts 'modules/roleAssignments/sessionHosts.bicep' = {
  name: 'assign-rbac-AVD-${timeStamp}'
  scope: resourceGroup(sessionHostResourceGroupName)
  params: {
    userAssignedIdentityPrincipalId: userAssignedIdentity_FunctionApp.properties.principalId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

module roleAssignment_TemplateSpec 'modules/roleAssignments/templateSpec.bicep' = {
  name: 'assign-rbac-template-spec-${timeStamp}'
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
  params: {
    templateSpecName: templateSpec.outputs.name
    userAssignedIdentityPrincipalId: userAssignedIdentity_FunctionApp.properties.principalId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

module roleAssignment_VirtualNetwork 'modules/roleAssignments/virtualNetwork.bicep' = {
  name: 'assign-rbac-AVD-${timeStamp}'
  scope: resourceGroup(split(subnetResourceId, '/')[4])
  params: {
    subnetResourceId: subnetResourceId
    userAssignedIdentityPrincipalId: userAssignedIdentity_FunctionApp.properties.principalId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}
