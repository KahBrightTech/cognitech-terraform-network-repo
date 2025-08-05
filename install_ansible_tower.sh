#!/bin/bash -xe

# Ansible Tower Installation Script
# Converted from AWS SSM Document to standalone bash script
# Date: August 4, 2025

# Configuration variables - modify these as needed
ANSIBLE_TOWER_USERNAME="${ANSIBLE_TOWER_USERNAME:-admin}"
ANSIBLE_TOWER_PASSWORD="${ANSIBLE_TOWER_PASSWORD:-changeme123}"
ANSIBLE_S3_BUCKET_NAME="${ANSIBLE_S3_BUCKET_NAME:-ansibleautomationbucket}"
ANSIBLE_S3_BUCKET_PREFIX="${ANSIBLE_S3_BUCKET_PREFIX:-Ansible_Tower}"
ANSIBLE_TOWER_ARCHIVE_NAME="${ANSIBLE_TOWER_ARCHIVE_NAME:-ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Main installation function
main() {
    log "Starting Ansible Tower installation..."
    log "Configuration:"
    log "  Username: $ANSIBLE_TOWER_USERNAME"
    log "  S3 Bucket: $ANSIBLE_S3_BUCKET_NAME"
    log "  S3 Prefix: $ANSIBLE_S3_BUCKET_PREFIX"
    log "  Archive Name: $ANSIBLE_TOWER_ARCHIVE_NAME"
    log "  Full S3 URI: s3://$ANSIBLE_S3_BUCKET_NAME/$ANSIBLE_S3_BUCKET_PREFIX/$ANSIBLE_TOWER_ARCHIVE_NAME"

    export PATH=/usr/local/bin:$PATH

    # Check and install AWS CLI if needed
    if ! command -v aws &> /dev/null; then
        log "Installing AWS CLI..."
        yum install unzip -y || error_exit "Failed to install unzip"
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" || error_exit "Failed to download AWS CLI"
        rm -rf aws
        unzip -o awscliv2.zip || error_exit "Failed to extract AWS CLI"
        ./aws/install || error_exit "Failed to install AWS CLI"
        /usr/local/bin/aws --version || error_exit "AWS CLI installation verification failed"
        export PATH=/usr/local/bin:$PATH
        if ! command -v aws &> /dev/null; then
            error_exit "AWS CLI installation failed - command not found in PATH"
        fi
        log "AWS CLI installed successfully"
    else
        log "AWS CLI already installed. Version: $(aws --version)"
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log "WARNING: AWS credentials not configured properly"
        log "Ensure the EC2 instance has an IAM role with S3 access permissions"
    fi

    # Register with Red Hat Subscription Manager
    log "Attempting to register with Red Hat Subscription Manager..."
    if subscription-manager register --username "$ANSIBLE_TOWER_USERNAME" --password "$ANSIBLE_TOWER_PASSWORD"; then
        log "Red Hat registration successful."
    else
        log "Instance already registered or failed to register. Continuing..."
    fi

    # Update system packages
    log "Updating system packages..."
    yum update -y || error_exit "Failed to update system packages"

    # Set hostname
    log "Setting hostname..."
    hostnamectl set-hostname ansible || error_exit "Failed to set hostname"
    echo "127.0.0.1 ansible.local localhost.localdomain" >> /etc/hosts

    # Download Ansible Tower installer from S3
    log "Downloading Ansible Tower installer from S3..."
    log "Source: s3://$ANSIBLE_S3_BUCKET_NAME/$ANSIBLE_S3_BUCKET_PREFIX/$ANSIBLE_TOWER_ARCHIVE_NAME"
    log "Destination: /root/$ANSIBLE_TOWER_ARCHIVE_NAME"

    mkdir -p /root
    if aws s3 cp "s3://$ANSIBLE_S3_BUCKET_NAME/$ANSIBLE_S3_BUCKET_PREFIX/$ANSIBLE_TOWER_ARCHIVE_NAME" "/root/" --no-progress; then
        log "Download completed successfully"
    else
        error_exit "Failed to download Ansible Tower archive from S3"
    fi

    # Verify download
    if [ ! -f "/root/$ANSIBLE_TOWER_ARCHIVE_NAME" ]; then
        error_exit "Ansible Tower archive not found after download"
    fi

    FILE_SIZE=$(stat -c%s "/root/$ANSIBLE_TOWER_ARCHIVE_NAME" 2>/dev/null || echo "unknown")
    log "Downloaded file size: $FILE_SIZE bytes"

    # Extract archive
    log "Extracting Ansible Tower archive..."
    if tar -xzf "/root/$ANSIBLE_TOWER_ARCHIVE_NAME" -C /root/; then
        log "Archive extracted successfully"
    else
        error_exit "Failed to extract Ansible Tower archive"
    fi

    # Find extracted folder
    log "Looking for extracted Ansible folder..."
    EXTRACTED_FOLDER=$(find /root -maxdepth 1 -type d -name "*ansible*" | grep -v "^/root$" | head -1)

    if [ -z "$EXTRACTED_FOLDER" ]; then
        log "Available directories in /root:"
        ls -la /root/
        error_exit "Could not find extracted Ansible Tower folder!"
    fi

    log "Found extracted folder: $EXTRACTED_FOLDER"

    # Verify inventory file exists
    if [ ! -f "$EXTRACTED_FOLDER/inventory" ]; then
        log "Contents of $EXTRACTED_FOLDER:"
        ls -la "$EXTRACTED_FOLDER/"
        error_exit "Inventory file not found!"
    fi

    # Backup and configure inventory file
    cp "$EXTRACTED_FOLDER/inventory" "$EXTRACTED_FOLDER/inventory.backup"
    log "Created backup of inventory file"
    log "Original inventory file content:"
    cat "$EXTRACTED_FOLDER/inventory"

    log "Configuring inventory file..."
    sed -i "s|admin_password=.*|admin_password='$ANSIBLE_TOWER_PASSWORD'|" "$EXTRACTED_FOLDER/inventory"
    sed -i "s|pg_password=.*|pg_password='$ANSIBLE_TOWER_PASSWORD'|" "$EXTRACTED_FOLDER/inventory"
    sed -i "s|register_username=.*|register_username='$ANSIBLE_TOWER_USERNAME'|" "$EXTRACTED_FOLDER/inventory"
    sed -i "s|register_password=.*|register_password='$ANSIBLE_TOWER_PASSWORD'|" "$EXTRACTED_FOLDER/inventory"

    echo "" >> "$EXTRACTED_FOLDER/inventory"
    echo "[automationcontroller]" >> "$EXTRACTED_FOLDER/inventory"
    echo "ansible ansible_connection=local" >> "$EXTRACTED_FOLDER/inventory"

    log "Modified inventory file content:"
    cat "$EXTRACTED_FOLDER/inventory"

    # Verify setup script exists
    if [ ! -f "$EXTRACTED_FOLDER/setup.sh" ]; then
        log "Contents of $EXTRACTED_FOLDER:"
        ls -la "$EXTRACTED_FOLDER/"
        error_exit "Ansible Tower setup script not found!"
    fi

    # Run setup
    chmod +x "$EXTRACTED_FOLDER/setup.sh"
    log "Starting Ansible Tower setup..."
    cd "$EXTRACTED_FOLDER" || error_exit "Failed to change to extracted folder"

    if bash setup.sh -e required_ram=2048; then
        log "Ansible Tower setup completed successfully!"
    else
        error_exit "Ansible Tower setup failed!"
    fi

    log "Installation script completed!"
    log "You can now access Ansible Tower at: https://$(hostname)/api/"
    log "Username: admin"
    log "Password: $ANSIBLE_TOWER_PASSWORD"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    error_exit "This script is designed for Linux systems only"
fi

# Display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Environment variables (optional):"
    echo "  ANSIBLE_TOWER_USERNAME     - Red Hat username (default: admin)"
    echo "  ANSIBLE_TOWER_PASSWORD     - Red Hat password (default: changeme123)"
    echo "  ANSIBLE_S3_BUCKET_NAME     - S3 bucket name (default: ansibleautomationbucket)"
    echo "  ANSIBLE_S3_BUCKET_PREFIX   - S3 bucket prefix (default: Ansible_Tower)"
    echo "  ANSIBLE_TOWER_ARCHIVE_NAME - Archive filename (default: ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz)"
    echo ""
    echo "Example:"
    echo "  export ANSIBLE_TOWER_PASSWORD='your_password'"
    echo "  export ANSIBLE_S3_BUCKET_NAME='your_bucket'"
    echo "  sudo $0"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
