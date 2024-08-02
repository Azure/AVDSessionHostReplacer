param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentityResourceId, 'a959dbd1-f747-45e3-8ba6-dd80f235f97c', resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'a959dbd1-f747-45e3-8ba6-dd80f235f97c') // Desktop Virtualization Virtual Machine Contributor
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
