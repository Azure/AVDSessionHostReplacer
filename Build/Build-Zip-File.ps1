[CmdletBinding()]
param (
    [Parameter()]
    [string] $Path = '.\temp',

    [string] $Tag = 'v0.0.0'
)


# Update the version banner.
# The banner pattern is a regex pattern that matches the line containing the version banner. It has three matching groups, the second one is the one we replace.
$filesToUpdate = @(
    @{
        Path = '.\FunctionApp\profile.ps1'
        BannerPattern = @"
(Write-PSFMessage -Level Host -Message "This is SessionHostReplacer version \{0\}" -StringValues ')(.*)(')
"@
    }
    @{
        Path = '.\deploy\portal-ui\portal-ui.json'
        BannerPattern = '("text": "AVD session host replacer Portal UI Version: )(.*)(",)'
    }
    @{
        Path = '.\deploy\portal-ui\portal-ui.json'
        BannerPattern = '("uri": "https://github.com/Azure/AVDReplacementPlans/blob/)(.*)(/docs/Permissions.md")'
    }
    @{
        Path = '.\deploy\bicep\DeployAVDSessionHostReplacer.bicep'
        BannerPattern = "(param FunctionAppZipUrl string = 'https://github.com/Azure/AVDSessionHostReplacer/releases/download/)(.*)(/FunctionApp.zip')"
    }
    @{
        Path = '.\docs\CodeDeploy.md'
        BannerPattern = "(TemplateUri = 'https://raw.githubusercontent.com/Azure/AVDSessionHostReplacer/)(.+)(/deploy/arm/DeployAVDSessionHostReplacer.json')"
    }
    @{
        Path = '.\docs\CodeDeploy-offline.md'
        BannerPattern = "(\* \[DeployAVDSessionHostReplacer.json\]\(https://github.com/Azure/AVDSessionHostReplacer/releases/download/)(.+)(/DeployAVDSessionHostReplacer.json\))"
    }
    @{
        Path = '.\docs\CodeDeploy-offline.md'
        BannerPattern = "(\* \[FunctionApp.zip\]\(https://github.com/Azure/AVDSessionHostReplacer/releases/download/)(.+)(/FunctionApp.zip\))"
    }
)

foreach($file in $filesToUpdate){
    $fileContent = Get-Content -Path $file.Path
    $bannerLine = $fileContent | Where-Object { $_ -match $file.BannerPattern } # This is the line that contains the version banner
    if (-not $bannerLine) { throw "Failed to find version banner line in $($file.Path)" } # Fail if the version banner line is not found
    $index = $fileContent.IndexOf($bannerLine) # This is the index of the version banner line
    $bannerLine = $bannerLine -replace $file.BannerPattern,  ('$1{0}$3' -f $Tag) # This is the new version banner line showing timestamp and build type
    $fileContent[$index] = $bannerLine # Replace the old version banner line with the new one
    $fileContent | Set-Content -Path $file.Path # Update the file

    Write-Host "Updated version in $($file.Path) to: $bannerLine"
}

# Update Readme File
$readmePath = '.\README.md'
$readmeContent = Get-Content -Path $readmePath
$urlDeployAVDSessionHostReplacer = "https://raw.githubusercontent.com/Azure/AVDSessionHostReplacer/$Tag/deploy/arm/DeployAVDSessionHostReplacer.json" -replace ":", "%3A" -replace "/", "%2F"
$urlPortalUiUrl = "https://raw.githubusercontent.com/Azure/AVDSessionHostReplacer/$Tag/deploy/portal-ui/portal-ui.json" -replace ":", "%3A" -replace "/", "%2F"

$readmePortalUiLineIndex = $readmeContent.IndexOf( ($readmeContent | Where-Object {$_ -like "| Azure Portal UI           |*"}) )
$readmeContent[$readmePortalUiLineIndex] = "| Azure Portal UI           | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/$urlDeployAVDSessionHostReplacer/uiFormDefinitionUri/$urlPortalUiUrl)  [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/$urlDeployAVDSessionHostReplacer/uiFormDefinitionUri/$urlPortalUiUrl)  [![Deploy to Azure China](https://aka.ms/deploytoazurechinabutton)](https://portal.azure.cn/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/$urlDeployAVDSessionHostReplacer/uiFormDefinitionUri/$urlPortalUiUrl) |"

$readmeContent | Set-Content -Path $readmePath


# Create the zip file
$folder = New-Item -Path $Path -ItemType Directory -Force
$zipFilePath = $folder.FullName + "\FunctionApp.zip"
if (Test-Path $zipFilePath) { Remove-Item $zipFilePath -Force }
Compress-Archive -Path .\FunctionApp\* -DestinationPath $folder\FunctionApp.zip -Force -CompressionLevel Optimal


# Create json files for deployment
bicep build .\StandardSessionHostTemplate\DeploySessionHosts.bicep --outfile .\StandardSessionHostTemplate\DeploySessionHosts.json
bicep build .\deploy\bicep\DeployAVDSessionHostReplacer.bicep --outfile .\deploy\arm\DeployAVDSessionHostReplacer.json
