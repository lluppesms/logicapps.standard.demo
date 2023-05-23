// --------------------------------------------------------------------------------
// Logic Apps Standard - Main Bicep File
// --------------------------------------------------------------------------------
param appName string = 'logic-std-demo'
@allowed(['azd','gha','azdo','dev','demo','design','qa','stg','ct','prod'])
param environmentCode string = 'demo'
param location string = 'eastus'
param keyVaultOwnerUserId string = ''

param runDateTime string = utcNow()

// --------------------------------------------------------------------------------
var deploymentSuffix = '-${runDateTime}'
var commonTags = {         
  LastDeployed: runDateTime
  Application: appName
  Environment: environmentCode
}

var svcBusQueueOrders = 'orders-received'
var svcBusQueueERP =  'orders-to-d365' 

// --------------------------------------------------------------------------------
module resourceNames 'resourcenames.bicep' = {
  name: 'resourcenames${deploymentSuffix}'
  params: {
    appName: appName
    environmentCode: environmentCode
  }
}

// --------------------------------------------------------------------------------
module blobStorageAccountModule 'storageaccount.bicep' = {
  name: 'storage${deploymentSuffix}'
  params: {
    storageAccountName: resourceNames.outputs.blobStorageAccountName
    blobStorageConnectionName: resourceNames.outputs.blobStorageConnectionName
    location: location
    commonTags: commonTags
    storageAccessTier: 'Hot'
    allowBlobPublicAccess: true
  }
}

module servicebusModule 'servicebus.bicep' = {
  name: 'servicebus${deploymentSuffix}'
  params: {
    serviceBusName: resourceNames.outputs.serviceBusName
    queueNames: [ svcBusQueueOrders, svcBusQueueERP ]
    location: location
    commonTags: commonTags
  }
}


module logAnalyticsModule 'loganalyticsworkspace.bicep' = {
  name: 'logAnalytics${deploymentSuffix}' 
  params: {
    logAnalyticsWorkspaceName: resourceNames.outputs.logAnalyticsWorkspaceName
    location: location
    commonTags: commonTags
  }
}

module logicAppServiceModule 'logicappservice.bicep' = {
  name: 'logicappservice${deploymentSuffix}'
  params: {
    logicAppServiceName:  resourceNames.outputs.logicAppServiceName
    logicAppStorageAccountName: resourceNames.outputs.logicAppStorageAccountName
    logicAnalyticsWorkspaceId: logAnalyticsModule.outputs.id
    location: location
    commonTags: commonTags
  }
}

module storageAccountRoleModule 'storageaccountroles.bicep' = {
  name: 'storageaccountroles${deploymentSuffix}' 
  params: {
    logicAppServiceName: logicAppServiceModule.outputs.name
    storageAccountName: blobStorageAccountModule.outputs.name
    logicAppServicePrincipalId: logicAppServiceModule.outputs.principalId
    blobStorageConnectionName: blobStorageAccountModule.outputs.blobStorageConnectionName
    location: location
    environmentCode: environmentCode
  }
}

module keyVaultModule 'keyvault.bicep' = {
  name: 'keyvault${deploymentSuffix}'
  params: {
    keyVaultName: resourceNames.outputs.keyVaultName
    adminUserObjectIds: [ keyVaultOwnerUserId ]
    applicationUserObjectIds: [ logicAppServiceModule.outputs.principalId ]
    location: location
    commonTags: commonTags
  }
}

module keyVaultSecret1 'keyvaultsecretstorageconnection.bicep' = {
  name: 'keyVaultSecret1${deploymentSuffix}'
  dependsOn: [ keyVaultModule, blobStorageAccountModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'BlobStorageConnectionString'
    storageAccountName: blobStorageAccountModule.outputs.name
  }
}
module keyVaultSecret2 'keyvaultsecretservicebusconnection.bicep' = {
  name: 'keyVaultSecret2${deploymentSuffix}'
  dependsOn: [ keyVaultModule, servicebusModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'ServiceBusReceiveConnectionString'
    serviceBusName: servicebusModule.outputs.name
    accessKeyName: 'listen'
  }
}

module keyVaultSecret3 'keyvaultsecretservicebusconnection.bicep' = {
  name: 'keyVaultSecret3${deploymentSuffix}'
  dependsOn: [ keyVaultModule, servicebusModule ]
  params: {
    keyVaultName: keyVaultModule.outputs.name
    keyName: 'ServiceBusSendConnectionString'
    serviceBusName: servicebusModule.outputs.name
    accessKeyName: 'send'
  }
}

module logicAppSettingsModule 'logicappsettings.bicep' = {
  name: 'logicAppSettings${deploymentSuffix}'
  params: {
    logicAppName: logicAppServiceModule.outputs.name
    logicAppStorageAccountName: logicAppServiceModule.outputs.storageResourceName
    logicAppInsightsKey: logicAppServiceModule.outputs.insightsKey
    customAppSettings: {
      BLOB_CONNECTION_RUNTIMEURL: blobStorageAccountModule.outputs.connectionRuntimeUrl
      BLOB_STORAGE_CONNECTION_NAME: blobStorageAccountModule.outputs.blobStorageConnectionName
      BLOB_STORAGE_ACCOUNT_NAME: blobStorageAccountModule.outputs.name
      STORAGE_ACCOUNT_NAME: blobStorageAccountModule.outputs.name
      WORKFLOWS_SUBSCRIPTION_ID: subscription().subscriptionId
      WORKFLOWS_RESOURCE_GROUP_NAME: resourceGroup().name
      WORKFLOWS_LOCATION_NAME: location
      BlobStorageConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=BlobStorageConnectionString)'
      ServiceBusReceiveConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=ServiceBusReceiveConnectionString)'
      ServiceBusSendConnectionString: '@Microsoft.KeyVault(VaultName=${keyVaultModule.outputs.name};SecretName=ServiceBusSendConnectionString)'
    }
  }
}
