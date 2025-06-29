targetScope = 'resourceGroup'

@description('The name of the deployment script.')
param name string

@description('The location of the deployment script.')
param location string

@description('Specifies the name of the policy exemption. Maximum length is 64 characters.')
param policyExemptionName string

@description('Optional. The display name of the policy exemption. Maximum length is 128 characters.')
param displayName string = ''

@description('Optional. The policy exemption description.')
param policyExemptionDescription string = ''

@description('Optional. The policy exemption metadata. Metadata is an open ended object and is typically a collection of key-value pairs.')
param metadata object = {}

@description('The policy exemption category.')
@allowed([
  'Mitigated'
  'Waiver'
])
param exemptionCategory string

@description('The policy assignment ID.')
param policyAssignmentId string

@description('Optional. The policy definition display names.')
param policyDefinitionDisplayNames array = []

@description('Optional. The expiration date of the policy exemption.')
param expiresOn string = ''

@description('The resource group name for the resource.')
param resourceGroupName string

@description('The subscription ID for the resource.')
param subscriptionId string

@description('The resource name.')
param resourceName string

@description('The resource ID of the managed identity.')
param managedIdentityId string

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: name
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'userAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    azPowerShellVersion: '9.7'
    scriptContent: '''
    param(
      [object] $metadata,
      [string] $exemptionCategory,
      [string] $policyAssignmentId,
      [array] $policyDefinitionDisplayNames,
      [string] $subscriptionId,
      [string] $resourceGroupName,
      [string] $resourceName
      )

      if ($subscriptionId) {
        Set-AzContext -Subscription $subscriptionId
      }

      $resource = Get-AzResource -ResourceGroupName $resourceGroupName -ResourceName $resourceName
      $assignment = Get-AzPolicyAssignment -Id $policyAssignmentId

      $arguments = @{
        Name = ${Env:policyExemptionName}
        PolicyAssignment = $assignment
        Scope = $resource.Id
      }
      if (${Env:policyExemptionDescription}) {
        $arguments.Description = ${Env:policyExemptionDescription}
      }
      if (${Env:expiresOn}) {
        $arguments.ExpiresOn = $expiresOn
      }
      if ($policyDefinitionDisplayNames) {
        $policyDefinitionReferenceIds=@()
        foreach ($policy in $policyDefinitionDisplayNames){
          $policyformatted = $policy.replace('[',"").replace(']',"")
          $policyDefinitionReferenceIds+=$policyformatted
        }
        $arguments.PolicyDefinitionReferenceId = $policyDefinitionReferenceIds
      }
      if (${Env:displayName}) {
        $arguments.displayName = ${Env:displayName}
      }
      if ($exemptionCategory) {
        $arguments.exemptionCategory = "Waiver"
      }

      New-AzPolicyExemption @arguments
    '''
    arguments: '-metadata ${metadata} -exemptionCategory ${exemptionCategory} -policyAssignmentId ${policyAssignmentId} -policyDefinitionDisplayNames ${policyDefinitionDisplayNames} -subscriptionId ${subscriptionId} -resourceGroupName ${resourceGroupName} -resourceName ${resourceName}'
    environmentVariables: [
      // the values below are configured as environment variables as parsing as arguments in the script does not parse correctly (when they contain special characters or spaces,etc.)
      {
        name: 'displayName'
        value: displayName
      }
      {
        name: 'policyExemptionName'
        value: policyExemptionName
      }
      {
        name: 'policyExemptionDescription'
        value: policyExemptionDescription
      }
      {
        name: 'expiresOn'
        value: expiresOn
      }
    ]
    timeout: 'PT15M'
    retentionInterval: 'PT1H'
    cleanupPreference: 'Always'
  }
}
