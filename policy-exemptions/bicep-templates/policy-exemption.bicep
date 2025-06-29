targetScope = 'managementGroup'

@description('Creates a policy exemption for a policy assignment.')
param exemptions exemptionsType[] = []

@description('Management group ID.')
param managementGroupId string

@description('The name of the managed identity.')
param managedIdentityName string

@description('The location of the managed identity.')
param managedIdentityLocation string

@description('Optional. The location of the deployment script resource. This is only used when creating a resource exemption.')
param deploymentScriptLocation string = ''

@description('Optional. The subscription ID for the deployment of the deployment script resource. This is only used when creating a resource exemption.')
param deploymentScriptSubscriptionId string = ''

@description('Optional. The resource group name for the deployment of the deployment script resource. This is only used when creating a resource exemption.')
param deploymentScriptResourceGroupName string = ''

var maxExemptionNameLength = 54 // deployment names have a max length limit of 64, this is to allow for the additional characters added to the name

// Create policy exemptions at Management Group level
module policyExemption_mg 'br/public:avm/ptn/authorization/policy-exemption:0.1.1' = [
  for (exemption, i) in exemptions: if (!empty(exemption.?managementGroupId) && empty(exemption.?subscriptionId) && empty(exemption.?resourceGroupName)) {
    name: '${take(exemption.policyExemptionName, maxExemptionNameLength)}-${i}-mg'
    scope: managementGroup(exemption.managementGroupId!)
    params: {
      name: toLower(replace(exemption.policyExemptionName, ' ', '-'))
      displayName: exemption.?displayName ?? ''
      description: exemption.?policyExemptionDescription ?? ''
      metadata: exemption.?metadata ?? {}
      exemptionCategory: exemption.?exemptionCategory!
      policyAssignmentId: exemption.policyAssignmentId
      policyDefinitionReferenceIds: exemption.?policyDefinitionReferenceIds ?? []
      expiresOn: exemption.?expiresOn ?? null
      managementGroupId: exemption.?managementGroupId
    }
  }
]

// Create policy exemptions at Subscription level
module policyExemption_sub 'br/public:avm/ptn/authorization/policy-exemption:0.1.1' = [
  for (exemption, i) in exemptions: if (empty(exemption.?managementGroupId) && !empty(exemption.?subscriptionId) && empty(exemption.?resourceGroupName)) {
    name: '${take(exemption.policyExemptionName, maxExemptionNameLength)}-${i}-sub'
    params: {
      name: toLower(replace(exemption.policyExemptionName, ' ', '-'))
      displayName: exemption.?displayName ?? ''
      description: exemption.?policyExemptionDescription ?? ''
      metadata: exemption.?metadata ?? {}
      exemptionCategory: exemption.exemptionCategory!
      policyAssignmentId: exemption.policyAssignmentId
      policyDefinitionReferenceIds: exemption.?policyDefinitionReferenceIds ?? []
      expiresOn: exemption.?expiresOn ?? null
      subscriptionId: exemption.?subscriptionId
    }
  }
]

// Create policy exemptions at Resource Group level
module policyExemption_rg 'br/public:avm/ptn/authorization/policy-exemption:0.1.1' = [
  for (exemption, i) in exemptions: if (empty(exemption.?managementGroupId) && !empty(exemption.?resourceGroupName) && !empty(exemption.?subscriptionId) && empty(exemption.?resourceName)) {
    name: '${take(exemption.policyExemptionName, maxExemptionNameLength)}-${i}-rg'
    params: {
      name: toLower(replace(exemption.policyExemptionName, ' ', '-'))
      displayName: exemption.?displayName ?? ''
      description: exemption.?policyExemptionDescription ?? ''
      metadata: exemption.?metadata ?? {}
      exemptionCategory: exemption.exemptionCategory!
      policyAssignmentId: exemption.policyAssignmentId
      policyDefinitionReferenceIds: exemption.?policyDefinitionReferenceIds ?? []
      expiresOn: exemption.?expiresOn ?? null
      subscriptionId: exemption.?subscriptionId
      resourceGroupName: exemption.?resourceGroupName
    }
  }
]

// Create a user assigned identity used by a deployment script
module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.1' = {
  scope: resourceGroup(deploymentScriptSubscriptionId, deploymentScriptResourceGroupName)
  name: '${uniqueString(managedIdentityName, managedIdentityLocation)}-umi'
  params: {
    name: managedIdentityName
    location: managedIdentityLocation
  }
}

// Create Resource Policy Contributor role assignment for the user assigned identity used by a deployment script
module policyContribRa 'br/public:avm/ptn/authorization/role-assignment:0.2.2' = {
  scope: managementGroup(managementGroupId)
  name: 'policy-contrib-role-mg-${uniqueString(deployment().name, managedIdentityLocation, managementGroupId, 'Resource Policy Contributor')}'
  params: {
    roleDefinitionIdOrName: 'Resource Policy Contributor'
    principalId: userAssignedIdentity.outputs.principalId
  }
}

// Create Reader role assignment for the user assigned identity used by a deployment script
module ReaderRa 'br/public:avm/ptn/authorization/role-assignment:0.2.2' = {
  scope: managementGroup(managementGroupId)
  name: 'reader-role-mg-${uniqueString(deployment().name, managedIdentityLocation, managementGroupId, 'Reader')}'
  params: {
    roleDefinitionIdOrName: 'Reader'
    principalId: userAssignedIdentity.outputs.principalId
  }
}

// Create policy exemptions at Resource level using a deployment script
@batchSize(1) // This is to cater for policy exemptions that utilise the same name but a different display name as you cant update at the same time
module policyExemption_resource '../modules/policy-exemption-resource.bicep' = [
  for (exemption, i) in exemptions: if (empty(exemption.?managementGroupId) && !empty(exemption.?resourceName) && !empty(exemption.?resourceGroupName) && !empty(exemption.?subscriptionId)) {
    dependsOn: [
      policyContribRa
      ReaderRa
    ]
    name: '${take(exemption.policyExemptionName, maxExemptionNameLength)}-${i}-rsrc'
    scope: resourceGroup(deploymentScriptSubscriptionId, deploymentScriptResourceGroupName)
    params: {
      name: '${toLower(replace(exemption.policyExemptionName, ' ', '-'))}-policy-exemption'
      location: deploymentScriptLocation
      policyExemptionName: toLower(replace(exemption.policyExemptionName, ' ', '-'))
      displayName: exemption.?displayName ?? ''
      policyExemptionDescription: exemption.?policyExemptionDescription ?? ''
      metadata: exemption.?metadata ?? {}
      exemptionCategory: exemption.exemptionCategory!
      policyAssignmentId: exemption.policyAssignmentId
      policyDefinitionDisplayNames: exemption.?policyDefinitionDisplayNames ?? null
      expiresOn: exemption.?expiresOn ?? ''
      subscriptionId: exemption.subscriptionId!
      resourceGroupName: exemption.resourceGroupName!
      resourceName: exemption.resourceName!
      managedIdentityId: userAssignedIdentity.outputs.resourceId
    }
  }
]

@export()
type exemptionsType = {
  @description('Specifies the name of the policy exemption (max 64 characters). Space characters will be replaced by (-) and converted to lowercase.')
  @maxLength(64)
  policyExemptionName: string

  @description('Optional. The display name of the policy exemption.')
  displayName: string?

  @description('Optional. The description of the policy exemption.')
  policyExemptionDescription: string?

  @description('Optional. The policy exemption metadata. Metadata is an open ended object and is typically a collection of key value pairs.')
  metadata: object?

  @description('Optional. The policy exemption category. Possible values are Waiver and Mitigated. Default is Waiver.')
  exemptionCategory: ('Waiver' | 'Mitigated')?

  @description('The ID of the policy assignment that is being exempted.')
  policyAssignmentId: string

  @description('Optional. The reference ids of the policy definitions when the associated policy assignment is an assignment of a policy set definition.')
  policyDefinitionReferenceIds: array?

  @description('Optional. The expiration date and time (in UTC ISO 8601 format yyyy-MM-ddTHH:mm:ssZ) of the policy exemption. e.g. 2021-10-02T03:57:00.000Z.')
  expiresOn: string?

  @description('Optional. The ID of the management group to be exempted from the policy assignment. Cannot use with subscription id property.')
  managementGroupId: string?

  @description('Optional. The ID of the azure subscription to be exempted from the policy assignment. Cannot use with management group id property.')
  subscriptionId: string?

  @description('Optional. The name of the resource group to be exempted from the policy assignment. Must also use the subscription ID property.')
  resourceGroupName: string?

  @description('Optional. The name of the resource to be exempted from the policy assignment. Must also use the resourceGroup and subscription ID property.')
  resourceName: string?
}
