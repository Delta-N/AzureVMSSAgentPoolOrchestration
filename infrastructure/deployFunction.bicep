param imageName string
param hostingPlanName string
param storageAccountName string
param applicationInsightsName string
param functionNamePrefix string

param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' existing = {
  name: storageAccountName
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' existing = {
  name: hostingPlanName
}

module functionApp '../bicep/functionApp.bicep' = {
  name: 'functionApp'
  params: {
    name: '${functionNamePrefix}${imageName}'
    hostingPlanId: hostingPlan.id
    location: location
  }
}

// Create-Update the webapp app settings.
module appSettings '../bicep/appSettings.bicep' = {
  name: '${functionNamePrefix}${imageName}-appsettings'
  params: {
    webAppName: '${functionNamePrefix}${imageName}'
    // Get the current appsettings
    currentAppSettings: list(resourceId('Microsoft.Web/sites/config', '${functionNamePrefix}${imageName}', 'appsettings'), '2022-03-01').properties
    appSettings: {
      FUNCTIONS_EXTENSION_VERSION: '~7'
      FUNCTIONS_WORKER_RUNTIME: 'powershell'
      AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
      WEBSITE_CONTENTSHARE: imageName
      WEBSITE_RUN_FROM_PACKAGE: '1'
      APPINSIGHTS_INSTRUMENTATIONKEY: applicationInsights.properties.InstrumentationKey
    }
  }
}
