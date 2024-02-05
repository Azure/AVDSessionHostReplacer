# Welcome to Azure Virtual Desktop (AVD) Replacement Plans

## Overview

This tool automates the deployment and replacement of session hosts in an Azure Virtual Desktop host pool.

The best practice for AVD recommends replacing the session hosts instead of maintaining them,
the AVD Replacement Plans helps you automate the task of replacing old session hosts with new ones automatically.

# Getting started

You can deploy using Bicep. This will create,

1. **Function App**
2. **App Service Plan:** Consumption tier. Used to host the function.
3. **Storage Account:** Utilized by the function App
4. **Log Analytics Workspace:** Used to store Logs and AppService insights

| Deployment Type    | Link                                                                                                                                                                                                                                                                                                                                                                                                                       |
| :----------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Azure Portal UI    | [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2FWillyMoselhy%2FAVDReplacementPlans%2Fmain%2Fportal-ui%2Fportal-deploy.json/uiFormDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2FWillyMoselhy%2FAVDReplacementPlans%2Fmain%2Fportal-ui%2Fportal-ui.json) |
| PowerShell (Bicep) | [![Powershell/Azure CLI](./docs/icons/powershell.png)](./docs/bicepDeploy.md)

## How it works?

It follows a very simple logic,

- Query the host pool for existing session hosts
- How many session hosts are newer than X number of days?
  - Greater than X => Remove the old ones.
  - Less than X => Deploy new ones.

The core of an AVD Replacement Plan is an Azure Function App built using PowerShell.

When deploying, the function uses a template and a parameters PowerShell file for the session host. A sample is available [here](SampleSessionHostTemplate).

When deleting an old session host, the function will check if it has existing sessions and,

1. Place the session host drain mode.
2. Send a notification to all sessions.
3. Add a tag to the session host with a timestamp
4. Delete the session host once there are no sessions or the grace period has passed.


## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

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
