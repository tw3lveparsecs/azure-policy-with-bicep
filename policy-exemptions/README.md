# Azure Policy Exemptions

This directory contains examples of deploying Azure Policy exemptions at various scopes including management group, subscription, resource group, and individual resource levels.

## Purpose

The purpose of this repository is to:

- Provide a reusable template for deploying Azure Policy exemptions at different scopes.
- Demonstrate the use of GitHub Actions for CI/CD workflows for policy exemption management.
- Serve as a reference for developers and DevOps engineers working with Azure Policy governance.
- Show how to implement controlled exemptions while maintaining compliance and audit trails.

## Overview

Policy exemptions are used to exclude specific resources from a policy assignment. This is useful when a policy is not applicable to a specific resource or group of resources, or when temporary exceptions are needed for business continuity. You can exempt a management group, subscription, resource group, or individual resource from a policy assignment.

Resource-level exemptions require a deployment script that utilises a managed identity to deploy the exemption. The managed identity is created as part of the policy exemption deployment and is assigned the necessary permissions to deploy the exemption.

## Setup

### 1. Configure Entra ID Application for OIDC Authentication

1. Register an application in Entra ID
2. Set up Federated Credentials for GitHub Actions (see [GitHub Actions Prerequisites](#github-actions-prerequisites) for detailed setup)
3. Grant the application appropriate permissions based on exemption scope (see [Prerequisites](#prerequisites) below)

### 2. Update GitHub Workflow Files

Update the environment variables in the workflow file `.github/workflows/policy-exemptions.yml`:

Replace the placeholders with the actual values:

```yaml
env:
  management_group_id: "<MANAGEMENT_GROUP_ID>"
  oidc_app_reg_client_id: "<OIDC_APP_REG_CLIENT_ID>"
  azure_tenant_id: "<AZURE_TENANT_ID>"
  environment: "<ENVIRONMENT>"
```

## Prerequisites

### Management Group, Subscription, and Resource Group Level Exemptions

To deploy policy exemptions at the management group, subscription, or resource group level, the following permissions are required:

| Name                           | Definition                                           | Permissions                             | Assignment       | Notes                                                                                        |
| :----------------------------- | :--------------------------------------------------- | :-------------------------------------- | :--------------- | :------------------------------------------------------------------------------------------- |
| **`<Service Principal Name>`** | Service principal for deploying policy via pipelines | Role Based Access Control Administrator | Management Group | This is required to create role assignments.                                                 |
|                                |                                                      | Security Admin                          | Management Group | This is required to create deployments and policy assignments at the management group level. |
|                                |

### Resource Level Exemptions

In addition to the Azure Policy service principal permissions specified in the table above, the following permissions are also required to deploy policy exemptions to resource level scope using a deployment script:

- The following permissions are required on a `Resource Group` in a `Subscription within the target Management Group`:

  - `Contributor` - This is required for resource level exemptions, as it needs to create a deployment script and execute code to deploy the exemption.
  - `Managed Identity Contributor` - This is required to create a user assigned managed identity for a deployment script.

- The `Microsoft.ContainerInstance` and `Microsoft.ManagedIdentity` resource provider must also be registered in the subscription where the deployment script will be deployed.

## Repository Structure

```
├── .github/
│   └── workflows/
│       └── policy-exemptions.yml
├── bicep-templates/
│   ├── policy-exemption.bicep
│   ├── policy-exemption.bicepparam
│   └── modules/
│       └── policy-exemption-resource.bicep
└── README.md
```

## Deployment

The repository uses GitHub Actions workflows for deployment:

**Policy Exemptions Deployment**

- Deploys policy exemptions at various scopes (management group, subscription, resource group, or resource level)
- Triggered by changes to files in the `bicep-templates` directory
- Can be manually triggered using workflow_dispatch
- Flexibility to include environment approval for security review

### Manual Deployment

1. Go to the Actions tab in your GitHub repository
2. Select "Policy Exemptions Deployment" workflow
3. Click "Run workflow" and select the branch (typically main)
4. Complete any required approvals if configured

### Automatic Deployment

The workflow will automatically run when changes are pushed to the main branch in the relevant directories.

## Configuration

### Making Changes to Policy Exemptions

To make changes to policy exemptions, simply add or update the required parameters and values to the `policy-exemption.bicepparam` parameter file.

- Once your code is ready to be deployed, commit your changes and push to the repository.
- Raise a pull request to merge your changes into the `main` branch.
- Once the pull request is approved and merged, pipelines will automatically trigger and deploy your updates.

If you need to change the underlying architecture of the deployment you will need to modify the logic in the `policy-exemption.bicep` file.

### Adding a New Exemption

To add an exemption to a policy:

1. Open the [policy-exemption.bicepparam](bicep-templates/policy-exemption.bicepparam) file.
2. Find the `exemptions` parameter and insert the new required exemption. Example below:

```bicep
param exemptions = [
  {
    policyExemptionName: 'exemption-name'
    displayName: 'Exemption Display Name'
    policyExemptionDescription: 'Exemption Description'
    exemptionCategory: 'Waiver'
    policyAssignmentId: '/providers/Microsoft.Management/managementGroups/<management-group-id>/providers/Microsoft.Authorization/policyAssignments/<policy-assignment-id>'
    policyDefinitionReferenceIds:[
      'Policy Definition Display Name'
    ]
    subscriptionId: '00000000-0000-0000-0000-000000000000'
    resourceGroupName: 'Resource Group Name'
    resourceName: 'Resource Name'
  }
]
```

## Customisation

### Exemption Scopes

The template supports exemptions at different scopes:

- **Management Group Level**: Exempts entire management groups from policies
- **Subscription Level**: Exempts entire subscriptions from policies
- **Resource Group Level**: Exempts specific resource groups from policies
- **Resource Level**: Exempts individual resources from policies (requires deployment script)

### Exemption Categories

- **Waiver**: Complete exemption from policy evaluation
- **Mitigated**: Acknowledges alternative compliance methods

### Time-bounded Exemptions

Exemptions can include expiration dates for temporary exceptions that require periodic review.

## CI/CD Integration

### GitHub Actions Integration

Orchestration exists to deploy this pattern via GitHub Actions workflows. The workflow file is located at `.github/workflows/deploy-policy-exemptions.yml`.

### GitHub Actions Prerequisites

In order to authenticate to Azure you are required to configure [OpenID Connect (OIDC)](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure). A guide is available [here](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#github-actions) to configure the app registration in Azure.

When configuring the app registration you will need to setup two federated credentials:

- One with `Entity type` set to `Environment` and set the `GitHub environment name` to `build`.
- The other with `Entity type` set to `Environment` and set the `GitHub environment name` to what is defined in the GitHub workflow, example below.

```yml
on:
  workflow_dispatch:
  push:
    branches:
      - main
    paths:
      - "bicep-templates/**"
  pull_request:
    branches:
      - main
    paths:
      - "bicep-templates/**"

env:
  bicep_template: policy-exemption.bicep
  bicep_template_parameter: policy-exemption.bicepparam
  management_group_id: "<MANAGEMENT_GROUP_ID>"
  oidc_app_reg_client_id: "<OIDC_APP_REG_CLIENT_ID>"
  azure_tenant_id: "<AZURE_TENANT_ID>"
  environment: "<ENVIRONMENT>" # <-- You should set this to the name of the GitHub environment you created for OIDC authentication
  location: australiaeast
  deployment_name: "deploy_policy_exemptions"
  az_deployment_type: "managementgroup"
```

## Recommended Practices

1. **Strategic Use**: Use exemptions judiciously and only when absolutely necessary
2. **Time-Bounded**: Implement expiration dates and regular review cycles for temporary exemptions
3. **Comprehensive Documentation**: Maintain detailed records of business justification and approval in metadata
4. **Approval Workflow**: Establish clear approval processes with appropriate stakeholder involvement
5. **Regular Auditing**: Implement reporting and alerting for exemption lifecycle management
6. **Principle of Least Privilege**: Only exempt specific policies that are absolutely necessary, not entire initiatives when possible
