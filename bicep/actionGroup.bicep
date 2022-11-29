param name string
param alertNotificationEmailAddress string

resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: name
  location: 'global'
  properties: {
    emailReceivers: [
      {
        emailAddress: alertNotificationEmailAddress
        name: 'Email notification'
        useCommonAlertSchema: true
      }
    ]
    enabled: true
    groupShortName: 'ag-devops'
  }
}
