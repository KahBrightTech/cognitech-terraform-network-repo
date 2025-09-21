# DataSync SMB Location Fix Script
# This script addresses the "Missing Resource Identity After Update" error

Write-Host "DataSync SMB Location Fix Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if terragrunt is available
try {
    $terragruntVersion = & terragrunt --version
    Write-Host "Terragrunt found: $terragruntVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Terragrunt not found in PATH. Please ensure Terragrunt is installed and available." -ForegroundColor Red
    exit 1
}

# Set the working directory
$workingDir = "c:\Users\Owner\Downloads\GitRepos\cognitech-repos\cognitech-terraform-network-repo\Terraform\deployments\INT\Shared-account\primary"
Set-Location $workingDir

Write-Host "Working directory: $workingDir" -ForegroundColor Yellow

# Step 1: Clean up the problematic resource
Write-Host "`nStep 1: Removing problematic SMB DataSync location..." -ForegroundColor Yellow
try {
    $destroyResult = & terragrunt destroy -target="module.datasync_locations[`"smb-laptop`"].aws_datasync_location_smb.smb[0]" -auto-approve 2>&1
    Write-Host "Destroy command executed" -ForegroundColor Green
} catch {
    Write-Host "Warning: Destroy command failed or resource doesn't exist" -ForegroundColor Yellow
}

# Step 2: Clear terraform cache
Write-Host "`nStep 2: Clearing Terraform cache..." -ForegroundColor Yellow
if (Test-Path ".terragrunt-cache") {
    Remove-Item ".terragrunt-cache" -Recurse -Force
    Write-Host "Terraform cache cleared" -ForegroundColor Green
} else {
    Write-Host "No cache directory found" -ForegroundColor Yellow
}

# Step 3: Initialize with new provider version
Write-Host "`nStep 3: Initializing with updated provider..." -ForegroundColor Yellow
try {
    $initResult = & terragrunt init -upgrade 2>&1
    Write-Host "Initialize completed" -ForegroundColor Green
} catch {
    Write-Host "Error during initialization: $_" -ForegroundColor Red
    exit 1
}

# Step 4: Plan to verify changes
Write-Host "`nStep 4: Creating execution plan..." -ForegroundColor Yellow
try {
    $planResult = & terragrunt plan -out=tfplan 2>&1
    Write-Host "Plan created successfully" -ForegroundColor Green
} catch {
    Write-Host "Error during planning: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`nScript completed successfully!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the plan output above" -ForegroundColor White
Write-Host "2. If the plan looks good, run: terragrunt apply tfplan" -ForegroundColor White
Write-Host "3. Monitor the SMB location creation carefully" -ForegroundColor White