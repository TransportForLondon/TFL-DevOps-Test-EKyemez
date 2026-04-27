param applicationInsightsName string
//param applicationInsightsDashboardName string
param location string
param tags object = {}

module applicationInsights 'applicationInsights.bicep' = {
  name: 'applicationInsights'
  params: {
    name: applicationInsightsName
    location: location
    tags: tags
    //dashboardName: applicationInsightsDashboardName
  }
}

output applicationInsightsConnectionString string = applicationInsights.outputs.connectionString
output applicationInsightsInstrumentationKey string = applicationInsights.outputs.instrumentationKey
output applicationInsightsName string = applicationInsights.outputs.name
