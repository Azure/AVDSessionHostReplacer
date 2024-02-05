# Image Version Based Replacement
One of the parameters provided to the FunctionApp is the image reference used to build the VM. This can be a Marketplace image or an gallery one.
``` PowerShell
# Example for Marketplace image
@{
    publisher = 'MicrosoftWindowsDesktop'
    offer     = 'Windows-11'
    sku       = 'win11-22h2-avd'
    version   = 'latest'
}
# Example for Image Gallery
@{
    id = "/subscriptions/XXXXXXX/resourceGroups/rg-AVD-Dev-Image-01/providers/Microsoft.Compute/galleries/AVD_Gallery/images/FirstAVDImage"
}
```
Marketplace images are versioned as documented [here](https://support.microsoft.com/en-au/topic/windows-10-and-windows-11-client-images-for-december-2022-b4604f5f-571d-4ba9-8fdf-51f6302a2093)
The version of the image should always follow a format that ends with the ReleaseDate (`MajorVersion.MinorVersion.ReleaseDate`)
for example as of this writing the latest version of the Windows 11 22h2 on the Marketplace is `22621.963.*221209*` meaning it dated as December 9, 2022.
