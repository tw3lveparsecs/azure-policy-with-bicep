using './security-initiative.bicep'

param initiativeName = 'security-baseline-initiative'
param displayName = 'Organisation Security Baseline'
param description = 'Security baseline requirements for organisational compliance'
param customPolicyIds = [
  loadJsonContent('../policy-definitions/definition.function.app.https.only.json')
  loadJsonContent('../policy-definitions/definition.resource.lock.rgs.json')
]
param policyDefinitionManagementGroupId = 'example-management-group-id'
