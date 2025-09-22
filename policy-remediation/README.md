# Azure Policy Remediation

This directory contains examples of deploying Azure Policy remediation tasks at various scopes including management group, subscription, and resource group levels.

## Purpose

The purpose of this repository is to:

- Provide a reusable template for deploying Azure Policy remediation tasks at different scopes.
- Demonstrate the use of GitHub Actions for CI/CD workflows for policy remediation management.
- Serve as a reference for developers and DevOps engineers working with Azure Policy governance.
- Show how to implement automated compliance remediation while maintaining audit trails and governance standards.

## Overview

Policy remediation is the process of fixing non-compliant resources to ensure they adhere to defined policies. In Azure, policies are used to enforce organisational standards and to assess compliance at-scale. When resources are found to be non-compliant, remediation actions can be taken to bring them into compliance.

This solution creates and runs policy remediation tasks for Azure Policy assignments. The script reads a JSON file that contains the policy assignments to remediate and the associated parameters, then creates and runs the remediation tasks for each policy assignment.

## Setup

### 1. Configure Entra ID Application for OIDC Authentication

1. Register an application in Entra ID
2. Set up Federated Credentials for GitHub Actions
3. Grant the application appropriate permissions based on remediation scope

### 2. Update GitHub Workflow Files

Update the environment variables in the workflow file `.github/workflows/policy-remediations.yml`:

Replace the placeholders with the actual values:

```yaml
env:
  management_group_id: "<MANAGEMENT_GROUP_ID>"
  oidc_app_reg_client_id: "<OIDC_APP_REG_CLIENT_ID>"
  azure_tenant_id: "<AZURE_TENANT_ID>"
  environment: "<ENVIRONMENT>"
```

## Prerequisites

### Management Group, Subscription, and Resource Group Level Remediation

To deploy policy remediation tasks at the management group, subscription, or resource group level, the following permissions are required:

| Name                           | Definition                                           | Permissions                 | Assignment       | Notes                                                           |
| :----------------------------- | :--------------------------------------------------- | :-------------------------- | :--------------- | :-------------------------------------------------------------- |
| **`<Service Principal Name>`** | Service principal for deploying policy via pipelines | Resource Policy Contributor | Management Group | This is required to create and manage policy remediation tasks. |

## Repository Structure

```
├── .github/
│   └── workflows/
│       └── policy-remediations.yml
├── policy-remediations.json
├── policy-remediations.ps1
└── README.md
```

## Deployment

The repository uses GitHub Actions workflows for deployment:

**Policy Remediation Deployment**

- Deploys policy remediation tasks at various scopes (management group, subscription, resource group)
- Triggered by changes to files in the policy remediation directory
- Can be manually triggered using workflow_dispatch
- Flexibility to include environment approval for security review

### Manual Deployment

1. Go to the Actions tab in your GitHub repository
2. Select "Policy Remediations Deployment" workflow
3. Click "Run workflow" and select the branch (typically main)
4. Complete any required approvals if configured

### Automatic Deployment

The workflow will automatically run when changes are pushed to the main branch in the relevant directories.

## Configuration

### Making Changes to Policy Remediation

To make changes to policy remediation, simply add or update the required parameters and values to the `policy-remediations.json` parameter file.

- Once your code is ready to be deployed, commit your changes and push to the repository.
- Raise a pull request to merge your changes into the `main` branch.
- Once the pull request is approved and merged, pipelines will automatically trigger and deploy your updates.

If you need to change the underlying architecture of the deployment you will need to modify the logic in the `policy-remediations.ps1` file.

### Adding a New Remediation Task

To add a remediation task for a policy:

1. Open the [policy-remediations.jsonc](policy-remediations.jsonc) file.
2. Find the remediation tasks array and insert the new required remediation task. Example below:

```json
{
  "name": "application_name Tag - Require a tag on the resource group",
  "managementGroup": "microsoft-mg",
  "policyAssignmentId": "/providers/microsoft.management/managementgroups/microsoft-mg/providers/microsoft.authorization/policyassignments/pltf-govern-tags-asgmt",
  "policyDefinitionReferenceId": "require a tag on the resource group (tag#6)"
}
```
