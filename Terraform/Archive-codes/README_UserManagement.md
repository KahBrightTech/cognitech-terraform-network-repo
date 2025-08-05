# SSM Documents for User Management

This directory contains SSM documents for automated user creation and management on both Windows and Linux instances.

## Documents Overview

### 1. UniversalUserCreation.yaml
A single SSM document that creates 2 users on both Windows and Linux systems using OS-specific preconditions.

**Features:**
- **OS Detection**: Uses preconditions to automatically detect and execute the correct OS-specific steps
- **Unified Management**: Single document for both Windows and Linux systems
- **Secure Credential Retrieval**: Gets credentials from AWS Secrets Manager
- **Windows Capabilities**:
  - Creates or updates 2 users with specified usernames and passwords
  - Adds users to Administrator group (full admin privileges)
  - Adds users to Remote Desktop Users group (RDP access)
  - Enables user accounts
- **Linux Capabilities**:
  - Creates or updates 2 users with specified usernames and passwords
  - Adds users to sudo group (Ubuntu/Debian) and wheel group (RHEL/CentOS/Amazon Linux)
  - Configures sudoers entries for passwordless sudo access
  - Enables SSH password authentication if needed
- **Comprehensive Logging**: Detailed logging and verification for both platforms

**Target Tags:** `BastionUserCreation=True`
**Schedule:** Every Sunday at 3 AM
**Preconditions:** 
- Windows steps execute only when `platformType = Windows`
- Linux steps execute only when `platformType = Linux`

## Prerequisites

### Secrets Manager Configuration
Both documents expect a secret named `int-preproduction-use1-Bastion-credentials` with the following structure:

```json
{
  "username1": "first_user_name",
  "password1": "first_user_password",
  "username2": "second_user_name", 
  "password2": "second_user_password"
}
```

### Environment Variables
Set the following environment variables before running Terraform:
- `TF_VAR_USER_USERNAME1`: First user's username
- `TF_VAR_USER_PASSWORD1`: First user's password
- `TF_VAR_USER_USERNAME2`: Second user's username
- `TF_VAR_USER_PASSWORD2`: Second user's password

### Instance Requirements

#### Windows Instances
- AWS PowerShell module (automatically imported)
- EC2 instance with SSM agent installed
- IAM role with Secrets Manager read permissions

#### Linux Instances
- AWS CLI and jq (automatically installed)
- EC2 instance with SSM agent installed
- IAM role with Secrets Manager read permissions

## Instance Tagging

To apply this document to your instances, tag them with:

### For Both Windows and Linux Instances:
```
BastionUserCreation = True
```

The SSM document will automatically detect the operating system using preconditions and execute the appropriate steps:
- Windows instances will execute PowerShell commands
- Linux instances will execute shell script commands

## Manual Execution

You can also run this document manually using AWS CLI:

### Universal User Creation (Both Windows and Linux):
```bash
aws ssm send-command \
    --document-name "universal-user-creation" \
    --targets "Key=tag:BastionUserCreation,Values=True" \
    --region us-east-1
```

The document will automatically detect the OS and execute the appropriate steps.

## Security Considerations

1. **Passwords**: Ensure strong passwords are used in the Secrets Manager
2. **Least Privilege**: Consider using more restrictive groups if full admin access is not required
3. **Rotation**: Regularly rotate passwords in Secrets Manager
4. **Logging**: All activities are logged in CloudWatch Logs via SSM
5. **Encryption**: Secrets are encrypted at rest in Secrets Manager

## Troubleshooting

### Common Issues:

1. **Secret not found**: Verify the secret name and region match the configuration
2. **Permission denied**: Ensure the EC2 instance role has `secretsmanager:GetSecretValue` permission
3. **User already exists**: The scripts handle existing users by updating their passwords
4. **SSH access issues**: The Linux script enables password authentication in SSH config

### Logs Location:
- Windows: Check CloudWatch Logs and Windows Event Logs
- Linux: Check CloudWatch Logs and `/var/log/amazon/ssm/`

## Deployment

These documents are automatically deployed when you run:

```bash
terragrunt apply
```

The deployment includes:
- SSM documents creation
- SSM associations for scheduled execution
- Secrets Manager secret with user credentials
