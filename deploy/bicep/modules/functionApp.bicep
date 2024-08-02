param applicationInsightsName string
param appServicePlanName string
param delegatedSubnetResourceId string
param entraEnvironmentName string
param functionAppName string
param functionAppNetworkInterfaceName string
param functionAppPrivateDnsZoneResourceId string
param functionAppPrivateEndpointName string
param functionAppScmPrivateDnsZoneResourceId string
param functionAppZipUrl string
param location string = resourceGroup().location
param replacementPlanSettings array
param storageAccountName string
param subnetResourceId string
param tags object
param timestamp string
param userAssignedIdentityResourceId string

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags[?'Microsoft.Web/serverfarms'] ?? {}
  sku: {
    name: 'P1v3'
    tier: 'PremiumV3'
    size: 'P1v3'
    family: 'Pv3'
    capacity: 1
}
  kind: 'functionapp'
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  tags: tags[?'Microsoft.Web/sites'] ?? {}
  kind: 'functionapp'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityResourceId}': {}
    }
  }
  properties: {
    clientAffinityEnabled: false
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: true
      appSettings: union(
        [
          {
            name: '_AzureEnvironmentName'
            value: environment().name
          }
          {
            name: '_EntraEnvironmentName'
            value: entraEnvironmentName
          }
          {
            name: '_SubscriptionId'
            value: subscription().subscriptionId
          }
          {
            name: '_TenantId'
            value: subscription().tenantId
          }
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: applicationInsights.properties.ConnectionString
          }
          {
            name: 'AzureWebJobsStorage__blobServiceUri'
            value: 'https://${storageAccountName}.blob.${environment().suffixes.storage}'
          }
          {
            name: 'AzureWebJobsStorage__credential'
            value: 'managedidentity'
          }
          {
            name: 'AzureWebJobsStorage__managedIdentityResourceId'
            value: userAssignedIdentityResourceId
          }
          {
            name: 'AzureWebJobsStorage__queueServiceUri'
            value: 'https://${storageAccountName}.queue.${environment().suffixes.storage}'
          }
          {
            name: 'AzureWebJobsStorage__tableServiceUri'
            value: 'https://${storageAccountName}.table.${environment().suffixes.storage}'
          }
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~4'
          }
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: 'powershell'
          }
        ],
        replacementPlanSettings
      )
      cors: {
        allowedOrigins: [ 
          '${environment().portal}'
          'https://functions-next.${cloudSuffix}'
          'https://functions-staging.${cloudSuffix}'
          'https://functions.${cloudSuffix}'
        ]
      }
      ftpsState: 'Disabled'
      netFrameworkVersion: 'v6.0'
      powerShellVersion: '7.2'
      publicNetworkAccess: 'Disabled'
      use32BitWorkerProcess: false
    }
    virtualNetworkSubnetId: delegatedSubnetResourceId
    vnetContentShareEnabled: false
    vnetRouteAllEnabled: true
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: functionAppPrivateEndpointName
  location: location
  tags: tags[?'Microsoft.Network/privateEndpoints'] ?? {}
  properties: {
    customNetworkInterfaceName: functionAppNetworkInterfaceName
    privateLinkServiceConnections: [
      {
        name: functionAppPrivateEndpointName
        properties: {
          privateLinkServiceId: functionApp.id
          groupIds: [
            'sites'
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
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'ipconfig1'
        properties: {
          privateDnsZoneId: functionAppPrivateDnsZoneResourceId
        }
      }
    ]
  }
}

resource msDeploy 'Microsoft.Web/sites/extensions@2023-01-01' = {
  parent: functionApp
  name: 'MSDeploy'
  properties: {
    packageUri: functionAppZipUrl
  }
  dependsOn: [
    privateDnsZoneGroup
    privateEndpoint
  ]
}

// This module is used to deploy the A record for the SCM site which does not use a dedicated private endpoint
module scmARecord 'aRecord.bicep' = {
  name: 'deploy-scm-a-record-${timestamp}'
  scope: resourceGroup(split(functionAppScmPrivateDnsZoneResourceId, '/')[2], split(functionAppScmPrivateDnsZoneResourceId, '/')[4])
  params: {
    functionAppName: functionAppName
    ipv4Address: filter(privateDnsZoneGroup.properties.privateDnsZoneConfigs[0].properties.recordSets, record => record.recordSetName == functionAppName)[0].ipAddresses[0]
    privateDnsZoneName: split(functionAppScmPrivateDnsZoneResourceId, '/')[8]
  }
}
