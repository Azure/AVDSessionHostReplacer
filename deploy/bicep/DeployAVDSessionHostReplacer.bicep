targetScope = 'subscription'

@description('Required: Yes | Name of the Application Insights resource.')
param applicationInsightsName string

@description('Required: Yes | Name of the app service plan resource.')
param appServicePlanName string

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

@description('Required: No | Number of hours to wait before draining a session host.')
param drainGracePeriodHours int = 24

@allowed([
  'China'
  'Global'
  'USGov'
  'USGovDoD'
])
@description('Required: No | The environment name of the Entra ID tenant for connecting to Microsoft Graph.')
param entraIdEnvironmentName string = 'Global'

@description('Required: No | Choose whether the session host replacer will fix the tags on existing session hosts or if tags are mistakenly deleted. The tag values will NOT allow deletion of existing session hosts and must be changed post deployment. This is useful if you are deploying a new session host replacer to an existing host pool.')
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

@description('Required: Yes | Resource ID of the AVD host pool.')
param hostPoolResourceId string

@allowed([
  'EntraID'
  'ActiveDirectory'
  'EntraDS'
])
@description('Required: Yes | Identity service provider for the AVD session hosts.')
param identityServiceProvider string

@description('Required: Yes | Name of the key vault resource. This value must be globally unique.')
param keyVaultName string

@description('Required: Yes | Name of the network interface resource for the key vault.')
param keyVaultNetworkInterfaceName string

@description('Required: Yes | Resource ID of the private DNS zone for the key vault.')
param keyVaultPrivateDnsZoneResourceId string

@description('Required: Yes | Name of the private endpoint resource for the key vault.')
param keyVaultPrivateEndpointName string

@description('Required: No | Region of the Function App. This does not need to be the same as the location of the Azure Virtual Desktop Host Pool. | Default: Location of the resource group.')
param location string = deployment().location

@description('Required: Yes | Resource ID of the Log Analytics Workspace used by Application Insights to monitor the Function App.')
param logAnalyticsWorkspaceResourceId string

@description('Required: Yes | Resource ID of the private DNS zone for the private link scope.')
param privateLinkScopeResourceId string

@description('Required: No | Choose whether to replace the AVD session host when a new image version is available.')
param replaceSessionHostOnNewImageVersion bool = true

@description('Required: No | Number of days to wait before replacing the AVD session host when a new image version is available.')
param replaceSessionHostOnNewImageVersionDelayDays int = 0

@description('Required: Yes | Resource group name for the AVD session hosts.')
param sessionHostsResourceGroupName string

@description('Required: No | The prefix of the deployment created in the session hosts resource group when replacement VMs are deploying. This is used to track running and failed deployments.')
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

@description('Required: No | Tag used to determine when the session host was deployed. This is updated by the session host replacer function on new session hosts. After deployment, you can edit the value of this tag to force replace a VM.')
param tagDeployTimestamp string = 'AutoReplaceDeployTimestamp'

@description('Required: No | Tag used to determine if an existing session host should be included in the automation. After deployment, if the tag is present and set to "true", the session host will be included. If the tag is not present or set to "false", the session host will be excluded.')
param tagIncludeInAutomation string = 'IncludeInAutoReplace'

@description('Required: No | Tag used to determine when the session host was marked for drain. This is updated by the session host replacer function on hosts pending deletion.')
param tagPendingDrainTimestamp string = 'AutoReplacePendingDrainTimestamp'

@description('Required: No | Tags to apply to the resources.')
param tags object = {}

@description('Required: No | Tag used by session host replacer to exclude a session host from scaling plan actions.')
param tagScalingPlanExclusionTag string = 'ScalingPlanExclusion'

@description('Required: No | Number of days to wait before replacing the AVD session host when a new image version is available.')
param targetVMAgeDays int = 45

@description('Required: Yes | URI for the parameters file needed for the template spec deployment to deploy new AVD session hosts.')
param templateParametersUri object

@description('Required: Yes | Resource ID of the template spec version resource.')
param templateSpecVersionResourceId string

@description('Required: No | Value used to generate unique names for the deployments. Do not supply a value for this parameter.')
param timeStamp string = utcNow()

@description('Required: No | Name of the user assigned identity to support customer managed keys on the storage account.')
param userAssignedIdentityName string

@description('Required: Yes | Resource ID of the user assigned identity to support the function app. The resource group name in this value is used as the deployment scope for all resources.')
param userAssignedIdentityResourceId string

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

module functionApp 'modules/functionApp.bicep' = {
  name: 'deploy-function-app-${timeStamp}'
  scope: resourceGroup(split(userAssignedIdentityResourceId, '/')[2], split(userAssignedIdentityResourceId, '/')[4])
  params: {
    applicationInsightsName: applicationInsights.outputs.name
    appServicePlanName: appServicePlanName
    delegatedSubnetResourceId: delegatedSubnetResourceId
    entraIdEnvironmentName: entraIdEnvironmentName
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
        name: '_SessionHostTemplate'
        value: templateSpecVersionResourceId
      }
      {
        name: '_DeploymentParametersUri'
        value: templateParametersUri
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
        name: '_ReplaceSessionHostOnNewImageVersion'
        value: replaceSessionHostOnNewImageVersion
      }
      {
        name: '_ReplaceSessionHostOnNewImageVersionDelayDays'
        value: replaceSessionHostOnNewImageVersionDelayDays
      }
      {
        name: '_SessionHostResourceGroupName'
        value: sessionHostsResourceGroupName
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
  scope: resourceGroup(sessionHostsResourceGroupName)
  params: {
    userAssignedIdentityPrincipalId: userAssignedIdentity_FunctionApp.properties.principalId
    userAssignedIdentityResourceId: userAssignedIdentityResourceId
  }
}

module roleAssignment_TemplateSpec 'modules/roleAssignments/templateSpec.bicep' = {
  name: 'assign-rbac-template-spec-${timeStamp}'
  scope: resourceGroup(split(templateSpecVersionResourceId, '/')[2], split(templateSpecVersionResourceId, '/')[4])
  params: {
    templateSpecName: split(templateSpecVersionResourceId, '/')[8]
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
