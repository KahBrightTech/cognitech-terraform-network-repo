#!/bin/bash

##############################################################
#         ANSIBLE TOWER INSTALLATION - CONFIGURATION        #
##############################################################

echo "Ansible Tower Installation Configuration Setup"
echo "=============================================="
echo ""
echo "This script will help you set up the required environment variables"
echo "for testing the Ansible Tower installation."
echo ""

# Function to read input with default value
read_with_default() {
    local prompt="$1"
    local default="$2"
    local varname="$3"
    
    if [ -n "$default" ]; then
        read -p "$prompt [$default]: " input
        export $varname="${input:-$default}"
    else
        read -p "$prompt: " input
        export $varname="$input"
    fi
}

# Get current values if they exist
current_username="${ANSIBLE_TOWER_USERNAME:-}"
current_bucket="${ANSIBLE_S3_BUCKET_NAME:-}"
current_prefix="${ANSIBLE_S3_BUCKET_PREFIX:-Ansible_Tower}"
current_archive="${ANSIBLE_TOWER_ARCHIVE_NAME:-ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz}"

echo "Please provide the following configuration values:"
echo ""

# Red Hat credentials
read_with_default "Red Hat username" "$current_username" "ANSIBLE_TOWER_USERNAME"
read -s -p "Red Hat password: " ANSIBLE_TOWER_PASSWORD
echo ""
export ANSIBLE_TOWER_PASSWORD

# S3 configuration
echo ""
read_with_default "S3 bucket name" "$current_bucket" "ANSIBLE_S3_BUCKET_NAME"
read_with_default "S3 bucket prefix" "$current_prefix" "ANSIBLE_S3_BUCKET_PREFIX"
read_with_default "Ansible archive filename" "$current_archive" "ANSIBLE_TOWER_ARCHIVE_NAME"

# Generate export commands
echo ""
echo "Configuration Summary:"
echo "====================="
echo "Username: $ANSIBLE_TOWER_USERNAME"
echo "Password: [HIDDEN]"
echo "S3 Bucket: $ANSIBLE_S3_BUCKET_NAME"
echo "S3 Prefix: $ANSIBLE_S3_BUCKET_PREFIX"
echo "Archive: $ANSIBLE_TOWER_ARCHIVE_NAME"
echo ""

# Create environment file
cat > ansible_tower_config.env << EOF
# Ansible Tower Installation Configuration
# Source this file before running the installation script:
# source ansible_tower_config.env

export ANSIBLE_TOWER_USERNAME="$ANSIBLE_TOWER_USERNAME"
export ANSIBLE_TOWER_PASSWORD="$ANSIBLE_TOWER_PASSWORD"
export ANSIBLE_S3_BUCKET_NAME="$ANSIBLE_S3_BUCKET_NAME"
export ANSIBLE_S3_BUCKET_PREFIX="$ANSIBLE_S3_BUCKET_PREFIX"
export ANSIBLE_TOWER_ARCHIVE_NAME="$ANSIBLE_TOWER_ARCHIVE_NAME"
EOF

echo "Configuration saved to: ansible_tower_config.env"
echo ""
echo "To use this configuration:"
echo "1. Source the environment file: source ansible_tower_config.env"
echo "2. Run the installation script: sudo -E ./ansible_install_test.sh"
echo ""
echo "Or set the variables manually:"
echo "export ANSIBLE_TOWER_USERNAME=\"$ANSIBLE_TOWER_USERNAME\""
echo "export ANSIBLE_TOWER_PASSWORD=\"[your_password]\""
echo "export ANSIBLE_S3_BUCKET_NAME=\"$ANSIBLE_S3_BUCKET_NAME\""
echo "export ANSIBLE_S3_BUCKET_PREFIX=\"$ANSIBLE_S3_BUCKET_PREFIX\""
echo "export ANSIBLE_TOWER_ARCHIVE_NAME=\"$ANSIBLE_TOWER_ARCHIVE_NAME\""
