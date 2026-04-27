param name string
param location string
param tags object = {}

param databaseName string = ''
param keyVaultName string

@secure()
param sqlAdminPassword string
@secure()
param appUserPassword string

// because databaseName is optional in main.bicep, we make sure the database name is set here.
var defaultDatabaseName = 'TflSchool'
var actualDatabaseName = !empty(databaseName) ? databaseName : defaultDatabaseName

module sqlServer '../core/database/sqlserver/sqlserver.bicep' = {
  name: 'sqlServer'
  params: {
    name: name
    location: location
    tags: tags
    databaseName: actualDatabaseName
    keyVaultName: keyVaultName
    sqlAdminPassword: sqlAdminPassword
    appUserPassword: appUserPassword
  }
}

output connectionStringKey string = sqlServer.outputs.connectionStringKey
output databaseName string = sqlServer.outputs.databaseName
output sqlServerName string = sqlServer.outputs.sqlServerName
