// This session host template is provided as a sample for you to build your own custom session host template.
// It builds Session Hosts that are Azure AD Joined and joins them to the host pool.
// It uses Windows 11 Enterprise multi-session + Microsoft 365 Apps, version 22H2 image from the marketplace.

//---- Parameters ----//
param VMName string
param VMSize string
param TimeZone string
param Location string = resourceGroup().location
param SubnetID string
param AdminUsername string
@secure()
param AdminPassword string = newGuid()

param AcceleratedNetworking bool

param Tags object = {}

param imageReference object

//HostPool join
param HostPoolName string
@secure()
param HostPoolToken string
param WVDArtifactsURL string = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02411.177.zip'

//Domain Join
param DomainJoinObject object

@secure()
param DomainJoinPassword string = ''

//---- Variables ----//


//---- Resources ----//


//---- Outputs ----//
