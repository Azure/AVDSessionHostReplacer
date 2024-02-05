function Connect-SHRGraphAPI {
    $resourceURI = "https://graph.microsoft.com"
    $tokenAuthURI = $env:IDENTITY_ENDPOINT + "?resource=$resourceURI&api-version=2019-08-01"
    $tokenResponse = Invoke-RestMethod -Method Get -Headers @{"X-IDENTITY-HEADER" = "$env:IDENTITY_HEADER" } -Uri $tokenAuthURI
    $mgToken = $tokenResponse.access_token
    Write-PSFMessage -Level Host -Message "Trying to connect to Graph API using managed identity..."
    $null = Connect-MgGraph -AccessToken $mgToken -ErrorAction Stop
    Write-PSFMessage -Level Host -Message "Connected to Graph API!"
}