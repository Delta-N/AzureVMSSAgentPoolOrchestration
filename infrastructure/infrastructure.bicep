
param storageAccountName string
param hostingPlanName string
param applicationInsightsName string
param actionGroupName string
param alertNotificationEmailAddress string

param location string = resourceGroup().location

module storageAccount '../bicep/storageAccount.bicep' = {
  name: 'storageAccount'
  params: {
    name: storageAccountName
    location: location
  }
}

module hostingplan '../bicep/hostingPlan.bicep' = {
  name: 'hostingplan'
  params: {
    name: hostingPlanName
    location: location
  }
}

module applicationinsights '../bicep/applicationInsights.bicep' = {
  name: 'applicationinsights'
  params: {
    name: applicationInsightsName
    location: location
  }
}

module actiongroup '../bicep/actionGroup.bicep' = {
  name: 'actiongroup'
  params: {
    name: actionGroupName
    alertNotificationEmailAddress: alertNotificationEmailAddress
  }
}

module exceptionalert '../bicep/exceptionAlert.bicep' = {
  name: 'exceptionalert'
  dependsOn: [
    applicationinsights
    actiongroup
  ]
  params: {
    applicationInsightsName: applicationInsightsName
    actionGroupName: actionGroupName
    location: location
  }
}
