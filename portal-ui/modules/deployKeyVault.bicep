//---- Parameters ----//
param Location string = resourceGroup().location
param KeyVaultName string

@secure()
param DomainJoinPassword string

//---- Varibalbes ----//

//---- Resources ----//
resource deployKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: KeyVaultName
  location: Location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForTemplateDeployment: true
    enableRbacAuthorization: true
  }
  resource secretDomainJoinPassword 'secrets@2023-07-01' = {
    name: 'DomainJoinPassword'
    properties: {
      value: DomainJoinPassword
    }
  }
}

//----Variables ----//
output keyVaultId string = deployKeyVault.id
