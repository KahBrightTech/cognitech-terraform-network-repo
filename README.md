# cognitech-terraform-network-repo
This creates all things infrastructure for cognitech
This is a test for Manuela

## Ansible Tower Dynamic Inventory Configuration

### Overview
This repository includes configuration for setting up dynamic inventory in Ansible Tower to automatically discover and group AWS EC2 instances based on their tags.

### Dynamic Inventory Setup

#### Step 1: Create Inventory in Ansible Tower
1. Navigate to **Resources** → **Inventories**
2. Click **Add** → **Add Inventory**
3. Name: `Dynamic AWS Inventory`
4. Save

#### Step 2: Add Inventory Source
1. Click on your new inventory
2. Go to **Sources** tab
3. Click **Add** → **Add Source**

#### Step 3: Configure AWS EC2 Source
- **Name**: `AWS EC2 Dynamic Source`
- **Source**: Select **Amazon EC2**
- **Credential**: Select your AWS credential
- **Regions**: Add AWS regions (e.g., `us-east-1`, `us-west-2`)

#### Step 4: Source Variables Configuration

For production servers only:
```yaml
---
# Filter for running instances with Environment=prod only
filters:
  instance-state-name: running
  tag:Environment: prod

# Create groups using compose and groups instead of keyed_groups
compose:
  ansible_host: private_ip_address
  environment: tags.Environment | default('unknown')
  instance_id: instance_id
  instance_type: instance_type
  # Create a clean group name
  env_group: tags.Environment

groups:
  # Create prod group directly
  prod: env_group == "prod"

# Use Name tag as hostname, fallback to private IP
hostnames:
  - tag:Name
  - private-ip-address

# Cache results for performance
cache: true
cache_plugin: memory
cache_timeout: 300
```

**Note**: Using `groups:` with conditional expressions instead of `keyed_groups:` ensures clean group names without unwanted prefixes or underscores.

#### Step 5: Usage
- **Sync the inventory** to discover instances
- **Target production servers** in job templates using **Limit**: `prod`
- **Schedule regular syncs** to keep inventory up-to-date

#### Prerequisites
- AWS credential configured in Ansible Tower
- EC2 instances tagged with `Environment: prod`
- Proper IAM permissions for EC2 discovery

### Group Structure
After sync, the following groups will be created:
- `prod` - All production servers with Environment=prod tag
- `all` - All discovered hosts
- `ungrouped` - Hosts without specific grouping