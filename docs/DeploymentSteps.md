# AVD Replacement Plans Deployment Steps
1. Clone repository
2. Run the bicep deployment
3. Assign permissions to the keyvault for domain join account
   1. secret user
   2. deploy action  https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/key-vault-parameter?tabs=azure-cli#grant-deployment-access-to-the-secrets
   3. network contributor permissions (or custom role for /subnets/join)
4. Assign permission on vnet if needed
5. Trigger the function


# Detailed instructions
