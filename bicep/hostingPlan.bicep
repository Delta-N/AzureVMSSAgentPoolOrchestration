param name string
param location string = resourceGroup().location

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: name
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}
