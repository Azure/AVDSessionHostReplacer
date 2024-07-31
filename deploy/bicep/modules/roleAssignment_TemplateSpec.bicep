param functionAppPrincipalId string
param functionAppResourceId string
param templateSpecName string

resource templateSpec 'Microsoft.Resources/templateSpecs@2022-02-01' existing = {
  name: templateSpecName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionAppResourceId, '392ae280-861d-42bd-9ea5-08ee6d83b80e', templateSpec.id)
  scope: templateSpec
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '392ae280-861d-42bd-9ea5-08ee6d83b80e') // Template Spec Reader
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}
