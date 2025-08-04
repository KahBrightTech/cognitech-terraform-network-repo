#!/bin/bash

##############################################################
#         SSM PARAMETER SETUP FOR ANSIBLE TOWER             #
##############################################################

echo "Setting up SSM Parameters for Ansible Tower Installation"
echo "========================================================"
echo ""

# Function to create SSM parameter
create_ssm_parameter() {
    local name="$1"
    local value="$2"
    local type="$3"
    local description="$4"
    
    echo "Creating SSM parameter: $name"
    
    if aws ssm put-parameter \
        --name "$name" \
        --value "$value" \
        --type "$type" \
        --description "$description" \
        --overwrite; then
        echo "✓ Successfully created parameter: $name"
    else
        echo "✗ Failed to create parameter: $name"
        return 1
    fi
}

# Check AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured or credentials are invalid"
    echo "Please run 'aws configure' first"
    exit 1
fi

echo "Current AWS identity:"
aws sts get-caller-identity

echo ""
read -p "Continue with SSM parameter creation? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Please provide the following values:"
echo ""

# Get Red Hat credentials
read -p "Red Hat username: " redhat_username
read -s -p "Red Hat password: " redhat_password
echo ""

# Get S3 bucket information
read -p "S3 bucket name (containing Ansible Tower installer): " s3_bucket
read -p "S3 bucket prefix/folder [Ansible_Tower]: " s3_prefix
s3_prefix="${s3_prefix:-Ansible_Tower}"

echo ""
echo "Creating SSM parameters..."
echo ""

# Create the SSM parameters
create_ssm_parameter \
    "/Standard/ansible/username" \
    "$redhat_username" \
    "SecureString" \
    "Red Hat username for Ansible Tower registration"

create_ssm_parameter \
    "/Standard/ansible/password" \
    "$redhat_password" \
    "SecureString" \
    "Red Hat password for Ansible Tower registration"

create_ssm_parameter \
    "/Standard/ansible/bucketName" \
    "$s3_bucket" \
    "String" \
    "S3 bucket name containing Ansible Tower installer"

echo ""
echo "SSM parameters created successfully!"
echo ""
echo "You can now use the fixed SSM document with these parameters:"
echo "- /Standard/ansible/username"
echo "- /Standard/ansible/password"
echo "- /Standard/ansible/bucketName"
echo ""
echo "Make sure your EC2 instances have an IAM role with permissions to:"
echo "1. Read these SSM parameters (ssm:GetParameter)"
echo "2. Download from the S3 bucket (s3:GetObject)"
echo "3. Run SSM commands (basic SSM agent permissions)"
