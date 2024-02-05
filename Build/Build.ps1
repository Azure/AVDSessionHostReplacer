param(
    $SubscriptionId ,
    $ResourceGroupName ,
    $Location ,

    $BicepParams,

    [switch] $AssignPermissions
)
# Validate inputs
if ($StorageAccountName.Length -gt 24) { Throw "StorageAccount name too long" }

# Login in to Azure using the right subscription
$null = Set-AzContext -SubscriptionId $SubscriptionId

#region: Create Azure Resource Group
$null = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force -ErrorAction Stop
Write-PSFMessage -Level Host -Message "Resource group created or already exists"
#endregion

#region: Create ZIP file of the FunctionApp
# I am only testing the zip file functionality, later this should be from GitHub Actions and the file should be stored as part of the release.
$tempFolderPath = '.\temp'
$tempFolder = New-Item -Path $tempFolderPath -ItemType Directory -Force
$zipFilePath = $tempFolder.FullName + "\FunctionApp.zip"
if (Test-Path $zipFilePath) { Remove-Item $zipFilePath -Force }
Compress-Archive -Path .\FunctionApp\* -DestinationPath $tempFolder\FunctionApp.zip -Force -CompressionLevel Optimal
#endregion

#region: Deploy Azure resources using Bicep template

Write-PSFMessage -Level Host -Message "Deploying Azure resources from Bicep template"

$timestamp = Get-Date -Format FileDateTime
$deployParams = @{
    # Cmdlet parameters
    TemplateFile      = ".\Build\Bicep\FunctionApps.bicep"
    Name              = "DeployFunctionApp-$timestamp"
    ResourceGroupName = $ResourceGroupName
}
$deploy = New-AzResourceGroupDeployment @deployParams @BicepParams -Verbose -ErrorAction Stop

Write-PSFMessage -Level Host -Message "Azure resources deployed."

#endregion
