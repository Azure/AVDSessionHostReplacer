$TemplateFilePath = '.\Build\Bicep\FunctionApps.bicep'

#region: Helper Functions
function ConvertTo-MarkdownTable {
    [CmdletBinding()]
    param (
        [Parameter()]
        [PSObject]
        $InputObject
    )

    $header = $InputObject[0].PSObject.Properties.Name
    $header = "| " + ($header -join " | " ) + " |"

    $headerSeparator = $header -replace "[^\|]", "-"

    $rows = foreach ($row in $InputObject) {
        $row = $row.PSObject.Properties.Value
        $row = "| " + ( $row -join " | ") + " |"
        $row
    }

    (@($header, $headerSeparator) + $rows) -join "`n"

}

#endregion: Helper Functions


# Get the template file
$templateFile = Get-Content -Path $TemplateFilePath

# Extract @description lines
$descriptionLines = $TemplateFile | Where-Object { $_ -like "@description(*" }

# Remove the @description and )' from the end of each line and convert to CSV


# for each description, get its index and extract info
$templateParameters = foreach ($line in $descriptionLines) {
    # Get index of line in template file
    $index = $TemplateFile.IndexOf($line)

    # Get the parameter name and type
    $TemplateFile[$index + 1] -match "param\s+(?<paramName>\w+)\s+(?<paramType>\w+)" | Out-Null
    $paramName = $Matches.paramName
    $paramType = $Matches.paramType

    $descriptionCSV = $line
    | ForEach-Object { $_.Substring(24) }
    | ForEach-Object { $_.TrimEnd("')'") }
    | ConvertFrom-Csv -Delimiter "|" -Header "Required", "Description", "Default"

    [PSCustomObject]@{
        Name        = $paramName
        required    = $descriptionCSV.Required.Trim()
        Description = $descriptionCSV.Description
        Type        = $paramType
        Default     = if ($descriptionCSV.Default) { $descriptionCSV.Default.Substring(9) }
    }


}
ConvertTo-MarkdownTable -InputObject ($templateParameters | Sort-Object -Property Name ) | Set-Clipboard

### Build for AVDMF ###
$ignoreParams = @(
    'ADOrganizationalUnitPath'
    'FunctionAppName'
    'HostPoolName'
    'HostPoolResourceGroupName'
    'Location'
    'LogAnalyticsWorkspaceName'
    'SessionHostNamePrefix'
    'SessionHostParameters'
    'StorageAccountName'
    'SubnetId'
    'SubscriptionId'
    'TargetSessionHostCount'
)
# parameters
$templateParameters | Where-Object {$_.Name -notin $ignoreParams} | Sort-Object required,Name| ForEach-Object {
    $mandatory = if ($_.required -eq "Yes") { '$true' } else { '$false' }
    $default = if ($_.required -eq "No") {' = {0}' -f ($_.Default)  } else { '' }
    @'
    [Parameter(Mandatory = {0} , ValueFromPipelineByPropertyName = $true )]
    [{1}] ${2}{3},
'@ -f $mandatory,$_.Type, $_.Name,$default
} | Set-Clipboard
#registration
$templateParameters | Where-Object {$_.Name -notin $ignoreParams} | Sort-Object required,Name| ForEach-Object {
    '{0} = ${0}' -f $_.Name
}| Set-Clipboard
#bicep file Hostpools.bicep
$templateParameters | Sort-Object required,Name | ForEach-Object {'{0}: ReplacementPlan.{0}' -f $_.Name} | Set-Clipboard