# Ansible Tower Installation Test Scripts

This directory contains converted bash scripts from the original SSM document to help with testing and debugging the Ansible Tower installation.

## Files

- `ansible_install_test.sh` - Main installation script converted from SSM document
- `configure_ansible_install.sh` - Configuration helper script
- `AnsibleInstall.yaml` - Original SSM document

## Prerequisites

1. **Red Hat Developer Account**: You need valid Red Hat credentials to register and download Ansible Tower
2. **AWS CLI Configured**: The script needs access to S3 to download the Ansible Tower installer
3. **Root/Sudo Access**: The installation requires root privileges
4. **Linux Environment**: This script is designed for Red Hat/CentOS/RHEL systems

## Usage

### Option 1: Using the Configuration Helper

1. Make the scripts executable:
   ```bash
   chmod +x configure_ansible_install.sh
   chmod +x ansible_install_test.sh
   ```

2. Run the configuration helper:
   ```bash
   ./configure_ansible_install.sh
   ```

3. Source the generated environment file and run the installation:
   ```bash
   source ansible_tower_config.env
   sudo -E ./ansible_install_test.sh
   ```

### Option 2: Manual Configuration

1. Set environment variables manually:
   ```bash
   export ANSIBLE_TOWER_USERNAME="your_redhat_username"
   export ANSIBLE_TOWER_PASSWORD="your_redhat_password"
   export ANSIBLE_S3_BUCKET_NAME="your-s3-bucket-name"
   export ANSIBLE_S3_BUCKET_PREFIX="Ansible_Tower"
   export ANSIBLE_TOWER_ARCHIVE_NAME="ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz"
   ```

2. Run the installation script:
   ```bash
   sudo -E ./ansible_install_test.sh
   ```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ANSIBLE_TOWER_USERNAME` | Red Hat username for registration | Required |
| `ANSIBLE_TOWER_PASSWORD` | Red Hat password for registration | Required |
| `ANSIBLE_S3_BUCKET_NAME` | S3 bucket containing the installer | Required |
| `ANSIBLE_S3_BUCKET_PREFIX` | S3 prefix/folder path | `Ansible_Tower` |
| `ANSIBLE_TOWER_ARCHIVE_NAME` | Installer filename | `ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz` |

## Troubleshooting

### Common Issues

1. **AWS CLI not found**: The script will install AWS CLI automatically, but make sure you have internet access

2. **AWS credentials not configured**: 
   ```bash
   aws configure
   # or
   export AWS_ACCESS_KEY_ID="your_key"
   export AWS_SECRET_ACCESS_KEY="your_secret"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

3. **S3 download fails**: 
   - Verify the bucket name and file path
   - Check AWS permissions
   - Ensure the file exists in S3

4. **Red Hat registration fails**:
   - Verify your Red Hat credentials
   - Check if the system is already registered: `subscription-manager status`
   - Unregister if needed: `subscription-manager unregister`

5. **Ansible Tower setup fails**:
   - Check system requirements (minimum RAM: 2GB)
   - Verify disk space
   - Check the inventory file configuration

### Debugging

The script includes extensive logging. Look for:
- Error messages with timestamps
- File verification steps
- Inventory file content before and after modification

### Log Files

- Installation logs: Check the Ansible Tower setup output
- System logs: `/var/log/messages` or `journalctl -f`

## Differences from SSM Document

1. **Parameters**: SSM parameters are replaced with environment variables
2. **Error Handling**: Enhanced error handling and logging
3. **Debugging**: Added file verification and content display
4. **Flexibility**: Can be run independently without SSM

## Testing Recommendations

1. **Test on a clean system**: Use a fresh VM or container
2. **Backup important data**: The script modifies system files
3. **Monitor resources**: Ensure adequate RAM and disk space
4. **Check network**: Verify internet connectivity for downloads

## Security Notes

- The script handles sensitive passwords - ensure proper file permissions
- The configuration file contains credentials - protect it appropriately
- Consider using AWS IAM roles instead of access keys where possible
