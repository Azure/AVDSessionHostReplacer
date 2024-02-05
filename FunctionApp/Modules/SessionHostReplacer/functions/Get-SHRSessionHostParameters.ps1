function Get-SHRSessionHostParameters {
    [CmdletBinding()]
    param (
        #[Parameter()]
        #[string] $SessionHostTemplateParametersPS1Uri = (Get-FunctionConfig _SessionHostTemplateParametersPS1Uri)

        [Parameter()]
        [string] $SessionHostParameters = (Get-FunctionConfig _SessionHostParameters)
    )

    #Write-PSFMessage -Level Host -Message "Downloading template parameter PS1 file from {0} (SAS redacted)" -StringValues ($SessionHostTemplateParametersPS1Uri -replace '\?.+','')
    #$sessionHostParametersPS1 = Invoke-RestMethod -Uri $SessionHostTemplateParametersPS1Uri -ErrorAction Stop

    #Invoke-Expression $sessionHostParametersPS1

    $paramsHash = ConvertFrom-Json $SessionHostParameters -Depth 99 -AsHashtable
    Write-PSFMessage -Level Host -Message "Session host parameters: {0}" -StringValues ($paramsHash | Out-String)
    $paramsHash
}