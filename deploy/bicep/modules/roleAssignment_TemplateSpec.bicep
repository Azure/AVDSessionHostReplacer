param principalId string
param resourceId string
param roleDefinitionId string
param templateSpecName string

resource templateSpec 'Microsoft.Resources/templateSpecs@2022-02-01' existing = {
  name: templateSpecName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceId, roleDefinitionId, templateSpec.id)
  scope: templateSpec
  properties: {
    roleDefinitionId: roleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
