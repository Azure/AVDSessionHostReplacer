param azureBlobsPrivateDnsZoneResourceId string
param azureFilesPrivateDnsZoneResourceId string
param azureQueuesPrivateDnsZoneResourceId string
param azureTablesPrivateDnsZoneResourceId string
param functionAppName string
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
param userAssignedIdentityResourceId string

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

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
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
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowedCopyScope: 'PrivateLink'
    allowSharedKeyAccess: true
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'None'
    }
    defaultToOAuthAuthentication: false
    dnsEndpointType: 'Standard'
    encryption: {
      identity: {
        userAssignedIdentity: userAssignedIdentityResourceId
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

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-09-01' = {
  parent: storageAccount
  name: 'default'
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {
        versions: 'SMB3.1.1;'
        authenticationMethods: 'NTLMv2;'
        channelEncryption: 'AES-128-GCM;AES-256-GCM;'
      }
    }
    shareDeleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  parent: fileServices
  name: toLower(functionAppName)
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 5120
    enabledProtocols: 'SMB'
  }
}

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

resource privateDnsZoneGroups 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = [
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

resource diagnosticSetting_storage_blob 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (!empty(logAnalyticsWorkspaceResourceId)) {
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
