// This is a sample bicep file //

param Location string = resourceGroup().location
param AvailabilityZones bool = false
param VMNames array
param VMSize string
param TimeZone string

param SubnetID string

param AdminUsername string

param AcceleratedNetworking bool
param DiskType string

param Tags object = {}

param imageReference object
param SecurityType string
param SecureBootEnabled string
param TpmEnabled string

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
