### Generates a json string of all standard time zones and copies it to the clipboard ###

$standardTimeZones = Get-TimeZone -ListAvailable
$headerNames = @(
    @{
        l='label'
        e={$_.DisplayName}
    }
    #@{
    #    l='description'
    #    e={$_.Id}
    #}
    @{
        l='value'
        e={$_.Id}
    }
)
$standardTimeZones | Select-Object -Property $headerNames | ConvertTo-Json | Set-Clipboard