@{
    _Tag_IncludeInAutomation                      = @{Required = $false ; Type = 'string'  ; Default = 'IncludeInAutoReplace'             ; Description = '' }
    _Tag_DeployTimestamp                          = @{Required = $false ; Type = 'string'  ; Default = 'AutoReplaceDeployTimestamp'       ; Description = '' }
    _Tag_PendingDrainTimestamp                    = @{Required = $false ; Type = 'string'  ; Default = 'AutoReplacePendingDrainTimestamp' ; Description = '' }
    _Tag_ScalingPlanExclusionTag                  = @{Required = $false ; Type = 'string'  ; Default = 'ScalingPlanExclusion'             ; Description = '' }
    _TargetVMAgeDays                              = @{Required = $false ; Type = 'int   '  ; Default = 45                                 ; Description = 'Automatically replaces the session hosts when they are older than X number of days even if there is no new image. The default is 45 days. Setting this value to 0 disables the feature.' }
    _DrainGracePeriodHours                        = @{Required = $false ; Type = 'int   '  ; Default = 24                                 ; Description = '' }
    _FixSessionHostTags                           = @{Required = $false ; Type = 'bool  '  ; Default = $true                              ; Description = '' }
    _SHRDeploymentPrefix                          = @{Required = $false ; Type = 'string'  ; Default = 'AVDSessionHostReplacer'           ; Description = '' }
    _MaxSimultaneousDeployments                   = @{Required = $false ; Type = 'int   '  ; Default = 100                                ; Description = 'Deprecated.This allows multiple deployments running simultaneously. Might change later to control maximum number of VMNames to deploy. Or control it using batches in template, or both!.' }
    _AllowDownsizing                              = @{Required = $false ; Type = 'bool  '  ; Default = $true                              ; Description = '' }
    _SessionHostInstanceNumberPadding             = @{Required = $false ; Type = 'int   '  ; Default = 2                                  ; Description = '' }
    _ReplaceSessionHostOnNewImageVersion          = @{Required = $false ; Type = 'bool  '  ; Default = $true                              ; Description = '' }
    _ReplaceSessionHostOnNewImageVersionDelayDays = @{Required = $false ; Type = 'int   '  ; Default = 0                                  ; Description = '' }
    _VMNamesTemplateParameterName                 = @{Required = $false ; Type = 'string'  ; Default = 'VMNames'                          ; Description = 'The name of the array parameter used in the Session Host deployment template to define the VM names. Default is "VMNames"' }
    _SessionHostResourceGroupName                 = @{Required = $false ; Type = 'string'  ; Default = ''                                 ; Description = 'Use this if you want to deploy VMs in a different Resource Group. By default it will be the same Resource Group as Host Pool' }
    _HostPoolResourceGroupName                    = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _HostPoolName                                 = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _TargetSessionHostCount                       = @{Required = $true  ; Type = 'int'                                                    ; Description = '' }
    _SessionHostNamePrefix                        = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _SessionHostTemplate                          = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _SessionHostParameters                        = @{Required = $true  ; Type = 'hashtable'                                              ; Description = '' }
    _SubscriptionId                               = @{Required = $true  ; Type = 'string'                                                 ; Description = '' }
    _RemoveAzureADDevice                          = @{Required = $true  ; Type = 'bool'                                                   ; Description = 'When deleting a session host, will also delete the Azure AD Device record. This is required for Azure AD Joined Session Hosts' }
}
