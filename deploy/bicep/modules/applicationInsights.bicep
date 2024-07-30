param applicationInsightsName string
param location string
param privateLinkScopeResourceId string
param tags object
param timestamp string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags[?'Microsoft.Insights/components'] ?? {}
  properties: {
    Application_Type: 'web'
  }
  kind: 'web'
}

module privateLinkScope 'privateLinkScope.bicep' = {
  name: 'deploy-private-link-scope-${timestamp}'
  scope: resourceGroup(split(privateLinkScopeResourceId, '/')[2], split(privateLinkScopeResourceId, '/')[4])
  params: {
    applicationInsightsName: applicationInsights.name
    applicationInsightsResourceId: applicationInsights.id
    privateLinkScopeResourceId: privateLinkScopeResourceId
  }
}
