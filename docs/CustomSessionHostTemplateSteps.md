# Custom Session Host Template
The default deployment includes a standard ARM template that is used to deploy the session hosts.
This template is saved as a Template Spec when deploying from Portal or using the accompanying [code deployment](\CodeDeploy.md)

If you wish to customize your own template you can do so starting from the bicep file [here](\..\StandardSessionHostTemplate\DeploySessionHosts.bicep).
This template loops through an array of `VMNames` to create all the sessions hosts triggered by the Session Host Replacer.

Bear in mind that the Session Host Replacer expects a few parameters to work properly.
These parameters must exist in the `SessionHostParameters` configuration setting of the FunctionApp and are case sensitive.

## `imageReference` Parameter

Used to build the VM. This can be a Marketplace image or an gallery one. SessionHostReplacer will use this
parameter to lookup for the latest image version.

### Example for Marketplace image
``` PowerShell
imageReference = @{
    publisher = 'MicrosoftWindowsDesktop'
    offer     = 'Windows-11'
    sku       = 'win11-22h2-avd'
    version   = 'latest'
}
```

### Example for Image Gallery
```PowerShell
imageReference = @{
    id = "/subscriptions/XXXXXXX/resourceGroups/rg-AVD-Dev-Image-01/providers/Microsoft.Compute/galleries/AVD_Gallery/images/FirstAVDImage"
}
```
Marketplace images are versioned as documented [here](https://support.microsoft.com/en-au/topic/windows-10-and-windows-11-client-images-for-december-2022-b4604f5f-571d-4ba9-8fdf-51f6302a2093)
The version of the image should always follow a format that ends with the ReleaseDate (`MajorVersion.MinorVersion.ReleaseDate`)
for example as of this writing the latest version of the Windows 11 22h2 on the Marketplace is `22621.963.*221209*` meaning it dated as December 9, 2022.
