# Account Setup Guide

This guide provides step-by-step instructions for creating resources in a new MD Pre-Production account using Terraform and CloudFormation templates.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform and Terragrunt installed
- Access to the `Cognitech-terraform-iac-modules` repository
- PowerShell or Bash terminal

## Step 1: Initialize Account with CloudFormation Templates

Before deploying any Terraform resources, you must first run the CloudFormation templates to initialize the account.

### 1.1 Navigate to CloudFormation Templates

```powershell
cd path/to/Cognitech-terraform-iac-modules/Cloudformation/Initializing-account-for-terraform
```

### 1.2 Deploy CloudFormation Stack

Run the CloudFormation templates in the following order:

1. **S3 Backend Stack** - Creates Terraform state buckets and DynamoDB table
2. **IAM Roles Stack** - Creates necessary IAM roles for Terraform execution
3. **Network Prerequisites Stack** - Sets up basic networking prerequisites

> **Note**: Make note of the following outputs from the CloudFormation deployment:
>
> - S3 bucket names for Terraform state (primary and secondary regions)
> - DynamoDB table name for state locking

## Step 2: Update CIDR Range Configuration

### 2.1 Update Primary Region CIDR Ranges

Edit `locals-cidr-range-use1.hcl` in the root deployments directory:

```powershell
# Open the file
code ../../locals-cidr-range-use1.hcl
```

Add or update the CIDR block configuration for your new account:

```hcl
locals {
  cidr_blocks = {
    # ... existing configurations ...
  
    mdpp = {  # Your account abbreviation (e.g., mdpp for md-preproduction)
      segments = {
        tgw_attachment = "tgw-attach-XXXXXXXXXXXXXXXXX" # Update after account creation
        Account_cidr   = "10.X.0.0/16"  # Update with assigned CIDR range
        shared-services = {
          vpc = "10.X.2.0/24"
          public_subnets = {
            sbnt1 = {
              primary   = "10.X.2.0/27"
              secondary = "10.X.2.32/27"
            }
            sbnt2 = {
              primary   = "10.X.2.64/27"
              secondary = "10.X.2.96/27"
            }
          }
          private_subnets = {
            sbnt1 = {
              primary   = "10.X.2.128/27"
              secondary = "10.X.2.160/27"
            }
            sbnt2 = {
              primary   = "10.X.2.192/27"
              secondary = "10.X.2.224/27"
            }
          }
        }
        app_vpc = {
          development = {
            vpc = "10.X.1.0/24"
            # ... subnet configurations
          }
          training = {
            vpc = "10.X.4.0/24"
            # ... subnet configurations
          }
          system-int = {
            vpc = "10.X.5.0/24"
            # ... subnet configurations
          }
        }
      }
    }
  }
}
```

### 2.2 Update Secondary Region CIDR Ranges

Edit `locals-cidr-range-usw2.hcl` with the same structure but for the US-West-2 region:

```powershell
# Open the file
code ../../locals-cidr-range-usw2.hcl
```

## Step 3: Update Environment Configuration

### 3.1 Edit Local Environment File

Update the `locals-env.hcl` file with your account-specific information:

```powershell
code locals-env.hcl
```

Update the following key parameters:

```hcl
locals {
  # Account abbreviation - change to match your new account
  name_abr = "mdpp"  # Example: md-preproduction = "mdpp"
  
  # Environment details
  environment = "md-preprod"  # Update as needed
  
  # Remote state configuration - UPDATE THESE WITH CFN OUTPUTS
  remote_state_bucket = {
    primary   = "your-new-account-us-east-1-network-config-state"
    secondary = "your-new-account-us-west-2-network-config-state"
  }
  
  # DynamoDB table - UPDATE WITH CFN OUTPUT
  remote_dynamodb_table = "terragrunt-lock-table"
  
  # Other configurations...
}
```

### 3.2 Key Parameters to Update:

| Parameter                         | Description                          | Example                         |
| --------------------------------- | ------------------------------------ | ------------------------------- |
| `name_abr`                      | Account name abbreviation            | `"mdpp"` for md-preproduction |
| `environment`                   | Environment name                     | `"md-preprod"`                |
| `remote_state_bucket.primary`   | S3 bucket for primary region state   | Created by CFN template         |
| `remote_state_bucket.secondary` | S3 bucket for secondary region state | Created by CFN template         |
| `remote_dynamodb_table`         | DynamoDB table for state locking     | Created by CFN template         |

## Step 4: Deploy Shared Services

### 4.1 Navigate to Shared Account Directory

```powershell
cd Shared-account/primary
```

### 4.2 Initialize and Deploy

```powershell
# Initialize Terragrunt
terragrunt init

# Plan the deployment
terragrunt plan

# Apply the configuration
terragrunt apply
```

### 4.3 Deploy Secondary Region (if applicable)

```powershell
cd ../secondary
terragrunt init
terragrunt plan
terragrunt apply
```

> **Important**: Shared services must be deployed successfully before proceeding to tenant accounts as they have dependencies on shared resources.

## Step 5: Deploy Tenant Account Environments

Once shared services are deployed, you can create tenant account environments (Dev, Trn, Sit, etc.).

### 5.1 Update Tenant Account Configurations

For each tenant account environment, update lines 34 and 35 in their respective `terragrunt.hcl` files:

#### Development Environment

```powershell
# Navigate to Dev environment
cd Tenant-account/Dev/primary
code terragrunt.hcl
```

Update lines 34-35:

```hcl
## Updates these variables as per the product/service
vpc_name     = "development"
vpc_name_abr = "dev"
```

#### Training Environment

```powershell
cd ../../../Trn/primary
code terragrunt.hcl
```

Update lines 34-35:

```hcl
## Updates these variables as per the product/service
vpc_name     = "training"
vpc_name_abr = "trn"
```

#### System Integration Environment (if applicable)

```powershell
cd ../../../Sit/primary
code terragrunt.hcl
```

Update lines 34-35:

```hcl
## Updates these variables as per the product/service
vpc_name     = "system-integration"
vpc_name_abr = "sit"
```

### 5.2 Deploy Each Tenant Environment

For each environment (Dev, Trn, Sit):

```powershell
# Navigate to the environment directory
cd Tenant-account/{Environment}/primary

# Initialize and deploy
terragrunt init
terragrunt plan
terragrunt apply

# Deploy secondary region if needed
cd ../secondary
terragrunt init
terragrunt plan
terragrunt apply
```

## Step 6: Create GitHub Actions Workflow for Automated Deployment

After setting up the infrastructure configurations, create a GitHub Actions workflow for automated deployments.

### 6.1 Create Workflow File

Navigate to the workflows directory and create a new workflow file following the naming convention:

```powershell
cd ../../../.github/workflows
```

Create a new workflow file named `deploy-primary-md-preproduction-{service}.yaml` (replace `{service}` with your specific service name).

### 6.2 Configure Workflow Template

Use an existing workflow as a template (e.g., `deploy-primary-md-production-shared-account.yaml`) and update the following specific lines:

| Line Number | Description | Update Required |
|-------------|-------------|----------------|
| Line 1 | Workflow name | Change to match your service |
| Line 8 | Workflow file path trigger | Update path to match new workflow filename |
| Line 9 | Terraform deployment path trigger | Update to match your deployment path |
| Line 26 | IAM Role ARN | Update account ID and role name for md-preproduction |
| Line 28 | Deployment path environment variable | Update to your specific deployment path |
| Line 107 | IAM Role ARN (Apply job) | Update account ID and role name for md-preproduction |
| Line 109 | Deployment path (Apply job) | Update to your specific deployment path |
| Line 151 | IAM Role ARN (Destroy job) | Update account ID and role name for md-preproduction |
| Line 153 | Deployment path (Destroy job) | Update to your specific deployment path |

### 6.3 Example Updates for MD Pre-Production

For md-preproduction account, update the following:

```yaml
# Line 1: Update workflow name
name: Deploy-primary-md-preproduction-{your-service}

# Lines 8-9: Update trigger paths
paths:
  - ".github/workflows/deploy-primary-md-preproduction-{your-service}.yaml"
  - "Terraform/deployments/md-preproduction/{Your-Service-Path}/**/*"

# Lines 26, 107, 151: Update IAM role (replace account ID)
IAM_ROLE: arn:aws:iam::533267408704:role/md-preprod-OIDCGitHubRole-role

# Lines 28, 109, 153: Update deployment path
DEPLOYMENT_PATH: Terraform/deployments/md-preproduction/{Your-Service-Path}
```

### 6.4 Required Updates Summary

| Component | Current (Production) | Update to (Pre-Production) |
|-----------|---------------------|----------------------------|
| Account ID | `388927731914` | `533267408704` |
| Role Name | `md-prod-OIDCGitHubRole-role` | `md-preprod-OIDCGitHubRole-role` |
| Environment | `md-production` | `md-preproduction` |
| Deployment Path | `md-production/...` | `md-preproduction/...` |

### 6.5 Run Deployment via GitHub Actions

Once the workflow is created and committed:

1. **Commit and Push Changes:**
   ```powershell
   git add .
   git commit -m "Add GitHub Actions workflow for md-preproduction deployment"
   git push origin main
   ```

2. **Trigger Manual Deployment:**
   - Navigate to your GitHub repository
   - Go to **Actions** tab
   - Select your new workflow
   - Click **Run workflow**
   - Choose the action: `plan`, `apply`, or `destroy`
   - Click **Run workflow** to execute

3. **Monitor Deployment:**
   - Watch the workflow execution in real-time
   - Review logs for any errors or warnings
   - Verify successful completion before proceeding

### 6.6 Workflow Security Considerations

- Workflows use OpenID Connect (OIDC) for secure AWS authentication
- Production deployments require manual approval
- All secrets are stored securely in GitHub repository secrets
- Workflows are triggered automatically on relevant file changes

## Step 7: Validation and Testing

### 7.1 Verify Resource Creation

1. Check AWS Console for created resources
2. Verify VPC and subnet configurations
3. Confirm Transit Gateway attachments
4. Test connectivity between environments

### 7.2 State File Verification

```powershell
# Check state file location
terragrunt state list
```

## Step 8: GitHub Actions Deployment Verification

### 8.1 Verify Workflow Execution

1. **Check Workflow Status:**
   - Navigate to GitHub repository → Actions tab
   - Verify workflow completed successfully
   - Review execution logs for any warnings

2. **Validate Infrastructure Changes:**
   - Compare planned vs actual resources
   - Verify all expected resources were created
   - Check resource tags and naming conventions

3. **Test Automated Triggers:**
   - Make a small configuration change
   - Commit and push to trigger automatic workflow
   - Verify that only affected resources are updated

## Common Account Abbreviations

| Account Type               | Abbreviation | Example Environment |
| -------------------------- | ------------ | ------------------- |
| MD Pre-Production          | `mdpp`     | md-preprod          |
| MD Production              | `mdp`      | md-prod             |
| Integration Pre-Production | `intpp`    | int-preprod         |
| Network                    | `ntw`      | network             |

## Troubleshooting

### Common Issues:

1. **State Bucket Access Denied**

   - Verify CloudFormation templates deployed successfully
   - Check IAM permissions for Terraform execution role
2. **CIDR Block Conflicts**

   - Ensure CIDR ranges don't overlap with existing accounts
   - Verify Transit Gateway route table configurations
3. **Resource Dependencies**

   - Always deploy Shared-account before Tenant-account environments
   - Check that shared services are in a healthy state
4. **Transit Gateway Attachment Issues**

   - Update `tgw_attachment` ID in CIDR configuration after account setup
   - Verify cross-account sharing permissions

## Support

For additional support or questions:

- Review the Terraform modules documentation
- Check CloudFormation stack events for deployment issues
- Consult with the infrastructure team for account-specific configurations

---

**Note**: Always test deployments in a development environment before applying to production accounts.
