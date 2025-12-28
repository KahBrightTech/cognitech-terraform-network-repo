# Remove-InactiveIAMRoles.ps1
# Deletes IAM roles with last activity older than 500 days
# Compatible with both AWS.Tools and AWSPowerShell modules

param(
    [int]$DaysInactive = 500,
    [switch]$WhatIf = $true  # Default to dry-run mode for safety
)

# Check if AWS module is available
$awsModuleLoaded = $false
if (Get-Command Get-IAMRoleList -ErrorAction SilentlyContinue) {
    $awsModuleLoaded = $true
    Write-Host "Using AWS.Tools module" -ForegroundColor Green
} elseif (Get-Command Get-IAMRoles -ErrorAction SilentlyContinue) {
    $awsModuleLoaded = $true
    Write-Host "Using legacy AWSPowerShell module" -ForegroundColor Green
} else {
    Write-Host "ERROR: AWS PowerShell module not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install one of the following:" -ForegroundColor Yellow
    Write-Host "  Option 1 (Recommended): Install-Module -Name AWS.Tools.IdentityManagement" -ForegroundColor White
    Write-Host "  Option 2 (Legacy):      Install-Module -Name AWSPowerShell" -ForegroundColor White
    Write-Host ""
    Write-Host "After installation, configure credentials with: Set-AWSCredential" -ForegroundColor Yellow
    exit 1
}

# Check AWS credentials
try {
    $null = Get-AWSCredential -ListProfileDetail -ErrorAction Stop
} catch {
    Write-Host "ERROR: AWS credentials not configured!" -ForegroundColor Red
    Write-Host "Run: Set-AWSCredential -AccessKey YOUR_KEY -SecretKey YOUR_SECRET -StoreAs default" -ForegroundColor Yellow
    exit 1
}

# Calculate the cutoff date
$cutoffDate = (Get-Date).AddDays(-$DaysInactive)

Write-Host ""
Write-Host "Starting IAM role cleanup..." -ForegroundColor Cyan
Write-Host "Cutoff date: $($cutoffDate.ToString('yyyy-MM-dd'))" -ForegroundColor Yellow
Write-Host "Mode: $(if($WhatIf){'DRY RUN (no changes will be made)'}else{'LIVE (roles will be deleted)'})" -ForegroundColor $(if($WhatIf){'Green'}else{'Red'})
Write-Host ""

# Get all IAM roles (compatible with both module versions)
Write-Host "Fetching all IAM roles..." -ForegroundColor Cyan
try {
    if (Get-Command Get-IAMRoleList -ErrorAction SilentlyContinue) {
        $roles = Get-IAMRoleList
    } else {
        $roles = Get-IAMRoles
    }
} catch {
    Write-Host "ERROR fetching roles: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you have the correct AWS permissions and region configured." -ForegroundColor Yellow
    exit 1
}

Write-Host "Found $($roles.Count) IAM roles" -ForegroundColor Green
Write-Host ""

$rolesToDelete = @()

foreach ($role in $roles) {
    $roleName = $role.RoleName
    
    # Get role's last activity
    try {
        $roleDetail = Get-IAMRole -RoleName $roleName
        $lastUsed = $roleDetail.RoleLastUsed.LastUsedDate
        
        if ($null -eq $lastUsed) {
            Write-Host "Role: $roleName - Never used" -ForegroundColor Gray
            # Handle never-used roles based on creation date
            if ($roleDetail.CreateDate -lt $cutoffDate) {
                $rolesToDelete += $role
                $daysOld = [math]::Round(((Get-Date) - $roleDetail.CreateDate).TotalDays)
                Write-Host "  -> Marked for deletion (created $daysOld days ago, never used)" -ForegroundColor Yellow
            }
        }
        elseif ($lastUsed -lt $cutoffDate) {
            $daysSinceUse = [math]::Round(((Get-Date) - $lastUsed).TotalDays)
            Write-Host "Role: $roleName - Last used $daysSinceUse days ago ($($lastUsed.ToString('yyyy-MM-dd')))" -ForegroundColor Yellow
            $rolesToDelete += $role
            Write-Host "  -> Marked for deletion" -ForegroundColor Red
        }
        else {
            $daysSinceUse = [math]::Round(((Get-Date) - $lastUsed).TotalDays)
            Write-Host "Role: $roleName - Last used $daysSinceUse days ago (ACTIVE)" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error checking role $roleName : $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "==================== SUMMARY ====================" -ForegroundColor Cyan
Write-Host "Total roles: $($roles.Count)" -ForegroundColor White
Write-Host "Roles to delete: $($rolesToDelete.Count)" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Cyan

if ($rolesToDelete.Count -eq 0) {
    Write-Host ""
    Write-Host "No roles to delete." -ForegroundColor Green
    exit
}

# Delete roles
if (-not $WhatIf) {
    Write-Host ""
    Write-Host "WARNING: You are about to DELETE $($rolesToDelete.Count) IAM roles!" -ForegroundColor Red
    Write-Host ""
    $confirmation = Read-Host "Type 'DELETE' to confirm"
    
    if ($confirmation -ne "DELETE") {
        Write-Host "Operation cancelled." -ForegroundColor Yellow
        exit
    }
    
    Write-Host ""
    Write-Host "Deleting roles..." -ForegroundColor Red
    
    $successCount = 0
    $failCount = 0
    
    foreach ($role in $rolesToDelete) {
        $roleName = $role.RoleName
        Write-Host ""
        Write-Host "Processing: $roleName" -ForegroundColor Cyan
        try {
            # Remove inline policies
            $inlinePolicies = Get-IAMRolePolicyList -RoleName $roleName
            foreach ($policyName in $inlinePolicies) {
                Remove-IAMRolePolicy -RoleName $roleName -PolicyName $policyName -Force
                Write-Host "  ✓ Removed inline policy: $policyName" -ForegroundColor Gray
            }
            
            # Detach managed policies
            $attachedPolicies = Get-IAMAttachedRolePolicyList -RoleName $roleName
            foreach ($policy in $attachedPolicies) {
                Unregister-IAMRolePolicy -RoleName $roleName -PolicyArn $policy.PolicyArn
                Write-Host "  ✓ Detached managed policy: $($policy.PolicyName)" -ForegroundColor Gray
            }
            
            # Remove instance profiles
            $instanceProfiles = Get-IAMInstanceProfileForRole -RoleName $roleName
            foreach ($profile in $instanceProfiles) {
                Remove-IAMRoleFromInstanceProfile -InstanceProfileName $profile.InstanceProfileName -RoleName $roleName -Force
                Write-Host "  ✓ Removed from instance profile: $($profile.InstanceProfileName)" -ForegroundColor Gray
            }
            
            # Delete the role
            Remove-IAMRole -RoleName $roleName -Force
            Write-Host "  ✓ DELETED: $roleName" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host "  ✗ FAILED to delete $roleName : $_" -ForegroundColor Red
            $failCount++
        }
    }
    
    Write-Host ""
    Write-Host "==================== RESULTS ====================" -ForegroundColor Cyan
    Write-Host "Successfully deleted: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failCount" -ForegroundColor $(if($failCount -gt 0){'Red'}else{'Green'})
    Write-Host "=================================================" -ForegroundColor Cyan
}
else {
    Write-Host ""
    Write-Host "DRY RUN - No changes made. Run with -WhatIf:`$false to actually delete roles." -ForegroundColor Green
    Write-Host ""
    Write-Host "Roles that would be deleted:" -ForegroundColor Yellow
    foreach ($role in $rolesToDelete) {
        $roleDetail = Get-IAMRole -RoleName $role.RoleName
        $lastUsed = $roleDetail.RoleLastUsed.LastUsedDate
        if ($null -eq $lastUsed) {
            $daysOld = [math]::Round(((Get-Date) - $roleDetail.CreateDate).TotalDays)
            Write-Host "  - $($role.RoleName) (never used, created $daysOld days ago)" -ForegroundColor White
        } else {
            $daysSinceUse = [math]::Round(((Get-Date) - $lastUsed).TotalDays)
            Write-Host "  - $($role.RoleName) (last used $daysSinceUse days ago)" -ForegroundColor White
        }
    }
}