# Permissions
The Session Host Replacer requires permissions to be able to query the host pool and replace the session hosts.
You can either use System Managed Identity, for which the deployment will assign the basic required permissions.
However, we recommend using a User Assigned Managed Identity specially if you have more than one session host replacer as it allows easier management of permissions.

Below we list the required permissions for the Session Host Replacer to work correctly,
## Azure Resource Permissions
The Session Host Replacer requires permissions to query the host pool and replace the session hosts. It also needs to read teh TemplateSpec storing the Session Hosts' ARM template.
When using a System Managed Identity, the deployment will assign the required permissions automatically in Azure as detailed below,
- **Destkop Virtualization Virtual Machine Contributor**
    - This role is required to query the host pool and replace the session hosts. Assign it to the user managed identity at the subscription level for easier management.
    - If using an Azure Computer Gallery in a different subscription make sure the role is assigned to the gallery as well.
    - When using System Managed Identity, the role is automatically assigned at the subscription level. Make sure to assign it to the gallery if using a custom image.
- **Template Spec Reader**
    - This role is required to access the TemplateSpec at deployment time. The session host replacer will create one for each Host Pool you configure. Assign it to the User Managed Identity at the subscription level for easier management.
    - When using System Managed Identity, the role is automatically assigned at the TemplateSpec scope.

## Key Vault Permissions
The Key Vault is used to store domain join password. Make sure the identity has `Key Vault Secret User` and `Key Vault resource manager template deployment operator`, this is required at the Key Vault level.

> This role is not built-in so you will need to create a custom role following the instructions [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/key-vault-parameter?tabs=azure-cli#grant-deployment-access-to-the-secrets).

## Entra Joined VMs
If your session hosts are Entra Joined (not hybrid), the FunctionApp requires permissions in Entra ID in order to delete the devices when deleting session hosts.
Without this cleanup, creating a new session host with the same name will fail. This permission is not assigned automatically and must be assigned to the system or user managed identity.

- **Graph API**
    - **Device.Read.All**: To query Entra ID for devices.
    - **DeviceManagementManagedDevices.ReadWrite.All**: To remove device in Intune.
- **Cloud Device Administrator Role**: To delete the devices from Entra ID.

> Assigning Graph API permissions to a user or system managed identity cannot be done from the portal.

Use the script below to configure the permissions. Make sure to run them with a Global Admin account.
```PowerShell
$FunctionAppSP = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' # The Object ID of the User Managed Identity assigned or the Managed System Identity of the function app.

# Connect to Graph with requires scopes.
Connect-MgGraph -Scopes Application.ReadWrite.All, Directory.ReadWrite.All, AppRoleAssignment.ReadWrite.All,  RoleManagement.ReadWrite.Directory

#region: Assign Device.Read.All
$graphAppId = "00000003-0000-0000-c000-000000000000"
$graphSP = Get-MgServicePrincipal -Search "AppId:$graphAppId" -ConsistencyLevel eventual
$msGraphPermissions = @(
    'Device.Read.All' # To read device in Entra ID
    'DeviceManagementManagedDevices.ReadWrite.All' # To remove device in Intune
)
$msGraphAppRoles = $graphSP.AppRoles | Where-Object { $_.Value -in $msGraphPermissions }

$msGraphAppRoles | ForEach-Object {
    $params = @{
        PrincipalId = $FunctionAppSP
        ResourceId  = $graphSP.Id
        AppRoleId   = $_.Id
    }
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $FunctionAppSP -BodyParameter $params -Verbose
}

# Assign Cloud Device Administrator
$directoryRole = Get-MgRoleManagementDirectoryRoleDefinition -Filter "DisplayName eq 'Cloud Device Administrator'"
New-MgRoleManagementDirectoryRoleAssignment -RoleDefinitionId $directoryRole.Id -PrincipalId $FunctionAppSP  -DirectoryScopeId '/'
```
