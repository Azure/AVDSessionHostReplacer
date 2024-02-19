// This is a sample bicep file //

param VMNames array
param VMSize string
param TimeZone string
param Location string = resourceGroup().location

@description('This parameter name is mandatory and is passed using this name from AVDMF')
param SubnetID string

param AdminUsername string

param AcceleratedNetworking bool

param Tags object = {}

param imageReference object

//HostPool join
param HostPoolName string
@secure()
param HostPoolToken string
param WVDArtifactsURL string

//Domain Join
param DomainJoinObject object = {}

@secure()
param DomainJoinPassword string = ''

module deploySessionHosts 'modules/AVDSampleTemplate.bicep' = [for vm in VMNames: {
  name: 'deploySessionHosts-${vm}'
  params: {
    AcceleratedNetworking: AcceleratedNetworking
    AdminUsername: AdminUsername
    HostPoolName: HostPoolName
    HostPoolToken:  HostPoolToken
    imageReference: imageReference
    SubnetID: SubnetID
    TimeZone: TimeZone
    VMName: vm
    VMSize: VMSize
    WVDArtifactsURL:  WVDArtifactsURL
    DomainJoinObject: DomainJoinObject
    DomainJoinPassword: DomainJoinPassword
    Location: Location
    Tags: Tags
  }
}]
