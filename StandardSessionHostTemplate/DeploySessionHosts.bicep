// This is a sample bicep file //

param Location string = resourceGroup().location
param AvailabilityZones array = []
param VMNames array
param VMSize string
param TimeZone string

param SubnetID string

param AdminUsername string

param AcceleratedNetworking bool
param DiskType string

param Tags object = {}

param ImageReference object
param SecurityProfile object

//HostPool join
param HostPoolName string
@secure()
param HostPoolToken string
param WVDArtifactsURL string

//Domain Join
param DomainJoinObject object = {}

@secure()
param DomainJoinPassword string = ''

module deploySessionHosts 'modules/AVDStandardSessionHost.bicep' = [for vm in VMNames: {
  name: 'deploySessionHost-${vm}'
  params: {
    AcceleratedNetworking: AcceleratedNetworking
    AdminUsername: AdminUsername
    HostPoolName: HostPoolName
    HostPoolToken:  HostPoolToken
    ImageReference: ImageReference
    SecurityProfile: SecurityProfile
    SubnetID: SubnetID
    TimeZone: TimeZone
    VMName: vm
    VMSize: VMSize
    DiskType: DiskType
    WVDArtifactsURL:  WVDArtifactsURL
    DomainJoinObject: DomainJoinObject
    DomainJoinPassword: DomainJoinPassword
    Location: Location
    AvailabilityZones: AvailabilityZones
    Tags: Tags
  }
}]
