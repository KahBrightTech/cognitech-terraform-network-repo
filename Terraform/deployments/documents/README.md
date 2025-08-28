# AWS Systems Manager Documents

This directory contains AWS Systems Manager (SSM) documents for automated software installation and configuration on Linux servers.

## DockerInstall.yaml

### Overview

The `DockerInstall.yaml` document provides comprehensive Docker and Docker Compose lifecycle management on Linux servers through AWS Systems Manager. It supports both installation and uninstallation operations with granular control over components and data preservation.

### Features

- ✅ **Multi-OS Support**: Amazon Linux 2, Amazon Linux 2023, Ubuntu, and generic Linux distributions
- ✅ **Dual Operations**: Complete install and uninstall functionality
- ✅ **Component Control**: Independent management of Docker and Docker Compose
- ✅ **Data Safety**: Optional preservation of Docker data during uninstall
- ✅ **Service Management**: Automatic Docker service configuration
- ✅ **Comprehensive Logging**: Detailed operation tracking and status reporting
- ✅ **Error Handling**: Robust error checking with graceful degradation

### Supported Operating Systems

| OS | Version | Docker Installation Method | Package Manager |
|----|---------|----------------------------|-----------------|
| Amazon Linux | 2 | `amazon-linux-extras` | `yum` |
| Amazon Linux | 2023 | `yum install docker` | `yum` |
| Ubuntu | All | Official Docker Repository | `apt-get` |
| Generic Linux | - | Fallback methods | `yum`/`apt-get` |

### Parameters

#### Core Operations

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `Operation` | String | `install` | Operation to perform: `install` or `uninstall` |

#### Installation Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `InstallDocker` | String | `true` | Whether to install Docker |
| `InstallDockerCompose` | String | `true` | Whether to install Docker Compose |

#### Uninstallation Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `UninstallDocker` | String | `true` | Whether to uninstall Docker |
| `UninstallDockerCompose` | String | `true` | Whether to uninstall Docker Compose |
| `RemoveDockerData` | String | `false` | Whether to remove Docker data (images, containers, volumes) |

### Usage Examples

#### 1. Complete Installation (Default)

```bash
aws ssm send-command \
    --document-name "DockerInstall" \
    --targets "Key=tag:Environment,Values=dev" \
    --parameters "Operation=install"
```

#### 2. Install Docker Only

```bash
aws ssm send-command \
    --document-name "DockerInstall" \
    --targets "Key=tag:Environment,Values=dev" \
    --parameters "Operation=install,InstallDocker=true,InstallDockerCompose=false"
```

#### 3. Install Docker Compose Only

```bash
aws ssm send-command \
    --document-name "DockerInstall" \
    --targets "Key=tag:Environment,Values=dev" \
    --parameters "Operation=install,InstallDocker=false,InstallDockerCompose=true"
```

#### 4. Complete Uninstall (Preserving Data)

```bash
aws ssm send-command \
    --document-name "DockerInstall" \
    --targets "Key=tag:Environment,Values=dev" \
    --parameters "Operation=uninstall,RemoveDockerData=false"
```

#### 5. Complete Uninstall (Removing All Data)

```bash
aws ssm send-command \
    --document-name "DockerInstall" \
    --targets "Key=tag:Environment,Values=dev" \
    --parameters "Operation=uninstall,RemoveDockerData=true"
```

#### 6. Uninstall Docker Only

```bash
aws ssm send-command \
    --document-name "DockerInstall" \
    --targets "Key=tag:Environment,Values=dev" \
    --parameters "Operation=uninstall,UninstallDocker=true,UninstallDockerCompose=false"
```

#### 7. Uninstall Docker Compose Only

```bash
aws ssm send-command \
    --document-name "DockerInstall" \
    --targets "Key=tag:Environment,Values=dev" \
    --parameters "Operation=uninstall,UninstallDocker=false,UninstallDockerCompose=true"
```

### Installation Process

#### Docker Installation Steps

1. **OS Detection**: Automatically detects the operating system and version
2. **Package Updates**: Updates system packages using appropriate package manager
3. **Repository Setup**: Adds official Docker repositories (Ubuntu)
4. **Package Installation**: Installs Docker using OS-specific methods
5. **Service Configuration**: Starts and enables Docker service
6. **User Management**: Adds users to docker group (when applicable)
7. **Verification**: Confirms successful installation

#### Docker Compose Installation Steps

1. **Version Detection**: Fetches latest Docker Compose version from GitHub
2. **Binary Download**: Downloads Docker Compose binary
3. **Installation**: Installs to `/usr/local/bin/docker-compose`
4. **Symlink Creation**: Creates symlink at `/usr/bin/docker-compose`
5. **Verification**: Confirms successful installation

### Uninstallation Process

#### Docker Compose Uninstallation Steps

1. **Service Discovery**: Locates running Docker Compose services
2. **Service Shutdown**: Stops all found Docker Compose services
3. **Binary Removal**: Removes Docker Compose binary and symlinks

#### Docker Uninstallation Steps

1. **Container Management**: Stops all running containers
2. **Data Cleanup**: Optionally removes images, volumes, and networks
3. **Service Management**: Stops and disables Docker service
4. **Package Removal**: Removes Docker packages using OS-specific methods
5. **Repository Cleanup**: Removes Docker repositories and GPG keys
6. **Directory Cleanup**: Optionally removes Docker data directories
7. **User Management**: Removes users from docker group

### Data Preservation

When `RemoveDockerData=false` (default for safety):

- **Preserved**: Docker images, containers, volumes, networks
- **Preserved**: Docker data directory (`/var/lib/docker`)
- **Removed**: Docker binaries, services, and configuration files

When `RemoveDockerData=true`:

- **Removed**: All Docker images, containers, volumes, networks
- **Removed**: Docker data directory (`/var/lib/docker`)
- **Removed**: Docker binaries, services, and configuration files

### Output and Logging

The document provides comprehensive logging throughout the operation:

```
[2025-08-27 10:30:15] Starting Docker and Docker Compose management...
[2025-08-27 10:30:16] Operation requested: install
[2025-08-27 10:30:17] Detected OS: Amazon Linux, Version: 2
[2025-08-27 10:30:18] Installing Docker...
[2025-08-27 10:30:25] Docker installation completed successfully
[2025-08-27 10:30:26] Installing Docker Compose...
[2025-08-27 10:30:35] Docker Compose installation completed successfully
[2025-08-27 10:30:36] Operation completed successfully!
==========================================
SYSTEM STATUS SUMMARY:
==========================================
Operation Performed: install
Operating System: Amazon Linux 2
Docker Status: INSTALLED
Docker Version: Docker version 20.10.25, build b82b9f3
Docker Service Status: active
Docker Compose Status: INSTALLED
Docker Compose Version: docker-compose version 2.21.0, build 5920eb0
==========================================
```

### Prerequisites

- **AWS Systems Manager Agent**: Must be installed and running on target instances
- **IAM Permissions**: Instances must have appropriate IAM roles for SSM operations
- **Internet Access**: Required for downloading Docker Compose and package updates
- **Root/Sudo Access**: Required for package installation and service management

### Error Handling

The document includes comprehensive error handling:

- **Graceful Degradation**: Operations continue even if non-critical steps fail
- **Detailed Error Messages**: Clear error descriptions with context
- **Rollback Safety**: Uninstall operations preserve data by default
- **Logging**: All errors are logged with timestamps

### Security Considerations

- **Package Verification**: Uses official repositories and GPG key verification
- **Service Management**: Properly configures system services
- **User Permissions**: Manages docker group membership appropriately
- **Data Protection**: Preserves user data by default during uninstall

### Troubleshooting

#### Common Issues

1. **Package Manager Conflicts**
   - **Symptom**: Installation fails due to package locks
   - **Solution**: The document includes automatic package manager availability checking

2. **Permission Errors**
   - **Symptom**: Docker commands fail with permission denied
   - **Solution**: Ensure users are added to docker group or use sudo

3. **Service Start Failures**
   - **Symptom**: Docker service fails to start
   - **Solution**: Check system logs and ensure no conflicting services

4. **Network Issues**
   - **Symptom**: Download failures
   - **Solution**: Verify internet connectivity and proxy settings

#### Log Locations

- **SSM Command Output**: Available in AWS Systems Manager Console
- **System Logs**: `/var/log/messages` or `/var/log/syslog`
- **Docker Logs**: `journalctl -u docker`

### Version Compatibility

- **Docker**: Latest stable version from official repositories
- **Docker Compose**: Latest version from GitHub releases
- **Fallback Versions**: Document includes fallback version (v2.21.0) if latest cannot be determined

### Contributing

When modifying this document:

1. Test on all supported operating systems
2. Maintain backward compatibility
3. Update this README with any new features or changes
4. Ensure comprehensive error handling
5. Add appropriate logging for troubleshooting

### License

This document is part of the Cognitech Terraform Network Repository and follows the same licensing terms.
