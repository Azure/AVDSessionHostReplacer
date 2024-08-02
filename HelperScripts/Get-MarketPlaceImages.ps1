$Targets = @(
    @{Publisher = 'MicrosoftWindowsDesktop'; Offer = 'windows-10'; SkuPattern = "*avd*" }
    @{Publisher = 'MicrosoftWindowsDesktop'; Offer = 'windows-11'; SkuPattern = "*avd*" }
    @{Publisher = 'MicrosoftWindowsDesktop'; Offer = 'office-365'; SkuPattern = "*avd*" }
)

$images = foreach ($target in $Targets) {
    $Skus = Get-AzVMImageSku -Location WestEurope -PublisherName $Target.Publisher -Offer $Target.Offer |
    Where-Object { $_.Skus -like $Target.SkuPattern }
    $Skus | foreach {
        $name = switch -Regex  ($_.Skus -split "-") {
            "win(\d{2})" { 'Windows ' + $Matches[1] + ' Enterprise' }
            "\d{2}h\d" { $_ }
            "avd" { "multi-session" }
            "m365" { "+ Microsoft 365 Apps" }
            "g2" { "(Gen 2)" }
        }

        $_ | Add-Member -Type NoteProperty -Name "FriendlyName" -Value ($name -join " ")
    }
    $Skus
}

$images | select PublisherName, Offer, Skus, FriendlyName | sort Skus | ft

$bicepImageReferenceOutput = $images | Sort-Object Skus | ForEach-Object {
    @"
'$($_.Skus)': {
  publisher: '$($_.PublisherName)'
  offer: '$($_.Offer)'
  sku: '$($_.Skus)'
}
"@
}
$bicepImageReferenceOutput | Set-Clipboard


$portalUIMarketplaceOutput = $images | Sort-Object Skus | ForEach-Object {
    @"
{
    "label": "$($_.FriendlyName)",
    "value": "$($_.Skus)"
}
"@
}
$portalUIMarketplaceOutput -join "," | scb
