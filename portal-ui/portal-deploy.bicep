//------ Parameters ------//
@description('Required: No | Region of the Function App. This does not need to be the same as the location of the Azure Virtual Desktop Host Pool. | Default: Location of the resource group.')
param Location string = resourceGroup().location

//FunctionApp
@description('Required: Yes | Name of the Function App.')
param FunctionAppName string



//Monitoring
param EnableMonitoring bool = true
param UseExistingLAW bool = false
@description('Required: Yes | Name of the Log Analytics Workspace used by the Function App Insights.')
param LogAnalyticsWorkspaceId string = 'none'

//Optional Parameters//
@description('Required: No | Name of the resource group containing the Azure Virtual Desktop Host Pool. | Default: The resource group of the Function App.')
param HostPoolResourceGroupName string = resourceGroup().name

@description('Required: Yes | Name of the Azure Virtual Desktop Host Pool.')
param HostPoolName string

@description('Required: Yes | Prefix used for the name of the session hosts.')
param SessionHostNamePrefix string

@description('Required: Yes | Number of session hosts to maintain in the host pool.')
param TargetSessionHostCount int

@description('Required: Yes | URI or Template Spec Resource Id of the arm template used to deploy the session hosts.')
param SessionHostTemplate string

@description('Required: Yes | A compressed (one line) json string containing the parameters of the template used to deploy the session hosts.')
param SessionHostParameters string

param RemoveAzureADDevice bool = false

@description('Required: No | Tag name used to indicate that a session host should be included in the automatic replacement process. | Default: IncludeInAutoReplace.')
param TagIncludeInAutomation string = 'IncludeInAutoReplace'

@description('Required: No | Tag name used to indicate the timestamp of the last deployment of a session host. | Default: AutoReplaceDeployTimestamp.')
param TagDeployTimestamp string = 'AutoReplaceDeployTimestamp'

@description('Required: No | Tag name used to indicate drain timestamp of session host pending deletion. | Default: AutoReplacePendingDrainTimestamp.')
param TagPendingDrainTimestamp string = 'AutoReplacePendingDrainTimestamp'

@description('Required: No | Tag name used to exclude session host from Scaling Plan activities. | Default: ScalingPlanExclusion')
param TagScalingPlanExclusionTag string = 'ScalingPlanExclusion'

@description('Required: No | Target age of session hosts in days. | Default:  45 days.')
param TargetVMAgeDays int = 45

@description('Required: No | Grace period in hours for session hosts to drain before deletion. | Default: 24 hours.')
param DrainGracePeriodHours int = 24

@description('Required: No | If true, will apply tags for Include In Auto Replace and Deployment Timestamp to existing session hosts. This will not enable automatic deletion of existing session hosts. | Default: True.')
param FixSessionHostTags bool = true

@description('Required: No | Prefix used for the deployment name of the session hosts. | Default: AVDSessionHostReplacer')
param SHRDeploymentPrefix string = 'AVDSessionHostReplacer'

@description('Required: No | Allow deleting session hosts if count exceeds target. | Default: true')
param AllowDownsizing bool = true

@description('Required: No | Number of digits to use for the instance number of the session hosts (eg. AVDVM-01). | Default: 2')
param SessionHostInstanceNumberPadding int = 2

@description('Required: No | If true, will replace session hosts when a new image version is detected. | Default: true')
param ReplaceSessionHostOnNewImageVersion bool = true

@description('Required: No | Delay in days before replacing session hosts when a new image version is detected. | Default: 0 (no delay).')
param ReplaceSessionHostOnNewImageVersionDelayDays int = 0

@description('Required: No | The name of the parameter in the template that specifies the VM Names array.')
param VMNamesTemplateParameterName string = 'VMNames'

@description('Required: No | Leave this empty to deploy to same resource group as the host pool.')
param SessionHostResourceGroupName string = ''

/////////////////

//---- Variables ----//

var varReplacementPlanSettings = [
  // Required Parameters //
  {
    name: '_HostPoolResourceGroupName'
    value: HostPoolResourceGroupName
  }
  {
    name: '_HostPoolName'
    value: HostPoolName
  }
  {
    name: '_TargetSessionHostCount'
    value: TargetSessionHostCount
  }
  {
    name: '_SessionHostNamePrefix'
    value: SessionHostNamePrefix
  }
  {
    name: '_SessionHostTemplate'
    value: SessionHostTemplate
  }
  {
    name: '_SessionHostParameters'
    value: string(SessionHostParameters)
  }
  {
    name: '_SubscriptionId'
    value: subscription().subscriptionId
  }
  {
    name: '_RemoveAzureADDevice'
    value: RemoveAzureADDevice
  }

  // Optional Parameters //
  {
    name: '_Tag_IncludeInAutomation'
    value: TagIncludeInAutomation
  }
  {
    name: '_Tag_DeployTimestamp'
    value: TagDeployTimestamp
  }
  {
    name: '_Tag_PendingDrainTimestamp'
    value: TagPendingDrainTimestamp
  }
  {
    name: '_Tag_ScalingPlanExclusionTag'
    value: TagScalingPlanExclusionTag
  }
  {
    name: '_TargetVMAgeDays'
    value: TargetVMAgeDays
  }
  {
    name: '_DrainGracePeriodHours'
    value: DrainGracePeriodHours
  }
  {
    name: '_FixSessionHostTags'
    value: FixSessionHostTags
  }
  {
    name: '_SHRDeploymentPrefix'
    value: SHRDeploymentPrefix
  }
  {
    name: '_AllowDownsizing'
    value: AllowDownsizing
  }
  {
    name: '_SessionHostInstanceNumberPadding'
    value: SessionHostInstanceNumberPadding
  }
  {
    name: '_ReplaceSessionHostOnNewImageVersion'
    value: ReplaceSessionHostOnNewImageVersion
  }
  {
    name: '_ReplaceSessionHostOnNewImageVersionDelayDays'
    value: ReplaceSessionHostOnNewImageVersionDelayDays
  }
  {
    name: '_VMNamesTemplateParameterName'
    value: VMNamesTemplateParameterName
  }
  {
    name: '_SessionHostResourceGroupName'
    value: SessionHostResourceGroupName
  }
]

//---- Modules ----//
module FunctionApp 'modules/deployFunctionApp.bicep' = {
  name: 'deployFunctionApp'
  params: {
    Location: Location
    FunctionAppName: FunctionAppName
    EnableMonitoring: EnableMonitoring
    UseExistingLAW: UseExistingLAW
    LogAnalyticsWorkspaceId: LogAnalyticsWorkspaceId
    ReplacementPlanSettings: varReplacementPlanSettings
  }
}
