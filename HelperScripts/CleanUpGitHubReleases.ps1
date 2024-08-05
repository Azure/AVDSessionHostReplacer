# This script is used to delete the pre-release (beta) versions after creating a new release.

$Repo = "Azure/AVDSessionHostReplacer"
$Confirm = $true

# gh auth login


$preReleases = gh release list -R $Repo --json tagName,isPrerelease --jq '.[] | select(.isPrerelease) | .tagName'

if($Confirm){
    Write-Host "Are you sure you want to remove the following releases?" -ForegroundColor Cyan
    Write-Host ($preReleases -join "`r`n") -ForegroundColor Magenta
    Write-Host "Press Enter delete, press any other key to cancel..." -ForegroundColor Cyan
    $confirmed = ([System.Console]::ReadKey($true)).Key -eq 'Enter'
}
else{
    $confirmed = $true
}
if($confirmed){
    $preReleases | foreach-Object {
        Write-PSFMessage -level Host -Message "Deleting prerelease: {0}" -StringValues $_
        gh release delete $_ -R $Repo -y --cleanup-tag
    }
}
