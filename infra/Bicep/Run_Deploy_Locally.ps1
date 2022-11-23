# To deploy this main.bicep manually:
# az login
# az account set --subscription <subscriptionId>
az deployment group create -n main-deploy-20221013T153000Z --resource-group rg-logappstd-demo --template-file 'main.bicep' --parameters appPrefix=lll environment=demo appName=logicappstd keyVaultOwnerUserId=xxxxx