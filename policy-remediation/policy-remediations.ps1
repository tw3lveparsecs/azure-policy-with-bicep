<#
.SYNOPSIS
  A script that is used to create and run policy remediation tasks for Azure Policy assignments.

.DESCRIPTION
  A script that is used to create and run policy remediation tasks for Azure Policy assignments.
  The script reads a JSON file that contains the policy assignments to remediate and the associated parameters.
  The script will then create and run the remediation tasks for each policy assignment.
  The script will output the results of the remediation tasks to the console.

.PARAMETER remediationFile
  Path to the JSON file that contains the policy assignments to remediate and the associated parameters.

.NOTES
  Dependencies:
    The account running this script is assumed to be logged in with an Azure PowerShell context and must have at least:
      - Resource Policy Contributor
#>

[CmdletBinding()]
param (
  [Parameter(Mandatory)]
  [string] $remediationFile
)

begin {
  # Import policies to remediate from JSON file
  $remediations = Get-Content -Path $remediationFile | ConvertFrom-Json
}

process {
  # Policy Remediation
  foreach ($remediation in $remediations) {
    Write-Host "------------------------------------------"
    # Create arguments for Start-AzPolicyRemediation
    $arguments = @{
      Name                  = ($remediation.name + " - " + (Get-Date -Format "yyyyMMddHHmmss"))
      PolicyAssignment      = $remediation.policyAssignmentId
      ResourceDiscoveryMode = "ReEvaluateCompliance"
    }
      
    if ($remediation.managementGroup) {
      $arguments.managementGroup = $remediation.managementGroup
      $arguments.ResourceDiscoveryMode = "ExistingNonCompliant"

    }
    if ($remediation.subscriptionId) {
      Set-AzContext -Subscription $remediation.subscriptionId | Out-Null
    }
    if ($remediation.resourceGroup) {
      $arguments.ResourceGroupName = $remediation.resourceGroup
    }
    if ($remediation.policyDefinitionReferenceId) {
      $arguments.PolicyDefinitionReferenceId = $remediation.policyDefinitionReferenceId
    }
    # Start remediation task
    try {
      $pa = Get-AzPolicyAssignment -Id $arguments.PolicyAssignment -ErrorAction Stop
      if ($pa) {
        Write-Host "Starting remediation task for: $($arguments.Name)"
        Start-AzPolicyRemediation @arguments
      }
    }
    # Catch any exceptions
    catch {
      Write-Host "Failed to create policy remediation task $($arguments.Name)"
      Write-Error $error[0].Exception.Message
    }
  }
  Write-Host "------------------------------------------"
}