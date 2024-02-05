[CmdletBinding()]
param (
    [Parameter()]
    [string] $Path = '.\Nightly',

    # Build Type, Release or Dev
    [Parameter(Mandatory = $false)]
    [ValidateSet('Release', 'Repo')]
    [string] $ReleaseType = 'Repo'
)
switch ($ReleaseType) {
    'Release' {
        # Not implemented yet
    }
    'Repo' {
        # Update the version banner.
        $timeStamp = Get-Date -Format 'yyyyMMdd-HHmmss' #This is the timestamp that will be used in the version banner
        $profilePs1 = Get-Content -Path .\FunctionApp\profile.ps1 # This is the profile.ps1 file
        $bannerLine = $profilePs1 | Where-Object { $_ -like '*Write-PSFMessage -Level Host -Message "This is SessionHostReplacer version {0}*' } # This is the line that contains the version banner
        if(-not $bannerLine) { throw 'Failed to find version banner line in profile.ps1' } # Fail if the version banner line is not found
        $index = $profilePs1.IndexOf($bannerLine) # This is the index of the version banner line
        $bannerLine = $bannerLine -replace '-StringValues.*', "-StringValues '$timeStamp (Repo)'" # This is the new version banner line showing timestamp and build type
        $profilePs1[$index] = $bannerLine # Replace the old version banner line with the new one
        $profilePs1 | Set-Content -Path .\FunctionApp\profile.ps1 # Update profile.ps1 file
    }
}
$folder = New-Item -Path $Path -ItemType Directory -Force
$zipFilePath = $folder.FullName + "\FunctionApp.zip"
if (Test-Path $zipFilePath) { Remove-Item $zipFilePath -Force }
Compress-Archive -Path .\FunctionApp\* -DestinationPath $folder\FunctionApp.zip -Force -CompressionLevel Optimal