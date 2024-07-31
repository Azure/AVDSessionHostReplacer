@secure()
param domainJoinPassword string
param keyVaultName string
param keyVaultNetworkInterfaceName string
param keyVaultPrivateEndpointName string
param location string = resourceGroup().location
param keyExpirationInDays int = 30
param keyVaultPrivateDnsZoneResourceId string
param subnetResourceId string
param tags object
param userAssignedIdentityName string
param userAssignedIdentityPrincipalId string


resource vault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: keyVaultName
  location: location
  tags: tags[?'Microsoft.KeyVault/vaults'] ?? {}
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
    publicNetworkAccess: 'Disabled'
    sku: {
      family: 'A'
      name: 'premium'
    }
    softDeleteRetentionInDays: 90
    tenantId: subscription().tenantId
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(userAssignedIdentityName, 'e147488a-f6f5-4113-8e2d-b22465e65bf6', keyVaultName)
  scope: vault
  properties: {
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'e147488a-f6f5-4113-8e2d-b22465e65bf6')  // Key Vault Crypto Service Encryption User
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: keyVaultPrivateEndpointName
  location: location
  tags: tags[?'Microsoft.Network/privateEndpoints'] ?? {}
  properties: {
    customNetworkInterfaceName: keyVaultNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: keyVaultPrivateEndpointName
        properties: {
          privateLinkServiceId: vault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
    subnet: {
      id: subnetResourceId
    }
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  parent: privateEndpoint
  name: vault.name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource key 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  parent: vault
  name: 'StorageEncryptionKey'
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 4096
    kty: 'RSA'
    rotationPolicy: {
      attributes: {
        expiryTime: 'P${string(keyExpirationInDays)}D'
      }
      lifetimeActions: [
        {
          action: {
            type: 'Notify'
          }
          trigger: {
            timeBeforeExpiry: 'P10D'
          }
        }
        {
          action: {
            type: 'Rotate'
          }
          trigger: {
            timeAfterCreate: 'P${string(keyExpirationInDays - 7)}D'
          }
        }
      ]
    }
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'DomainJoinPassword'
  properties: {
    value: domainJoinPassword
  }
}

output keyName string = key.name
output resourceId string = vault.id
output uri string = vault.properties.vaultUri
