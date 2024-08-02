param subnetResourceId string
param userAssignedIdentityPrincipalId string
param userAssignedIdentityResourceId string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: split(subnetResourceId, '/')[8]
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentityResourceId, 'a959dbd1-f747-45e3-8ba6-dd80f235f97c', virtualNetwork.id)
  scope: virtualNetwork
  properties: {
    principalId: userAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'a959dbd1-f747-45e3-8ba6-dd80f235f97c') // Desktop Virtualization Virtual Machine Contributor
  }
}
