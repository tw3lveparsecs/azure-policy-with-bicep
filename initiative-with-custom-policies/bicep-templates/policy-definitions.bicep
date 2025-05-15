targetScope = 'managementGroup'

@description('Required. Policy definition files to be deployed.')
param policyFiles array

module policyDefinition 'create-custom-policy-definition.bicep' = [
  for definition in policyFiles: {
    name: 'policy-definition-${uniqueString(deployment().name, definition.name)}'
    params: {
      name: definition.name
      description: definition.description
      displayName: definition.displayName
      mode: definition.mode
      metadata: definition.metadata
      parameters: definition.parameters
      policyRule: definition.policyRule
    }
  }
]
