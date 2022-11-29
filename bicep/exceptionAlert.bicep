param applicationInsightsName string
param actionGroupName string
param location string = resourceGroup().location

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' existing = {
  name: actionGroupName
}

resource exceptionAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'Alert for Exceptions within Azure Functions'
  location: 'global'
  properties: {
    description: 'Exceptions > 1'
    severity: 1
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT30M'
    autoMitigate: true
    targetResourceType: 'microsoft.insights/components'
    targetResourceRegion: location
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Azure VM Scale Set Pool Auto scaling function encountered more than 1 error in the last 30 minutes.'
          metricName: 'exceptions/count'
          operator: 'GreaterThan'
          threshold: 0
          timeAggregation: 'Count'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}
