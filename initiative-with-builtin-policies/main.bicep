// This Bicep file creates an initiative by loading the initiative definition from a JSON file and assigns it to a management group.

targetScope = 'managementGroup'

var initiative = loadJsonContent('locations-initiative.json')

// Create the initiative
resource policySetDefinition 'Microsoft.Authorization/policySetDefinitions@2023-04-01' = {
  name: initiative.name
  properties: {
    policyType: 'Custom'
    displayName: initiative.displayName
    description: initiative.description
    parameters: initiative.parameters
    metadata: {
      category: 'Example'
      version: '1.0.0'
    }
    policyDefinitions: initiative.policyDefinitions
  }
}

// Assign the initiative
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: 'locations-assignment'
  properties: {
    displayName: initiative.displayName
    description: initiative.description
    enforcementMode: 'Default'
    policyDefinitionId: policySetDefinition.id
    parameters: {
      listOfAllowedLocations: {
        value: initiative.parameters.listOfAllowedLocations.defaultValue
      }
    }
  }
}
