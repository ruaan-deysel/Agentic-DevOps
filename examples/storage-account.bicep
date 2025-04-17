@description('The name of the storage account')
param storageAccountName string = 'st${uniqueString(resourceGroup().id)}'

@description('The location for the storage account')
param location string = resourceGroup().location

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
@description('The SKU for the storage account')
param sku string = 'Standard_LRS'

@description('The kind of storage account')
@allowed([
  'StorageV2'
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
])
param kind string = 'StorageV2'

@description('Enable or disable blob encryption at rest')
param enableBlobEncryption bool = true

@description('Enable or disable file encryption at rest')
param enableFileEncryption bool = true

@description('Enable or disable https traffic only')
param enableHttpsTrafficOnly bool = true

@description('Tags for the resource')
param tags object = {
  environment: 'development'
  project: 'Nucleus'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: sku
  }
  kind: kind
  properties: {
    supportsHttpsTrafficOnly: enableHttpsTrafficOnly
    encryption: {
      services: {
        blob: {
          enabled: enableBlobEncryption
        }
        file: {
          enabled: enableFileEncryption
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
  tags: tags
}

output storageAccountId string = storageAccount.id
output storageAccountName string = storageAccount.name
