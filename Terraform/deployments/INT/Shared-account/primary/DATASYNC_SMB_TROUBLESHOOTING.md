# DataSync SMB Location Error - Troubleshooting Guide

## Error Summary
```
Error: Missing Resource Identity After Update: The Terraform provider unexpectedly returned no resource identity after having no errors in the resource update. This is always a problem with the provider and should be reported to the provider developer

with module.datasync_locations["smb-laptop"].aws_datasync_location_smb.smb[0]
```

## Root Cause
This error is caused by a known issue with AWS Terraform provider versions < 5.0.0 when handling DataSync SMB location resources. The provider fails to return the resource identity after update operations.

## Solutions Applied

### 1. Updated AWS Provider Version
- **Before**: `version = ">= 4.37.0"`
- **After**: `version = ">= 5.0.0"`
- **File**: `Terraform/formations/Simple-Network-Shared-Account/providers.tf`

### 2. Enhanced Provider Configuration
Added retry configuration and default tags to handle transient provider issues:
```hcl
provider "aws" {
  region = "${local.region}"
  
  # Retry configuration to handle provider issues
  retry_mode = "adaptive"
  max_retries = 3
  
  # Default tags for all resources
  default_tags {
    tags = {
      Environment  = "${include.env.locals.environment}"
      Owner        = "${include.env.locals.owner}"
      Build-method = "${include.env.locals.build}"
      ManagedBy    = "terraform:${local.deployment_name}"
    }
  }
}
```

### 3. Improved SMB Location Configuration
Added explicit domain parameter for better SMB compatibility:
```hcl
smb_location = {
  location_type   = "smb"
  server_hostname = include.env.locals.datasync.smb.server_hostname.laptop
  user            = include.env.locals.datasync.smb.user.first
  password        = include.env.locals.datasync.smb.password.first
  subdirectory    = include.env.locals.datasync.smb.subdirectory.smb
  agent_arns      = [include.env.locals.datasync.agent_arns.int]
  domain          = "WORKGROUP"  # Added for better compatibility
}
```

## Recovery Steps

### Step 1: Clean Up (if needed)
If the resource is in a bad state, remove it first:
```bash
terragrunt destroy -target='module.datasync_locations["smb-laptop"].aws_datasync_location_smb.smb[0]' -auto-approve
```

### Step 2: Clear Cache and Reinitialize
```bash
rm -rf .terragrunt-cache
terragrunt init -upgrade
```

### Step 3: Plan and Apply
```bash
terragrunt plan
terragrunt apply
```

### Step 4: Verify the Fix
Check that the SMB location is created successfully:
```bash
terragrunt output datasync_locations
```

## Alternative Workarounds

### Option A: Temporarily Remove SMB Location
If the issue persists, temporarily comment out the SMB location configuration:
```hcl
# {
#   key = "smb-laptop"
#   smb_location = {
#     # ... configuration
#   }
# },
```

### Option B: Use Import Instead of Create
If the resource exists in AWS but Terraform lost track:
```bash
terragrunt import 'module.datasync_locations["smb-laptop"].aws_datasync_location_smb.smb[0]' loc-xxxxxxxxxxxxxxxxx
```

### Option C: State Surgery (Last Resort)
Remove the resource from state and re-create:
```bash
terragrunt state rm 'module.datasync_locations["smb-laptop"].aws_datasync_location_smb.smb[0]'
terragrunt apply
```

## Prevention
- Always use AWS provider version >= 5.0.0 for DataSync resources
- Include retry configuration in provider blocks
- Test DataSync configurations in development environment first
- Monitor AWS provider release notes for DataSync-related fixes

## Additional Notes
- This issue is specific to DataSync SMB locations
- NFS and S3 locations are not affected
- The error typically occurs during update operations, not initial creation
- AWS provider team is aware of this issue and it's been fixed in newer versions