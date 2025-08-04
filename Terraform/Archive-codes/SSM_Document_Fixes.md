# SSM Document Issues and Fixes

## Issues Found in Original SSM Document

### 1. **Invalid Parameter Reference in Default Value**
**Problem:** Line 14 in original document:
```yaml
AnsibleTowerArchiveS3URI:
  type: String
  description: "S3 URI for Ansible Tower installer"
  default: "s3://{{ AnsibleS3BucketName }}/{{ AnsibleS3BucketPrefix }}/{{ AnsibleTowerArchiveName }}"
```

**Issue:** SSM doesn't support parameter references within default values. The `{{ AnsibleS3BucketName }}` syntax doesn't work in parameter defaults.

**Fix:** Remove the compound default and construct the S3 URI within the script using shell variables.

### 2. **Missing Error Handling and Logging**
**Problem:** The original script had minimal error handling compared to the working bash version.

**Fix:** Added comprehensive error handling, logging functions, and file verification steps.

### 3. **Inconsistent File Size Check**
**Problem:** The original used `stat -f%z` which doesn't work on all Linux distributions.

**Fix:** Changed to `stat -c%s` which is more universally supported on Linux.

### 4. **Missing Variable Validation**
**Problem:** No validation that SSM parameters were properly resolved.

**Fix:** Added logging to show resolved parameter values for debugging.

## Key Changes Made

### Parameters Section
```yaml
# REMOVED the problematic compound default:
# AnsibleTowerArchiveS3URI:
#   default: "s3://{{ AnsibleS3BucketName }}/{{ AnsibleS3BucketPrefix }}/{{ AnsibleTowerArchiveName }}"

# KEPT individual parameters:
AnsibleS3BucketName:
  default: "{{ssm:/Standard/ansible/bucketName}}"
AnsibleS3BucketPrefix:
  default: "Ansible_Tower"
AnsibleTowerArchiveName:
  default: "ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz"
```

### Script Section
```bash
# ADDED: Variable assignment and S3 URI construction
ANSIBLE_TOWER_USERNAME="{{ AnsibleTowerUsername }}"
ANSIBLE_TOWER_PASSWORD="{{ AnsibleTowerPassword }}"
ANSIBLE_S3_BUCKET_NAME="{{ AnsibleS3BucketName }}"
ANSIBLE_S3_BUCKET_PREFIX="{{ AnsibleS3BucketPrefix }}"
ANSIBLE_TOWER_ARCHIVE_NAME="{{ AnsibleTowerArchiveName }}"

# Construct S3 URI from components
ANSIBLE_TOWER_ARCHIVE_S3_URI="s3://${ANSIBLE_S3_BUCKET_NAME}/${ANSIBLE_S3_BUCKET_PREFIX}/${ANSIBLE_TOWER_ARCHIVE_NAME}"

# ADDED: Logging and error handling functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}
```

## Testing the Fixed SSM Document

### Prerequisites
1. **SSM Parameters must exist:**
   ```bash
   aws ssm put-parameter --name "/Standard/ansible/username" --value "your_redhat_username" --type "SecureString"
   aws ssm put-parameter --name "/Standard/ansible/password" --value "your_redhat_password" --type "SecureString"
   aws ssm put-parameter --name "/Standard/ansible/bucketName" --value "your-s3-bucket-name" --type "String"
   ```

2. **IAM Role for EC2 instance must have:**
   - `ssm:GetParameter` permission for `/Standard/ansible/*`
   - `s3:GetObject` permission for the S3 bucket
   - Basic SSM permissions for Systems Manager agent

3. **S3 bucket must contain the Ansible Tower installer**

### Running the Fixed SSM Document
```bash
# Create the SSM document
aws ssm create-document \
    --name "AnsibleTowerInstaller-Fixed" \
    --document-type "Command" \
    --document-format "YAML" \
    --content file://AnsibleInstall_fixed.yaml

# Execute on an instance
aws ssm send-command \
    --instance-ids "i-1234567890abcdef0" \
    --document-name "AnsibleTowerInstaller-Fixed" \
    --comment "Install Ansible Tower - Fixed Version"
```

## Common SSM Document Pitfalls

1. **Parameter References:** Don't use `{{ ParameterName }}` in default values
2. **File Paths:** Always use absolute paths in SSM scripts
3. **Error Handling:** SSM doesn't show detailed errors by default - add logging
4. **Permissions:** Ensure IAM roles have all required permissions
5. **Parameter Store:** Verify SSM parameters exist and are accessible
6. **Platform Differences:** Test commands work on your target OS version

## Why the Bash Script Worked but SSM Failed

1. **Direct Variable Assignment:** Bash script used environment variables directly
2. **No Parameter Resolution:** Bash script didn't rely on SSM parameter resolution
3. **Better Error Messages:** Bash script had more detailed error output
4. **Flexible Paths:** Bash script handled file system differences better
5. **Manual Credential Input:** Bash script allowed manual credential entry for testing

The fixed SSM document now mirrors the working bash script logic while properly handling SSM parameter resolution.
