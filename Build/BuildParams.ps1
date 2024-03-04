$param = @{
    SubscriptionId    = '89f2b949-44fe-4969-9a1c-f53a85990a5d'
    ResourceGroupName = 'rg-AVDReplaceHost-01'
    Location          = 'WestEurope'
    AssignPermissions = $false
    BicepParams       = @{
        #Storage Account
        StorageAccountName               = 'stavdreplacehost221216'

        #Log Analytics Workspace
        LogAnalyticsWorkspaceName        = 'law-avdreplacehost'

        #FunctionApp
        FunctionAppName                  = 'func-avdreplacementplan-weu-001'
        HostPoolResourceGroupName        = 'rg-AVD-01'
        HostPoolName                     = 'hpool-AVD-WE-D01'
        TagIncludeInAutomation           = 'IncludeInAutoReplace'
        TagDeployTimestamp               = 'AutoReplaceDeployTimestamp'
        TagPendingDrainTimestamp         = 'AutoReplacePendingDrainTimestamp'
        TargetVMAgeDays                  = 120
        DrainGracePeriodHours            = 24
        FixSessionHostTags               = $true
        SHRDeploymentPrefix              = "AVDSessionHostReplacer"
        TargetSessionHostCount           = 3
        MaxSimultaneousDeployments       = 2
        SessionHostNamePrefix            = "AVD-WE-D01" #Azure Virtual Desktop - West Europe - FullDesktop Host Pool 01
        SessionHostTemplate              = "URI or Template Spec Resource Id HERE"
        ADOrganizationalUnitPath         = "PATH HERE"
        #SessionHostTemplateParametersPS1Uri = "URIHere"
        SubnetId                         = "SUBNET ID HERE"
        SessionHostInstanceNumberPadding = 2 # This results in a session host name like AVD-WE-D01-01,02,03

        # Session Host Parameters
        SessionHostParameters            = @{
            VMSize                = 'Standard_D4ds_v5'
            TimeZone              = 'GMT Standard Time'
            AdminUsername         = 'AVDAdmin'

            AvailabilityZone      = '1' #TODO Distribute on AZs if supported

            AcceleratedNetworking = $true

            Tags                  = @{}

            ImageReference        = @{
                publisher = 'MicrosoftWindowsDesktop'
                offer     = 'Windows-11'
                sku       = 'win11-22h2-avd'
                version   = 'latest'
            }

            WVDArtifactsURL       = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip'

            #Domain Join
            DomainJoinObject      = @{
                DomainType = 'ActiveDirectory' # ActiveDirectory or AzureActiveDirectory
                DomainName = 'contoso.com'
                OUPath     = Get-FunctionConfig _ADOrganizationalUnitPath
                UserName   = 'AVDDomainJoin'
            }
            DomainJoinPassword    = @{
                reference = @{
                    keyVault = @{
                        id         = 'KEYVAULT RESOURCE ID'
                        secretName = 'AVDDomainJoin'
                    }
                }
            }
        }
    }
}
.\Build\Build.ps1 @param -Verbose