function Get-SHRTemplateSpecVersionResourceId {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResourceId
    )
    $azResourceType = (Get-AzResource -ResourceId $ResourceId -ErrorAction Stop).ResourceType
    Write-PSFMessage -Level Host -Message "Resource type: {0}" -StringValues $azResourceType
    switch ($azResourceType) {
        'Microsoft.Resources/templateSpecs' {
            # Get resource Id of the latest version of the template spec
            $templateSpecVersions = (Get-AzTemplateSpec -ResourceId $ResourceId -ErrorAction Stop).Versions
            Write-PSFMessage -Level Host -Message "Template Spec has {0} versions" -StringValues $templateSpecVersions.count

            $latestVersion = $templateSpecVersions | Sort-Object -Property CreationTime -Descending -Top 1
            Write-PSFMessage -Level Host -Message "Latest version: {0} Created at {1} - Returning Resource Id {2}" -StringValues $latestVersion.Name,$latestVersion.CreationTime.ToString('o'),$latestVersion.Id

            $latestVersion.Id
        }
        'Microsoft.Resources/templateSpecs/versions' {
            # Return the resource Id as is, since supplied value is already a version.
            $ResourceId
        }
        Default {
            throw ("Supplied value has type '{0}' is not a valid Template Spec or Template Spec version resource Id." -f $azResourceType)
        }
    }
}
