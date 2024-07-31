param functionAppPrincipalId string
param functionAppResourceId string
param roleDefinitionId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionAppResourceId, roleDefinitionId, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: functionAppPrincipalId
    principalType: 'ServicePrincipal'
  }
}
