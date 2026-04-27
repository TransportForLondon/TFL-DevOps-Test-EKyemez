param name string
//param dashboardName string
param location string
param tags object = {}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

/* module applicationInsightDashboard 'applicationInsights-dashboard.bicep' = {
  name: 'application-insight-dashboard'
  params: {
    name: dashboardName
    location: location
    applicationInsightsName: applicationInsights.name
  }
} */

output connectionString string = applicationInsights.properties.ConnectionString
output instrumentationKey string = applicationInsights.properties.InstrumentationKey
output name string = applicationInsights.name
