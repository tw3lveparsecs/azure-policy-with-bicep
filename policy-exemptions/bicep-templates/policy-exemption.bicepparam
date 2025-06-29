using 'policy-exemption.bicep'

param managementGroupId = '<management_group_id>'

param managedIdentityName = '<managed_identity_for_deployment_scripts>'

param managedIdentityLocation = '<managed_identity_location>'

param deploymentScriptLocation = '<deployment_script_location>'

param deploymentScriptSubscriptionId = '<deployment_script_subscription_id>'

param deploymentScriptResourceGroupName = '<deployment_script_resource_group_name>'

param exemptions = [
  // subscription level exemption example
  {
    policyExemptionName: 'example-policy-exemption-name'
    displayName: 'Example Policy Exemption Display Name'
    policyExemptionDescription: 'Example policy exemption description'
    exemptionCategory: 'Waiver' // 'Waiver' | 'Mitigated'
    policyAssignmentId: '/subscriptions/example-subscription-id/providers/microsoft.authorization/policyassignments/example-policy-assignment-id'
    policyDefinitionReferenceIds: [
      'examplePolicyDefinitionDisplayName'
    ]
    subscriptionId: 'example-subscription-id'
  }
  // resource level exemption example
  {
    policyExemptionName: 'example-policy-exemption-name-2'
    displayName: 'Example Policy Exemption Display Name 2'
    exemptionCategory: 'Waiver'
    policyAssignmentId: '/subscriptions/example-subscription-id-2/providers/microsoft.authorization/policyassignments/example-policy-assignment-id-2'
    policyDefinitionReferenceIds: [
      'examplePolicyDefinitionDisplayName2'
    ]
    subscriptionId: 'example-subscription-id-2'
    resourceGroupName: 'example-resource-group-name'
    resourceName: 'example-resource-name'
  }
  // management group level exemption example
  {
    policyExemptionName: '<example_policy_exemption_name_3>'
    displayName: '<Example Policy Exemption Display Name 3>'
    exemptionCategory: 'Waiver'
    policyAssignmentId: '/providers/microsoft.management/managementGroups/<example-management-group-id>/providers/microsoft.authorization/policyassignments/<example-policy-assignment-id-3>'
    policyDefinitionReferenceIds: [
      '<examplePolicyDefinitionDisplayName3>'
    ]
    managementGroupId: '<example-management-group-id>'
  }
  // resource group level exemption example
  {
    policyExemptionName: 'example-policy-exemption-name-4'
    displayName: 'Example Policy Exemption Display Name 4'
    exemptionCategory: 'Waiver'
    policyAssignmentId: '/subscriptions/example-subscription-id-3/providers/microsoft.authorization/policyassignments/example-policy-assignment-id-4'
    policyDefinitionReferenceIds: [
      'examplePolicyDefinitionDisplayName4'
    ]
    subscriptionId: 'example-subscription-id-4'
    resourceGroupName: 'example-resource-group-name-4'
  }
]
