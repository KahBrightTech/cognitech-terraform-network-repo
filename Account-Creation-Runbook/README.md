# Account Creation Runbook

This runbook provides a step-by-step guide for provisioning a new account in the Cognitech infrastructure. It covers CloudFormation prerequisite deployment, Terraform template configuration, Ansible Automation Platform setup, and workflow execution.

> **Prerequisites:** Ensure you have AWS CLI access with appropriate permissions, a Red Hat subscription with an active Ansible Automation Platform entitlement, and access to the Cognitech Terraform network repository.

---

## Step 1: Deploy CloudFormation Prerequisite Stacks

Use the CloudFormation templates located in `Account-Creation-Runbook/01-CFN-Prereqs` to provision the required infrastructure prerequisites. Stacks must be deployed to both the primary region (`us-east-1`) and the secondary region (`us-west-2`).

### 1.1 — Primary Region (`us-east-1`)

**Deploy SSM Parameters**

Update all parameter values in `primary-region-cfn-stacks/ssm-parameter.yaml` to reflect the new account, then deploy the stack.

**Bash:**
```bash
aws cloudformation create-stack \
  --stack-name account-parameters \
  --template-body file://Cloudformation/Initializing-account-for-terraform/primary-region-cfn-stacks/ssm-parameter.yaml \
  --region us-east-1
```

**PowerShell:**
```powershell
aws cloudformation create-stack `
  --stack-name account-parameters `
  --template-body file://Cloudformation/Initializing-account-for-terraform/primary-region-cfn-stacks/ssm-parameter.yaml `
  --region us-east-1
```

**Deploy Account Creation Prerequisites**

Once the parameter stack completes, deploy the main prerequisite stack.

**Bash:**
```bash
aws cloudformation create-stack \
  --stack-name account-creation-prereqs \
  --template-body file://Cloudformation/Initializing-account-for-terraform/primary-region-cfn-stacks/account-creation-prereqs.yaml \
  --region us-east-1
```

**PowerShell:**
```powershell
aws cloudformation create-stack `
  --stack-name account-creation-prereqs `
  --template-body file://Cloudformation/Initializing-account-for-terraform/primary-region-cfn-stacks/account-creation-prereqs.yaml `
  --region us-east-1
```

### 1.2 — Secondary Region (`us-west-2`)

**Deploy SSM Parameters**

Update the parameter values in `secondary-region-cfn-stacks/ssm-parameter.yaml` for the new account, then deploy.

**Bash:**
```bash
aws cloudformation create-stack \
  --stack-name account-parameters \
  --template-body file://Cloudformation/Initializing-account-for-terraform/secondary-region-cfn-stacks/ssm-parameter.yaml \
  --region us-west-2
```

**PowerShell:**
```powershell
aws cloudformation create-stack `
  --stack-name account-parameters `
  --template-body file://Cloudformation/Initializing-account-for-terraform/secondary-region-cfn-stacks/ssm-parameter.yaml `
  --region us-west-2
```

**Deploy Account Creation Prerequisites**

Once the parameter stack completes, deploy the main prerequisite stack.

**Bash:**
```bash
aws cloudformation create-stack \
  --stack-name account-creation-prereqs \
  --template-body file://Cloudformation/Initializing-account-for-terraform/secondary-region-cfn-stacks/account-creation-prereqs.yaml \
  --region us-west-2
```

**PowerShell:**
```powershell
aws cloudformation create-stack `
  --stack-name account-creation-prereqs `
  --template-body file://Cloudformation/Initializing-account-for-terraform/secondary-region-cfn-stacks/account-creation-prereqs.yaml `
  --region us-west-2
```

---

## Step 2: Configure the Terraform Account Template

The account template is located in `Account-Creation-Runbook/02-Account-Folder-Template/Template`. It includes a **shared-account** folder for shared services resources and a **tenant** folder for tenant-specific resources.

Update the following files with the correct values for the new account:

| File | What to Update |
|------|---------------|
| `locals-env.hcl` | Environment-specific variables for the new account |
| `locals-cidr-range-use1.hcl` | CIDR block for `us-east-1` — must not overlap with existing allocations |
| `locals-cidr-range-usw2.hcl` | CIDR block for `us-west-2` — must not overlap with existing allocations |
| `locals-cloud.hcl` | Account name, account ID, and other account-specific metadata |

> **Important:** When adding CIDR blocks, follow the format of existing entries and verify there are no overlaps with other accounts in the network.

---

## Step 3: Configure the Ansible SSM Document

Navigate to `documents/Ansible-Documents/` and create a copy of an existing Ansible install document (e.g., `Intp-AnsibleInstall.yaml`). Rename the copy to reflect the new account.

In the new document, update the S3 bucket name to point to the correct bucket for your account. Only the account name prefix needs to change. For example:

| Original | Updated |
|----------|---------|
| `int-production-use1-shared-software-bucket` | `<new-account-name>-use1-shared-software-bucket` |

---

## Step 4: Download the Ansible Automation Platform Installer

1. Navigate to the [Red Hat Customer Portal — AAP Downloads](https://access.redhat.com/downloads/content/480).
2. Log in with your Red Hat subscription credentials.
3. Download the setup bundle: **`ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz`**

> **Version Notice:** Only version `2.4-1` has been validated with the current Ansible SSM documents. If you use a different version, you will need to update the SSM document to ensure compatibility.

---

## Step 5: Upload the Installer to S3

Upload the downloaded archive to the S3 bucket for your new account. The file must be placed under the `Ansible_Tower/` prefix.

**Using the AWS CLI:**
```bash
aws s3 cp ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz \
  s3://<new-account-name>-use1-shared-software-bucket/Ansible_Tower/
```

You can also upload the file through the AWS Management Console by navigating to the bucket and creating the `Ansible_Tower/` folder if it does not already exist.

---

## Step 6: Create and Execute the Workflow

1. Copy the workflow template from `Account-Creation-Runbook/03-Workflow-Template`.
2. Update the template with all account-specific values for the new account.
3. Execute the workflow.

The workflow orchestrates the full account provisioning process, including resource creation, Ansible Automation Platform configuration, and post-installation setup. Monitor the execution for any errors and address issues as they arise.

Once the workflow completes successfully, the new account is fully provisioned and ready for use.
