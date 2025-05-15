# Azure Policy Initiative with Custom Policies

This directory contains examples of deploying custom Azure Policy definitions and initiatives to a management group.

## Purpose

The purpose of this repository is to:

- Provide a reusable template for deploying Azure Policy definitions and initiatives.
- Demonstrate the use of GitHub Actions for CI/CD workflows.
- Serve as a reference for developers and DevOps engineers working with Azure Policy.

## Setup

### 1. Configure Entra ID Application for OIDC Authentication

1. Register an application in Azure AD
2. Set up Federated Credentials for GitHub Actions
3. Grant the application Contributor access at the management group level

### 2. Update GitHub Workflow Files

Update the environment variables in both workflow files:

- `.github/deploy-custom-policy-definitions.yml`
- `.github/deploy-custom-policy-initiative.yml`

Replace the placeholders with the actual values:

```yaml
env:
  management_group_id: "<MANAGEMENT_GROUP_ID>"
  oidc_app_reg_client_id: "<OIDC_APP_REG_CLIENT_ID>"
  azure_tenant_id: "<AZURE_TENANT_ID>"
  environment: "<ENVIRONMENT>"
```

## Deployment

The repository uses two GitHub Actions workflows for deployment:

1. **Custom Policy Definitions Deployment**

   - Deploys individual custom policy definitions
   - Triggered by changes to files in the `policy-definitions` directory
   - Can be manually triggered using workflow_dispatch

2. **Custom Policy Initiative Deployment**
   - Deploys a policy initiative that references the custom policies
   - Triggered by changes to files in the `policy-initiatives` directory
   - Requires the custom policy definitions to be deployed first
   - Can be manually triggered using workflow_dispatch

### Deployment Order

For a complete deployment:

1. First deploy the custom policy definitions
2. Then deploy the policy initiative

### Manual Deployment

1. Go to the Actions tab in your GitHub repository
2. Select "Custom Policy Definition Deployment" workflow
3. Click "Run workflow" and select the branch (typically main)
4. After completion, run the "Custom Policy Initiative Deployment" workflow

### Automatic Deployment

The workflows will automatically run when changes are pushed to the main branch in the relevant directories.

## Repository Structure

```
├── .github/
│   ├── deploy-custom-policy-definitions.yml
│   └── deploy-custom-policy-initiative.yml
├── bicep-templates/
│   ├── create-custom-policy-definition.bicep
│   ├── policy-definitions.bicep
│   └── policy-definitions.bicepparam
├── policy-definitions/
│   └── [custom policy JSON files]
└── policy-initiatives/
    ├── security-initiative.bicep
    └── security-initiative.bicepparam
```

## Customisation

### Adding New Custom Policies

1. Add the policy definition JSON file to the `policy-definitions` directory
2. Update the `policy-definitions.bicep` and `.bicepparam` files to include the new policy
3. Commit and push the changes

### Modifying the Initiative

1. Edit the `policy-initiatives/security-initiative.bicep` file to modify the initiative
2. Update parameters in the corresponding `.bicepparam` file if needed
3. Commit and push the changes
