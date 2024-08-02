param azureBlobsPrivateDnsZoneResourceId string
param azureFilesPrivateDnsZoneResourceId string
param azureQueuesPrivateDnsZoneResourceId string
param azureTablesPrivateDnsZoneResourceId string
param keyName string
param keyVaultUri string
param location string
param logAnalyticsWorkspaceResourceId string
param storageAccountDiagnosticSettingName string
param storageAccountName string
param storageAccountNetworkInterfaceName string
param storageAccountPrivateEndpointName string
param subnetResourceId string
param tags object
param userAssignedIdentityResourceId_Encryption string
param userAssignedIdentityResourceId_FunctionApp string

var roleDefinitionIds = [
  '17d1049b-9a84-46fb-8f53-869881c3d3ab' // Storage Account Contributor
  'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' // Storage Blob Data Owner
  '974c5e8b-45b9-4653-ba55-5f855dd0fb88' // Storage Queue Data Contributor
]
var storagePrivateDnsZoneResourceIds = [
  azureBlobsPrivateDnsZoneResourceId
  azureFilesPrivateDnsZoneResourceId
  azureQueuesPrivateDnsZoneResourceId
  azureTablesPrivateDnsZoneResourceId
]
var storageSubResources = [
  'blob'
  'file'
  'queue'
  'table'
]

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags[?'Microsoft.Storage/storageAccounts'] ?? {}
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId_Encryption}': {}
    }
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowedCopyScope: 'PrivateLink'
    allowSharedKeyAccess: false
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'None'
    }
    defaultToOAuthAuthentication: true
    dnsEndpointType: 'Standard'
    encryption: {
      identity: {
        userAssignedIdentity: userAssignedIdentityResourceId_Encryption
      }
      requireInfrastructureEncryption: true
      keyvaultproperties: {
        keyvaulturi: keyVaultUri
        keyname: keyName
      }
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        table: {
          keyType: 'Account'
          enabled: true
        }
        queue: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.KeyVault'
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    publicNetworkAccess: 'Disabled'
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(split(userAssignedIdentityResourceId_FunctionApp, '/')[2], split(userAssignedIdentityResourceId_FunctionApp, '/')[4])
  name: split(userAssignedIdentityResourceId_FunctionApp, '/')[8]
}

resource roleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for roleDefinitionId in roleDefinitionIds : {
  name: guid(userAssignedIdentityResourceId_FunctionApp, roleDefinitionId, storageAccount.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}]

resource privateEndpoints 'Microsoft.Network/privateEndpoints@2023-04-01' = [
  for resource in storageSubResources: {
    name: '${storageAccountPrivateEndpointName}-${resource}'
    location: location
    tags: tags[?'Microsoft.Network/privateEndpoints'] ?? {}
    properties: {
      customNetworkInterfaceName: '${storageAccountNetworkInterfaceName}-${resource}'
      privateLinkServiceConnections: [
        {
          name: '${storageAccountPrivateEndpointName}-${resource}'
          properties: {
            privateLinkServiceId: storageAccount.id
            groupIds: [
              resource
            ]
          }
        }
      ]
      subnet: {
        id: subnetResourceId
      }
    }
  }
]

resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = [
  for (resource, i) in storageSubResources: {
    parent: privateEndpoints[i]
    name: storageAccount.name
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'ipconfig1'
          properties: {
            #disable-next-line use-resource-id-functions
            privateDnsZoneId: storagePrivateDnsZoneResourceIds[i]
          }
        }
      ]
    }
  }
]

resource diagnosticSetting_blobs 'Microsoft.Insights/diagnosticSettings@2017-05-01-preview' = if (!empty(logAnalyticsWorkspaceResourceId)) {
  scope: blobService
  name: storageAccountDiagnosticSettingName
  properties: {
    logs: [
      {
        category: 'StorageWrite'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspaceResourceId
  }
}

output name string = storageAccount.name
output resourceId string = storageAccount.id
