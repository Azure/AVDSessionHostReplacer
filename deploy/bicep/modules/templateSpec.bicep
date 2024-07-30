param location string = resourceGroup().location
param name string
param tags object

resource templateSpec 'Microsoft.Resources/templateSpecs@2022-02-01' = {
  name: name
  location: location
  tags: tags[?'Microsoft.Resources/templateSpecs'] ?? {}
  properties: {
    description: 'Template Spec for deploying VMs through the AVD Replacement Plan'
    displayName: 'AVD Replacement Plan Session Host Template'
  }
  resource deployTemplateSpecVersion 'versions@2022-02-01' = {
    name: 'deploymentTemplateSpecVersion'
    location: location
    properties: {
      mainTemplate: loadJsonContent('../../../StandardSessionHostTemplate/DeploySessionHosts.json')
    }
  }
}

output resourceId string = templateSpec.id
