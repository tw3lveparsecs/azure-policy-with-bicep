targetScope = 'managementGroup'

@sys.description('Required. The name of the policy initiative. Maximum length is 64 characters.')
@maxLength(64)
param initiativeName string

@sys.description('Required. The display name of the policy initiative. Maximum length is 128 characters.')
@maxLength(128)
param displayName string

@sys.description('Required. The policy initiative description. Maximum length is 256 characters.')
@maxLength(256)
param description string

@sys.description('Optional. The custom policy definitions to include in the initiative. The policy definition must be created in the management group specified by the managementGroupId parameter.')
param customPolicyIds array = []

@sys.description('Required. The management group ID where the policy definitions are stored.')
param policyDefinitionManagementGroupId string

var builtInPolicies = [
  {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/405c5871-3e91-4644-8a63-58e19d68ff5b' // Azure Key Vault should disable public network access
    parameters: {}
  }
  {
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/a4af4a39-4135-47fb-b175-47fbdf85311d' // App Service apps should only be accessible over HTTPS
    parameters: {}
  }
]

var customPolicyReferences = [
  for policy in customPolicyIds: {
    policyDefinitionId: '/providers/Microsoft.Management/managementGroups/${policyDefinitionManagementGroupId}/providers/Microsoft.Authorization/policyDefinitions/${policy.name}'
  }
]

var allPolicyReferences = concat(builtInPolicies, customPolicyReferences)

resource policyInitiative 'Microsoft.Authorization/policySetDefinitions@2025-01-01' = {
  name: initiativeName
  properties: {
    displayName: displayName
    description: description
    policyType: 'Custom'
    metadata: {
      category: 'Security'
      version: '1.0.0'
    }
    policyDefinitions: allPolicyReferences
  }
}

output initiativeId string = policyInitiative.id
