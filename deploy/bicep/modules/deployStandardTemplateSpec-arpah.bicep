param Name string
param Location string = resourceGroup().location

resource deployTemplateSpec 'Microsoft.Resources/templateSpecs@2022-02-01' = {
  name: Name
  location: Location
  properties: {
    description: 'Template Spec for deploying VMs through the AVD Replacement Plan'
    displayName: 'AVD Replacement Plan Session Host Template'
  }
  resource deployTemplateSpecVersion 'versions@2022-02-01' = {
    name: 'deploymentTemplateSpecVersion'
    location: Location
    properties: {
      mainTemplate: loadJsonContent('../../../StandardSessionHostTemplate/DeploySessionHosts-arpah.json')
    }
  }
}
output TemplateSpecResourceId string = deployTemplateSpec.id
