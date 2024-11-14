# Welcome to Azure Virtual Desktop (AVD) Session Host Replacer

## Overview

This tool automates the deployment and replacement of session hosts in an Azure Virtual Desktop host pool.

The best practice for AVD recommends replacing the session hosts instead of maintaining them, AVD Session Host Replacer helps you manage the task of replacing old session hosts with new ones automatically.

### AVD Session Host Replacer vs AVD Session Host Update (Preview)

[Session Host Update](https://learn.microsoft.com/en-us/azure/virtual-desktop/session-host-update) is a native feature that enables you to update the session hosts in a host pool. It is currently in preview. Below is a comparison of the two features,

| Point                                               | Session Host Update (Preview)                           | AVD Session Host Replacer                  |
| --------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------ |
| Support                                             | Officially supported by Microsoft (once out of preview) | Community supported (GitHub issues)        |
| Availabilty                                         | Public Cloud Only                                       | All clouds including Gov and China         |
| Entra Join                                          | ❌                                                       | ✅                                          |
| Customize ARM Template for VM deployment            | ❌                                                       | ✅                                          |
| Replacement Order                                   | Remove old VMs > Deploy new VMs                         | * Deploy new VMs > Remove old VMs          |
| Initial test deployment                             | ✅                                                       | * ❌                                        |
| Session Host VM Name                                | Changes after replacement to reflect the date           | Maintains the  names as per defined prefix |
| Change total number of session hosts (scale out/in) | ❌                                                       | ✅                                          |
| Trigger                                             | Based on schedules                                      | Based on criteria (Image Version, VM Age)  |
| Monitoring                                          | Native Azure Diagnostics                                | Function App logging in Log Analytics      |

>\* If you need these feature please use GitHub issues to request them.


## Getting started

### Pre-requisites

The Session Host Replacer requires permissions to manage resources in Azure and, if the session hosts are Entra joined, permissions in Entra. The recommended approach is to create a User Managed Identity, assign the necessary permissions to it, and use it for all instances of the Session Host Replacer.

If you do not select a User Managed Identity, the deployment will create a System Managed Identity and assign permissions to it. However, some additional permissions may need to be assigned manually after deployment. This is not recommended if you have more than one instance of the Session Host Replacer.

Detailed instructions on the required permissions and how to assign them are available [here](docs/Permissions.md).

### Deployment
| Deployment Type           | Link                                                                                                                                                                                                                                                                                                                                                                                                                       |
| :------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Azure Portal UI           | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAVDSessionHostReplacer%2Fv0.3.2%2Fdeploy%2Farm%2FDeployAVDSessionHostReplacer.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAVDSessionHostReplacer%2Fv0.3.2%2Fdeploy%2Fportal-ui%2Fportal-ui.json)  [![Deploy to Azure Gov](https://aka.ms/deploytoazuregovbutton)](https://portal.azure.us/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAVDSessionHostReplacer%2Fv0.3.2%2Fdeploy%2Farm%2FDeployAVDSessionHostReplacer.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAVDSessionHostReplacer%2Fv0.3.2%2Fdeploy%2Fportal-ui%2Fportal-ui.json)  [![Deploy to Azure China](https://aka.ms/deploytoazurechinabutton)](https://portal.azure.cn/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAVDSessionHostReplacer%2Fv0.3.2%2Fdeploy%2Farm%2FDeployAVDSessionHostReplacer.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FAVDSessionHostReplacer%2Fv0.3.2%2Fdeploy%2Fportal-ui%2Fportal-ui.json) |
| Command line (Bicep/ARM)  | [![Powershell/Azure CLI](./docs/icons/powershell.png)](./docs/CodeDeploy.md)  |
| Offline Deployment (no GitHub)  | [![Offline Deployment](./docs/icons/powershell.png)](./docs/CodeDeploy-offline.md) |

## How it works?

There are two criteria for replacing a session host,

1. **Image Version:** Is there a new image version available? If so, we create a new session host with the new image version. This can be from Marketplace or  Gallery Image Definition.
2. **Session Host VM Age:** If the session host is older than a certain age, default is 45 days, we create a new session host and drain the old one.

The core of an AVD Session Host Replacer is an Azure Function App built using PowerShell, the function is triggered every hour to check each session host against the above criteria.

To deploy new session hosts, the function uses an ARM Template that is stored as a Template Spec at deployment time.

When deleting an old session host, the function will check if it has existing sessions and,

1. Place the session host drain mode.
2. Send a notification to all sessions.
3. Add a tag to the session host with a timestamp
4. Delete the session host once there are no sessions or the grace period has passed.
    - Delete VM
    - Remove from Host Pool
    - (If Entra Joined) Delete device from Entra ID

## FAQ

- **Can I use a custom Template Spec for Session Hosts deployment?**

    Yes, you can use a custom Template Spec.
    You can base the customization on the [built-in template](StandardSessionHostTemplate/DeploySessionHosts.bicep) making sure of the following,
        - The template must accept an array parameter for the names of VMs to deploy. The default paramter name is `VMNames` and it can be changed using the parameter `VMNamesTemplateParameterName`.
        - To ensure proper cleanup, the template spec should be configured to delete disk and NICs when deleting the VM.
        - The parameter `SessionHostParameters` is a JSON object that will be passed to the template spec when deploying. The VMNames array will be added to this object. Moreover, it must contain the following properties (case sensitive),
            - `ImageReference`: Can be in the Provider/Offer/SKU or Id format for custom images.
            - `Location`: The region where the session hosts will be deployed. This is used when querying for the latest image version when using marketplace images.

- **I just deployed the Session Host Replacer, now what?

    The Session Host Replacer runs every hour on the hour. You can manually trigger it by going to the FunctionApp > timerTrigger1 > Code+Test.

    During the first run, the Session Host Replacer will download required PowerShell modules from the Internet which can take some time. Subsequent runs will be (much) faster.

- **I changed my mind about some of the settings during deployment or I want to upgrade to the latest version, what should I do?**

    You can simply redeploy the Session Host Replacer with the new settings or version. It will overwrite the existing deployment without any impact.

- **How can I force replace a specific session host?**

    On the VM(s) you want to replace, update the the tag `AutoReplaceDeployTimestamp` to any date older that 45 days. The Session Host Replacer will replace the VM on the next run.

- **What about AVD Scaling Plans?**

    When the Session Host Replacer needs to delete a session host that has users logged in, it will add a tag `ScalingPlanExclusion` to the VM. The name of the tag is configurable and it should be the same as the tag used in the scaling plan.

- **What happens if a deployment fails?**

    The Session host Replacer checks for failed deployments, if any are found it will NOT take any actions. You should clean up the failed deployment by deleting any resources created, Entra Devices, etc... and delete the failed deployment from the deployment history.

- **The Session Host Replacer is failing, how can I get help?**

    While this is a community project and we do not provide direct support, you can open an issue on GitHub and we will do our best to help you. Please make sure to include the logs of failed run by going to FunctionApp > timerTrigger1 > Invocations. Or manually run from Code+Test and copy the logs.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit <https://cla.opensource.microsoft.com>.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
