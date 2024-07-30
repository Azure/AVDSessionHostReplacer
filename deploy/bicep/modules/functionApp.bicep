param applicationInsightsName string
param appServicePlanName string
param delegatedSubnetResourceId string
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

var cloudSuffix = replace(replace(environment().resourceManager, 'https://management.', ''), '/', '')

resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  tags: tags[?'Microsoft.Web/serverfarms'] ?? {}
  sku: {
    tier: 'ElasticPremium'
    name: 'EP1'
  }
  kind: 'functionapp'
  properties: {
    targetWorkerSizeId: 3
    targetWorkerCount: 1
    maximumElasticWorkerCount: 20
    zoneRedundant: false
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountName
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  tags: tags[?'Microsoft.Web/sites'] ?? {}
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    clientAffinityEnabled: false
    httpsOnly: true
    publicNetworkAccess: 'Disabled'
    serverFarmId: appServicePlan.id
    siteConfig: {
      appSettings: union(
        [
          {
            name: 'FUNCTIONS_EXTENSION_VERSION'
            value: '~4'
          }
          {
            name: 'FUNCTIONS_WORKER_RUNTIME'
            value: 'powershell'
          }
          {
            name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
            value: applicationInsights.properties.ConnectionString
          }
          {
            name: 'AzureWebJobsStorage'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id,'2019-06-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
          }
          {
            name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
            value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id,'2019-06-01').keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
          }
          {
            name: 'WEBSITE_CONTENTOVERVNET'
            value: 1
          }
          {
            name: 'WEBSITE_CONTENTSHARE'
            value: toLower(functionAppName)
          }
          {
            name: '_EnvironmentName'
            value: environment().name
          }
          {
            name: '_SubscriptionId'
            value: subscription().subscriptionId
          }
          {
            name: '_TenantId'
            value: subscription().tenantId
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
      use32BitWorkerProcess: false
    }
    virtualNetworkSubnetId: delegatedSubnetResourceId
    vnetContentShareEnabled: true
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

resource deployFromZip 'Microsoft.Web/sites/extensions@2023-01-01' = {
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
  name: 'deploy-a-record-${timestamp}'
  scope: resourceGroup(split(functionAppScmPrivateDnsZoneResourceId, '/')[2], split(functionAppScmPrivateDnsZoneResourceId, '/')[4])
  params: {
    functionAppName: functionAppName
    ipv4Address: privateEndpoint.properties.networkInterfaces[0].properties.ipConfigurations[0].properties.privateIPAddress
    privateDnsZoneName: split(functionAppScmPrivateDnsZoneResourceId, '/')[8]
  }
}
