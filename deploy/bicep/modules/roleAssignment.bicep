targetScope = 'subscription'

param prinicpalId string
param roleDefinitionId string
param scope string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(prinicpalId, roleDefinitionId, scope)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
    principalId: prinicpalId
  }
}
