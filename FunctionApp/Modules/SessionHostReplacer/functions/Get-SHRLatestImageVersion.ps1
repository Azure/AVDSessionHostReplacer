function Get-SHRLatestImageVersion {
    [CmdletBinding()]
    param (
        # An Image reference object. Can be from Marketplace or Shared Image Gallery.
        [Parameter()]
        [hashtable] $ImageReference
    )

    # Marketplace image
    if ($ImageReference.publisher) {
        #TODO Do we need to change location here?
        if ($ImageReference.version -ne 'latest') {
            Write-PSFMessage -Level Host -Message "Image version is not set to latest. Returning version {0}" -StringValues $ImageReference.version
            $azImageVersion = $ImageReference.version
        }
        else {
            # Get the Images and select the latest version.
            $paramGetAzVMImage = @{
                Location      = 'WestEurope'
                PublisherName = $ImageReference.publisher
                Offer         = $ImageReference.offer
                Skus          = $ImageReference.sku
            }
            Write-PSFMessage -Level Host -Message "Getting latest version of image {0} {1} {2} {3}" -StringValues $paramGetAzVMImage.Location, $paramGetAzVMImage.PublisherName, $paramGetAzVMImage.Offer, $paramGetAzVMImage.Skus

            $azImageVersion = (Get-AzVMImage @paramGetAzVMImage | Sort-Object -Property {[version] $_.Version} -Descending| Select-Object -First 1).Version
            Write-PSFMessage -Level Host -Message "Latest version of image is {0}" -StringValues $azImageVersion

            if ($azImageVersion -match "\d+\.\d+\.(?<Year>\d{2})(?<Month>\d{2})(?<Day>\d{2})") {
                $azImageDate = Get-Date -Date ("20{0}-{1}-{2}" -f $Matches.Year, $Matches.Month, $Matches.Day)
                Write-PSFMessage -Level Host -Message "Image date is {0}" -StringValues $azImageDate
            }
            else {
                throw "Image version does not match expected format. Could not extract image date."
            }
        }
    }
    elseif ($ImageReference.Id) {
        # Shared Image Gallery
        Write-PSFMessage -Level Host -Message 'Image is from Shared Image Gallery: {0}' -StringValues $ImageReference.Id
        $imageDefinitionResourceIdPattern = '^\/subscriptions\/(?<subscription>[a-z0-9\-]+)\/resourceGroups\/(?<resourceGroup>[^\/]+)\/providers\/Microsoft\.Compute\/galleries\/(?<gallery>[^\/]+)\/images\/(?<image>[^\/]+)$'
        $imageVersionResourceIdPattern = '^\/subscriptions\/(?<subscription>[a-z0-9\-]+)\/resourceGroups\/(?<resourceGroup>[^\/]+)\/providers\/Microsoft\.Compute\/galleries\/(?<gallery>[^\/]+)\/images\/(?<image>[^\/]+)\/versions\/(?<version>[^\/]+)$'
        if ($ImageReference.Id -match $imageDefinitionResourceIdPattern) {
            Write-PSFMessage -Level Host -Message 'Image reference is an Image Definition resource.'
            $imageSubscriptionId = $Matches.subscription
            $imageResourceGroup = $Matches.resourceGroup
            $imageGalleryName = $Matches.gallery
            $imageDefinitionName = $Matches.image

            $currentSubscriptionId = (Get-AzContext).Subscription.Id
            # Switch Subscription if needed
            if ($imageSubscriptionId -ne $currentSubscriptionId) {
                Write-PSFMessage -Level Host -Message "Switching to subscription {0}" -StringValues $imageSubscriptionId
                Set-AzContext -SubscriptionId $imageSubscriptionId
            }

            # Get the latest version of the image
            $availableImageVersions = Get-AzGalleryImageVersion -ResourceGroupName $imageResourceGroup -GalleryName $imageGalleryName -GalleryImageName $imageDefinitionName | Where-Object { $_.PublishingProfile.ExcludeFromLatest -eq $false }
            if ($availableImageVersions.Count -eq 0) {
                throw "No available image versions found."
            }
            $latestImageVersion = $availableImageVersions | Select-Object -Last 1
            Write-PSFMessage -Level Host -Message "Selected image version with resource Id {0}" -StringValues $latestImageVersion.Id
            $azImageVersion = $latestImageVersion.Name
            $azImageDate = $latestImageVersion.PublishingProfile.PublishedDate

            Write-PSFMessage -Level Host -Message "Image version is {0} and date is {1}" -StringValues $azImageVersion, $azImageDate.ToString('o')

            # Switch back to original subscription
            if ($imageSubscriptionId -ne $currentSubscriptionId) {
                Write-PSFMessage -Level Host -Message "Switching back to subscription {0}" -StringValues $currentSubscriptionId
                Set-AzContext -SubscriptionId $currentSubscriptionId
            }
        }
        elseif ($ImageReference.Id -match $imageVersionResourceIdPattern ) {
            Write-PSFMessage -Level Host -Message 'Image reference is an Image Version resource.'
            $imageVersion = Get-AzGalleryImageVersion -ResourceId $ImageReference.Id
            $azImageVersion = $imageVersion.Name
            $azImageDate = $imageVersion.PublishingProfile.PublishedDate
            Write-PSFMessage -Level Host -Message "Image version is {0} and date is {1}" -StringValues $azImageVersion, $azImageDate.ToString('o')
        }
        else {
            throw "Image reference Id does not match expected format for an Image Definition resource."
        }
    }
    else {
        throw "Image reference does not contain a publisher or Id property. ImageReference, publisher, and Id are case sensitive!!"
    }
    #return output
    [PSCustomObject]@{
        Version = $azImageVersion
        Date    = $azImageDate
    }
}
