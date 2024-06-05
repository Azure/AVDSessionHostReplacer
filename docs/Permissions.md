# Permissions
The Session Host Replacer requires permissions to be able to query the host pool and replace the session hosts.
You can either use System Managed Identity, for which the deployment will assign the basic required permissions.
However, we recommend using a User Assigned Managed Identity specially if you have more than one session host replacer as it allows easier management of permissions.

Below we list the required permissions for the Session Host Replacer to work correctly,
## Azure Resource Permissions
Assign the Desktop Virtualization Virtual Machine Contributor role to the resource group or subscription where the host pool is located, this is assigned automatically for System Managed Identity.
If you are using a User Assigned Managed Identity, you will need to assign this role manually. Additionally, if you are using a custom image from a compute gallery in a different subscription, make sure to assign the same permission against it.

## Key Vault Permissions
The Key Vault is used to store domain join password. Make sure the identity has `Key Vault Secret User` and `Key Vault resource manager template deployment operator`, this is required at the Key Vault level.

> This role is not built-in so you will need to create a custom role following the instructions [here](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/key-vault-parameter?tabs=azure-cli#grant-deployment-access-to-the-secrets).

## Entra Joined VMs
If your session hosts are Entra Joined (not hybrid), the FunctionApp requires permissions in Entra ID in order to delete the devices when deleting session hosts.
Without this cleanup, creating a new session host with the same name will fail. This permission is not assigned automatically and must be assigned to the system or user managed identity.

- **Graph API: Device.Read.All**, this is required to query Entra ID for devices.
- **Cloud Device Administrator Role**, this role is required to delete the devices from Entra ID. Assigning Graph API permissions to a system managed identity cannot be done from the portal.

You use the script below to configure the permissions. Make sure to run them with a Global Admin account.
```PowerShell
$FunctionAppSP = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx' # The ID of the system managed identity of the function app or the user assigned managed identity you created.

# Connect to Graph with requires scopes.
Connect-MgGraph -Scopes Application.ReadWrite.All, Directory.ReadWrite.All, AppRoleAssignment.ReadWrite.All,  RoleManagement.ReadWrite.Directory

#region: Assign Device.Read.All
$graphAppId = "00000003-0000-0000-c000-000000000000"
$graphSP = Get-MgServicePrincipal -Search "AppId:$graphAppId" -ConsistencyLevel eventual
$msGraphPermissions = @(
    'Device.Read.All' #Used to read user and group permissions
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
