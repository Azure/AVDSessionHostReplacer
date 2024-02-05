$functionParameters = PSFramework\Import-PSFPowerShellDataFile -Path .\FunctionApp\FunctionParameters.psd1
$bicepFunctionAppTemplate = {
    [ordered]@{
        _description = "Required: {0} - {1}" -f $_.Value.Required, $_.Value.Description
        name  = $_.name
        value = $_.Value.Type
    }
}
$json = $functionParameters.GetEnumerator() | foreach { if ($_.Value.Required) {. $bicepFunctionAppTemplate} } | ConvertTo-Json
$json -replace '"_description": "(.+)",','// $1' | scb
