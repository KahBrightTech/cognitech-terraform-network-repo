#!/bin/bash -xe

##############################################################
#         ANSIBLE TOWER INSTALLATION TEST SCRIPT            #
#            Converted from SSM Document                    #
##############################################################

# Configuration Variables - Set these before running the script
# Replace these with your actual values for testing

# SSM Parameter equivalent variables
ANSIBLE_TOWER_USERNAME="${ANSIBLE_TOWER_USERNAME:-your_redhat_username}"
ANSIBLE_TOWER_PASSWORD="${ANSIBLE_TOWER_PASSWORD:-your_redhat_password}"
ANSIBLE_S3_BUCKET_NAME="${ANSIBLE_S3_BUCKET_NAME:-your-s3-bucket-name}"
ANSIBLE_S3_BUCKET_PREFIX="${ANSIBLE_S3_BUCKET_PREFIX:-Ansible_Tower}"
ANSIBLE_TOWER_ARCHIVE_NAME="${ANSIBLE_TOWER_ARCHIVE_NAME:-ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz}"

# Constructed S3 URI
ANSIBLE_TOWER_ARCHIVE_S3_URI="s3://${ANSIBLE_S3_BUCKET_NAME}/${ANSIBLE_S3_BUCKET_PREFIX}/${ANSIBLE_TOWER_ARCHIVE_NAME}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check if running as root or with sudo
if [[ $EUID -ne 0 ]]; then
    log "This script must be run as root or with sudo privileges"
    exit 1
fi

# Validate required variables
if [[ "$ANSIBLE_TOWER_USERNAME" == "your_redhat_username" ]] || [[ "$ANSIBLE_TOWER_PASSWORD" == "your_redhat_password" ]]; then
    log "WARNING: Please set ANSIBLE_TOWER_USERNAME and ANSIBLE_TOWER_PASSWORD environment variables with your Red Hat credentials"
    log "Example: export ANSIBLE_TOWER_USERNAME='your_username'"
    log "Example: export ANSIBLE_TOWER_PASSWORD='your_password'"
fi

if [[ "$ANSIBLE_S3_BUCKET_NAME" == "your-s3-bucket-name" ]]; then
    log "WARNING: Please set ANSIBLE_S3_BUCKET_NAME environment variable with your S3 bucket name"
    log "Example: export ANSIBLE_S3_BUCKET_NAME='my-ansible-bucket'"
fi

log "Starting Ansible Tower installation..."
log "Configuration:"
log "  Username: $ANSIBLE_TOWER_USERNAME"
log "  S3 Bucket: $ANSIBLE_S3_BUCKET_NAME"
log "  S3 Prefix: $ANSIBLE_S3_BUCKET_PREFIX"
log "  Archive Name: $ANSIBLE_TOWER_ARCHIVE_NAME"
log "  Full S3 URI: $ANSIBLE_TOWER_ARCHIVE_S3_URI"

##############################################################
#        INSTALLING AND CONFIGURING ANSIBLE TOWER           #
##############################################################

# Ensure AWS CLI is in the PATH
export PATH=/usr/local/bin:$PATH

# Install AWS CLI if not installed
if ! command -v aws &> /dev/null; then
    log "Installing AWS CLI..."
    yum install unzip -y || error_exit "Failed to install unzip"
    
    # Download AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" || error_exit "Failed to download AWS CLI"
    
    # Clean up any existing installation
    rm -rf aws
    unzip -o awscliv2.zip || error_exit "Failed to extract AWS CLI"
    
    # Install AWS CLI
    ./aws/install || error_exit "Failed to install AWS CLI"
    
    # Verify installation
    /usr/local/bin/aws --version || error_exit "AWS CLI installation verification failed"
    export PATH=/usr/local/bin:$PATH
    
    if ! command -v aws &> /dev/null; then
        error_exit "AWS CLI installation failed - command not found in PATH"
    fi
    
    log "AWS CLI installed successfully"
else
    log "AWS CLI already installed. Version: $(aws --version)"
fi

# Verify AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    log "WARNING: AWS credentials not configured. You may need to run 'aws configure' or set environment variables"
    log "The script will continue but S3 download may fail"
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
log "Source: $ANSIBLE_TOWER_ARCHIVE_S3_URI"
log "Destination: /root/$ANSIBLE_TOWER_ARCHIVE_NAME"

# Create download directory if it doesn't exist
mkdir -p /root

# Download the file
if aws s3 cp "$ANSIBLE_TOWER_ARCHIVE_S3_URI" "/root/" --no-progress; then
    log "Download completed successfully"
else
    error_exit "Failed to download Ansible Tower archive from S3: $ANSIBLE_TOWER_ARCHIVE_S3_URI"
fi

# Verify the file was downloaded
if [ ! -f "/root/$ANSIBLE_TOWER_ARCHIVE_NAME" ]; then
    error_exit "Ansible Tower archive not found after download: /root/$ANSIBLE_TOWER_ARCHIVE_NAME"
fi

# Check file size
FILE_SIZE=$(stat -f%z "/root/$ANSIBLE_TOWER_ARCHIVE_NAME" 2>/dev/null || stat -c%s "/root/$ANSIBLE_TOWER_ARCHIVE_NAME" 2>/dev/null)
log "Downloaded file size: $FILE_SIZE bytes"

# Extract Ansible Tower installer
log "Extracting Ansible Tower archive..."
if tar -xzf "/root/$ANSIBLE_TOWER_ARCHIVE_NAME" -C /root/; then
    log "Archive extracted successfully"
else
    error_exit "Failed to extract Ansible Tower archive"
fi

# Auto-detect the extracted folder name
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
    error_exit "Inventory file not found in $EXTRACTED_FOLDER!"
fi

# Backup original inventory file
cp "$EXTRACTED_FOLDER/inventory" "$EXTRACTED_FOLDER/inventory.backup"
log "Created backup of inventory file"

# Show original inventory content for debugging
log "Original inventory file content:"
cat "$EXTRACTED_FOLDER/inventory"

# Modify inventory file
log "Configuring inventory file..."
sed -i "s|admin_password=.*|admin_password='$ANSIBLE_TOWER_PASSWORD'|" "$EXTRACTED_FOLDER/inventory"
sed -i "s|pg_password=.*|pg_password='$ANSIBLE_TOWER_PASSWORD'|" "$EXTRACTED_FOLDER/inventory"
sed -i "s|register_username=.*|register_username='$ANSIBLE_TOWER_USERNAME'|" "$EXTRACTED_FOLDER/inventory"
sed -i "s|register_password=.*|register_password='$ANSIBLE_TOWER_PASSWORD'|" "$EXTRACTED_FOLDER/inventory"

# Add automation controller section
echo "" >> "$EXTRACTED_FOLDER/inventory"
echo "[automationcontroller]" >> "$EXTRACTED_FOLDER/inventory"
echo "ansible ansible_connection=local" >> "$EXTRACTED_FOLDER/inventory"

# Show modified inventory content for debugging
log "Modified inventory file content:"
cat "$EXTRACTED_FOLDER/inventory"

# Verify setup script exists
if [ ! -f "$EXTRACTED_FOLDER/setup.sh" ]; then
    log "Contents of $EXTRACTED_FOLDER:"
    ls -la "$EXTRACTED_FOLDER/"
    error_exit "Ansible Tower setup script not found in $EXTRACTED_FOLDER!"
fi

# Make setup script executable
chmod +x "$EXTRACTED_FOLDER/setup.sh"

# Run Ansible Tower setup
log "Starting Ansible Tower setup..."
log "This may take several minutes..."

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
