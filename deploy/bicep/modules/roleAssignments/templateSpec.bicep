param templateSpecName string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string

resource templateSpec 'Microsoft.Resources/templateSpecs@2022-02-01' existing = {
  name: templateSpecName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentityResourceId, '392ae280-861d-42bd-9ea5-08ee6d83b80e', templateSpec.id)
  scope: templateSpec
  properties: {
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', '392ae280-861d-42bd-9ea5-08ee6d83b80e') // Template Spec Reader
  }
}
