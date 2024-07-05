# This file enables modules to be automatically managed by the Functions service.
# See https://aka.ms/functionsmanageddependency for additional information.
#
@{
    # For latest supported version, go to 'https://www.powershellgallery.com/packages/Az'.
    # To use the Az module in your function app, please uncomment the line below.
    'AzureFunctionConfiguration'                   = "1.*"
    'Az.Resources'                                 = '6.*'
    'Az.DesktopVirtualization'                     = '3.*'
    'Az.Compute'                                   = '5.*'
    'PSFramework'                                  = '1.*'
    'Microsoft.Graph.Identity.DirectoryManagement' = '2.*'
    'Microsoft.Graph.DeviceManagement'             = '2.*'
}