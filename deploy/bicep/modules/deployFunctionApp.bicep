/*
This solution is made up of:
1- AppServicePlan - Used to host all functions
2- Azure Function: AVDSessionHostReplacer
4- StorageAccount - To store FunctionApp
5- LogAnalyticsWorkspace - Used to store Logs, and AppService insights
*/

//------ Parameters ------//
@description('Required: No | Region of the Function App. This does not need to be the same as the location of the Azure Virtual Desktop Host Pool. | Default: Location of the resource group.')
param Location string = resourceGroup().location

//Log Analytics Workspace
param EnableMonitoring bool = true
param UseExistingLAW bool = false
@description('Required: Yes | Name of the Log Analytics Workspace used by the Function App Insights.')
param LogAnalyticsWorkspaceId string = 'none'

//FunctionApp
@description('Required: Yes | Name of the Function App.')
param FunctionAppName string

@description('Required: No | URL of the FunctionApp.zip file. This is the zip file containing the Function App code. | Default: The latest release of the Function App code.')
param FunctionAppZipUrl string = 'https://github.com/Azure/AVDSessionHostReplacer/releases/download/v0.3.0/FunctionApp.zip'

@description('Required: No | App Service Plan Name | Default: Y1 for consumption based plan')
param AppPlanName string = 'Y1'

@description('Required: No | App Service Plan Tier | Default: Dynamic for consumption based plan')
param AppPlanTier string = 'Dynamic'

@description('''Required: Yes | The following settings are mandatory. Rest are optional.
[
  {
    name: '_HostPoolResourceGroupName'
    value: 'string'
  }
  {
    name: '_HostPoolName'
    value: 'string'
  }
  {
    name: '_RemoveEntraDevice'
    value: 'bool'
  }
  {
    name: '_SessionHostTemplate'
    value: 'string'
  }
  {
    name: '_SessionHostParameters'
    value: 'hashtable'
  }
  {
    name: '_SubscriptionId'
    value: 'string'
  }
  {
    name: '_TargetSessionHostCount'
    value: 'int'
  }
  {
    name: '_SessionHostNamePrefix'
    value: 'string'
  }
]''')
param ReplacementPlanSettings array

param FunctionAppIdentity object = {
  type: 'SystemAssigned'
}

//-------//

//------ Variables ------//
var varFunctionAppSettings = [
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'powershell'
  }
  {
    name: 'AzureWebJobsStorage'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
  }
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsights.properties.InstrumentationKey
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: toLower(FunctionAppName)
  }
]
var varAppInsightsKey = EnableMonitoring ? [
  {
    name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
    value: appInsights.properties.InstrumentationKey
  }
] : []
var varFunctionAppSettingsAndReplacementPlanSettings = union(varFunctionAppSettings, varAppInsightsKey, ReplacementPlanSettings)

var varStorageAccountName = 'stavdrpfunc${uniqueString(FunctionAppName)}'
var varLogAnalyticsWorkspaceName = '${FunctionAppName}-law'
var varAppServicePlanName = '${FunctionAppName}-asp'
//-------//

//------ Resources ------//

// Deploy Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: varStorageAccountName
  location: Location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    // TODO: Discuss securing the storage account (firewall)
  }
}

// Deploy or use Log Analytics Workspace
resource deployLogAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = if (EnableMonitoring && !UseExistingLAW) {
  name: varLogAnalyticsWorkspaceName
  location: Location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Deploy App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: varAppServicePlanName
  location: Location
  sku: {
    name: AppPlanName
    tier: AppPlanTier
  }
}

// Deploy App Insights for App Service Plan
resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (EnableMonitoring) {
  name: varAppServicePlanName
  location: Location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    WorkspaceResourceId: UseExistingLAW ? LogAnalyticsWorkspaceId : deployLogAnalyticsWorkspace.id
  }
}

// Create ReplaceSessionHost function with Managed System Identity (MSI)
resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: FunctionAppName
  location: Location
  kind: 'functionApp'
  identity: FunctionAppIdentity
  properties: {
    httpsOnly: true
    serverFarmId: appServicePlan.id
    siteConfig: {
      use32BitWorkerProcess: false
      powerShellVersion: '7.2'
      netFrameworkVersion: 'v6.0'
      appSettings: varFunctionAppSettingsAndReplacementPlanSettings
      ftpsState: 'Disabled'
      cors: {
        allowedOrigins: [ 'https://portal.azure.com' ]
      }
    }
  }
  resource deployFromZip 'extensions@2023-01-01' = {
    name: 'MSDeploy'
    properties: {
      packageUri: FunctionAppZipUrl
    }
  }
}

//----- Outputs ------//
output functionAppPrincipalId string = FunctionAppIdentity.type == 'SystemAssigned'? functionApp.identity.principalId : ''
