

[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Tag,
    [Parameter()]
    [string]
    $GitRef
)

$timeStamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$urlDeployAVDSessionHostReplacer = "https://raw.githubusercontent.com/Azure/AVDSessionHostReplacer/$Tag/deploy/arm/DeployAVDSessionHostReplacer.json" -replace ":", "%3A"  -replace "/", "%2F"
$urlPortalUiUrl = "https://raw.githubusercontent.com/Azure/AVDSessionHostReplacer/$Tag/deploy/portal-ui/portal-ui.json"  -replace ":", "%3A"  -replace "/", "%2F"

$body = @"
ReleaseBody<<EOF
This release is based on $GitRef built on $timeStamp
## Deploy This Release

| Deployment Type           | Link                                                                                                                                                                                                                                                                                                                                                                                                                       |
| :------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Azure Portal UI           | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/$urlDeployAVDSessionHostReplacer/uiFormDefinitionUri/$urlPortalUiUrl) |
| Command line (Bicep/ARM)  | [![Powershell/Azure CLI](./docs/icons/powershell.png)](./docs/CodeDeploy.md)
EOF
"@

$body >> $Env:GITHUB_OUTPUT