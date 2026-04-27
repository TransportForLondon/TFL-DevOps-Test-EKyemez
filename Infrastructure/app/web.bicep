param name string
param location string
param tags object = {}
param serviceName string = 'web'
param appCommandLine string = ''
param applicationInsightsName string = ''
param appServicePlanId string = ''
param appSettings object = {}

module web '../core/host/appService.bicep' = {
  name: '${name}-deployment'
  params: {
    name: name
    location: location
    appCommandLine: appCommandLine
    applicationInsightsName: applicationInsightsName
    appServicePlanId: appServicePlanId
    appSettings: appSettings
    runtimeName: 'dotnetcore'
    runtimeVersion: '8.0'
    tags: union(tags, { 'azd-service-name': serviceName})
    scmDoBuildDuringDeploymentBool: false
  }
}

output SERVICE_WEB_IDENTITY_PRINCIPAL_ID string = web.outputs.identityPrincipalId
output SERVICE_WEB_NAME string = web.outputs.name
output SERVICE_WEB_URI string = web.outputs.uri
output SERVICE_WEB_HOSTNAME string = web.outputs.hostName
