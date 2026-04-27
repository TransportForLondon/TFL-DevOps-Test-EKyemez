param name string
param location string
param tags object = {}
param serviceName string = 'dataupload'
param applicationInsightsName string = ''
param appServicePlanId string
param appSettings object = {}

module functionApp '../core/host/appService.bicep' = {
  name: '${name}-function-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    kind: 'functionapp,linux'
    applicationInsightsName: applicationInsightsName
    appServicePlanId: appServicePlanId
    runtimeName: 'powershell'
    runtimeVersion: '7.4'
    runtimeNameAndVersion: 'PowerShell|7.4'
    scmDoBuildDuringDeploymentBool: false
    appSettings: union(appSettings, {
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'powershell'
      WEBSITE_RUN_FROM_PACKAGE: '1'
    })
  }
}

output SERVICE_FUNCTION_NAME string = functionApp.outputs.name
output SERVICE_FUNCTION_URI string = functionApp.outputs.uri
output SERVICE_FUNCTION_HOSTNAME string = functionApp.outputs.hostName
