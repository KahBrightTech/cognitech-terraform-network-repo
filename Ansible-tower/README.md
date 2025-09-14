# Ansible Tower Setup and Web UI Guide

This comprehensive guide will walk you through setting up Ansible Tower (now called Red Hat Ansible Automation Platform) and provides a complete workflow from initial login to running your first GitHub playbook. This repository also contains Ansible roles and playbooks for infrastructure automation.

## Table of Contents

### Quick Start Workflow (First-Time Setup to Running Playbooks)

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Step 1: Initial Login and Setup](#step-1-initial-login-and-setup)
4. [Step 2: User and Organization Management](#step-2-user-and-organization-management)
5. [Step 3: Configure GitHub Integration](#step-3-configure-github-integration)
6. [Step 4: Create Your First Project](#step-4-create-your-first-project)
7. [Step 5: Set Up Inventory](#step-5-set-up-inventory)
8. [Step 6: Configure Credentials](#step-6-configure-credentials)
9. [Step 7: Create Job Template](#step-7-create-job-template)
10. [Step 8: Run Your First Playbook](#step-8-run-your-first-playbook)

### Repository Information

10. [Repository Structure and Roles](#repository-structure-and-roles)
11. [Available Ansible Roles](#available-ansible-roles)
12. [Using Roles and Playbooks](#using-roles-and-playbooks)
13. [Integration with Terraform](#integration-with-terraform)

### Infrastructure Connection Guide

14. [Infrastructure Connection Guide](#infrastructure-connection-guide)
    - [Connecting to AWS Accounts](#connecting-to-aws-accounts)
    - [Connecting to Linux Servers](#connecting-to-linux-servers)
    - [Connecting to Windows Servers with WinRM](#connecting-to-windows-servers-with-winrm)

### Complete Web UI Reference

15. [Complete Web UI Navigation](#complete-web-ui-navigation)
16. [Advanced Configuration Options](#advanced-configuration-options)
17. [Troubleshooting](#troubleshooting)

---

## Quick Start Summary

This guide is organized to take you from installation to running your first playbook from GitHub:

**🚀 Fast Track (Steps 1-7)**: If you have Ansible Tower already installed, jump directly to [Step 1: Initial Login](#step-1-initial-login-and-setup) and follow the numbered steps sequentially to run your first GitHub playbook in ~15 minutes.

**📚 Complete Setup**: Start with [Prerequisites](#prerequisites) and [Installation](#installation) if you need to set up Ansible Tower from scratch.

**🔍 Reference Material**: Use the [Complete Web UI Navigation](#complete-web-ui-navigation) and [Repository Information](#repository-and-integration-information) sections for detailed feature explanations and advanced configuration.

**What You'll Accomplish:**

- ✅ Connect Tower to this GitHub repository
- ✅ Set up Windows server inventory
- ✅ Configure authentication credentials
- ✅ Create and run a job template
- ✅ Deploy IIS and Chrome to Windows servers automatically

---

## Prerequisites

### System Requirements

- **Operating System**: Red Hat Enterprise Linux 8/9, CentOS 8, or Ubuntu 20.04+
- **RAM**: Minimum 4GB (8GB recommended for production)
- **CPU**: 2 cores minimum (4 cores recommended)
- **Storage**: 40GB minimum free space
- **Network**: Internet access for package downloads

### Required Accounts and Access

- **Red Hat Developer Account**: Required for downloading Ansible Automation Platform
- **AWS Account**: For S3 bucket access (if using the provided installation script)
- **Administrator/Root Access**: Required for installation

### Prerequisites Checklist

- [ ] Red Hat Developer account created
- [ ] AWS CLI configured with appropriate permissions
- [ ] Target server/VM provisioned with required specifications
- [ ] Firewall ports opened (443, 80, 5432 for PostgreSQL)

## Installation

### Method 1: Using the Provided Installation Script

The repository includes an automated installation script (`install_ansible_tower.sh`) that handles the entire setup process.

#### Step 1: Configure Environment Variables

```bash
# Set your Red Hat credentials
export ANSIBLE_TOWER_USERNAME="your_redhat_username"
export ANSIBLE_TOWER_PASSWORD="your_redhat_password"

# Configure S3 bucket settings (if using S3 for installer storage)
export ANSIBLE_S3_BUCKET_NAME="your-ansible-bucket"
export ANSIBLE_S3_BUCKET_PREFIX="Ansible_Tower"
export ANSIBLE_TOWER_ARCHIVE_NAME="ansible-automation-platform-setup-bundle-2.4-1-x86_64.tar.gz"
```

#### Step 2: Run the Installation Script

```bash
# Make the script executable
chmod +x install_ansible_tower.sh

# Run as root
sudo -E ./install_ansible_tower.sh
```

The script will:

1. Install and configure AWS CLI
2. Register with Red Hat Subscription Manager
3. Update system packages
4. Download Ansible Tower installer from S3
5. Extract and configure the installer
6. Run the Ansible Tower setup

#### Step 3: Monitor Installation Progress

The installation process typically takes 15-30 minutes. Monitor the output for:

- ✅ AWS CLI installation and verification
- ✅ Red Hat registration success
- ✅ Package updates completion
- ✅ Installer download and extraction
- ✅ Ansible Tower setup completion

### Method 2: Manual Installation

If you prefer manual installation or need to customize the process:

#### Step 1: Download Ansible Automation Platform

1. Visit the [Red Hat Customer Portal](https://access.redhat.com/)
2. Navigate to Downloads → Red Hat Ansible Automation Platform
3. Download the latest installer bundle

#### Step 2: Extract and Configure

```bash
# Extract the installer
tar -xzf ansible-automation-platform-setup-bundle-*.tar.gz
cd ansible-automation-platform-setup-bundle-*

# Edit the inventory file
cp inventory inventory.backup
vi inventory
```

#### Step 3: Configure Inventory File

Edit the inventory file with your settings:

```ini
[automationcontroller]
localhost ansible_connection=local

[database]

[all:vars]
admin_password='your_admin_password'
pg_password='your_pg_password'
registry_url='registry.redhat.io'
registry_username='your_redhat_username'
registry_password='your_redhat_password'
```

#### Step 4: Run Setup

```bash
./setup.sh
```

## Initial Access and Setup

---

## Step 1: Initial Login and Setup

### First-Time Web UI Login

1. **Access the Web Interface**

   - Open your browser and navigate to `https://your-server-ip/`
   - You may see a security warning due to self-signed certificates (this is normal for initial setup)
   - Click "Advanced" and proceed to the site
2. **Login with Default Credentials**

   - **Username**: `admin`
   - **Password**: The password you set in the configuration (default: `changeme123`)

*📸 Screenshot needed: Login page showing username/password fields*

3. **Upload License (First Login Only)**
   - Upon first login, you'll be prompted to upload your license
   - If you don't have a license, you can request a trial license from Red Hat
   - Upload your license file (.json format)

*📸 Screenshot needed: License upload dialog*

4. **Complete Initial Setup Wizard**
   - Complete the setup wizard with your organization details
   - Configure your subscription preferences
   - Set up initial user preferences

### Dashboard Overview

After login, you'll see the main dashboard with:

- Job status overview and recent activity
- Quick access to main functions
- System health indicators

---

## Step 2: User and Organization Management

Before setting up GitHub integration and projects, it's important to properly configure users, teams, and organizations in Ansible Tower. This ensures proper access control and multi-tenant environment management.

### Creating a New Organization

Organizations in Ansible Tower provide multi-tenancy and resource isolation. They help separate different teams, departments, or environments.

#### Step 2.1: Create Organization

1. **Navigate to Organizations**

   - Click "Organizations" in the left navigation menu
   - Click the "+" button to add a new organization
2. **Configure Organization Settings**

   - **Name**: "Engineering Team" (or your organization name)
   - **Description**: "Engineering team automation resources"
   - **Max Hosts**: Set the maximum number of hosts (e.g., 100)
   - **Default Environment**: Leave blank (optional)
3. **Save Organization**

   - Click "Save"
   - The organization will be created and available for resource assignment

*📸 Screenshot needed: Organization creation form*

#### Organization Best Practices

- **Naming Convention**: Use clear, descriptive names (e.g., "Production-Ops", "Dev-Team", "QA-Environment")
- **Resource Limits**: Set appropriate host limits based on your license
- **Isolation**: Keep different environments or teams in separate organizations
- **Documentation**: Use descriptions to explain the organization's purpose

### Creating New Users

User management is crucial for security and access control in Ansible Tower.

#### Step 2.2: Create User Accounts

1. **Navigate to Users**

   - Click "Users" in the left navigation menu
   - Click the "+" button to add a new user
2. **Configure User Details**

   - **Username**: `john.doe` (unique identifier)
   - **Email**: `john.doe@company.com`
   - **First Name**: `John`
   - **Last Name**: `Doe`
   - **Password**: Set a secure password
   - **Confirm Password**: Re-enter the password
3. **User Type Selection**

   - **Normal User**: Standard user with limited system access
   - **System Auditor**: Read-only access to all Tower resources
   - **System Administrator**: Full administrative access to Tower
4. **Organization Assignment**

   - **Organizations**: Select organizations the user should belong to
   - Multiple organizations can be selected
5. **Save User**

   - Click "Save"
   - The user account will be created

*📸 Screenshot needed: User creation form with all fields*

#### User Types Explained

**Normal User**

- Standard user account for day-to-day operations
- Access limited to assigned resources and organizations
- Cannot modify system-wide settings
- Can execute job templates they have access to

**System Auditor**

- Read-only access to all Tower resources across all organizations
- Useful for compliance and monitoring roles
- Cannot execute jobs or modify configurations
- Can view all inventories, projects, and job results

**System Administrator**

- Full administrative access to Ansible Tower
- Can create/modify/delete any resource
- Access to system settings and configuration
- Should be limited to a few trusted administrators

### Assigning User Permissions

Ansible Tower uses a role-based access control (RBAC) system to manage permissions.

#### Step 2.3: Assign Organization Roles

1. **Navigate to User's Organization**

   - Go to Organizations → Select your organization
   - Click the "Users" tab
   - Find your user or click "+" to add existing users
2. **Assign Organization-Level Roles**

   **Member Role**

   - Basic access to organization resources
   - Can view resources they're granted access to
   - Cannot create new resources at organization level

   **Admin Role**

   - Full administrative access within the organization
   - Can create/modify/delete organization resources
   - Can manage users and teams within the organization

   **Auditor Role**

   - Read-only access to all organization resources
   - Cannot execute jobs or modify configurations
   - Useful for compliance and monitoring
3. **Configure Role Assignment**

   - Select the user from the list
   - Choose appropriate role (Member, Admin, or Auditor)
   - Click "Save"

*📸 Screenshot needed: Organization users tab with role assignment*

#### Step 2.4: Assign Resource-Specific Permissions

For fine-grained access control, assign permissions to specific resources:

1. **Project Permissions**

   - Navigate to Projects → Select a project
   - Click "Permissions" tab
   - Click "+" to add user permissions
   - **Available Roles**:
     - **Use**: Can use project in job templates
     - **Read**: Can view project details
     - **Update**: Can modify project settings
     - **Admin**: Full project control
2. **Inventory Permissions**

   - Navigate to Inventories → Select an inventory
   - Click "Permissions" tab
   - **Available Roles**:
     - **Use**: Can use inventory in job templates
     - **Read**: Can view inventory and hosts
     - **Update**: Can modify inventory and add/remove hosts
     - **Admin**: Full inventory control
     - **Adhoc**: Can run ad-hoc commands
3. **Job Template Permissions**

   - Navigate to Templates → Select a job template
   - Click "Permissions" tab
   - **Available Roles**:
     - **Execute**: Can launch the job template
     - **Read**: Can view template configuration
     - **Update**: Can modify template settings
     - **Admin**: Full template control
4. **Credential Permissions**

   - Navigate to Credentials → Select a credential
   - Click "Permissions" tab
   - **Available Roles**:
     - **Use**: Can use credential in job templates
     - **Read**: Can view credential details (not sensitive data)
     - **Update**: Can modify credential
     - **Admin**: Full credential control

*📸 Screenshot needed: Resource permissions assignment interface*

### Creating and Managing Teams

Teams help organize users and simplify permission management.

#### Step 2.5: Create Teams

1. **Navigate to Teams**

   - Click "Teams" in the left navigation menu
   - Click the "+" button to create a new team
2. **Configure Team Settings**

   - **Name**: "Web Development Team"
   - **Description**: "Team responsible for web application deployment"
   - **Organization**: Select the appropriate organization
3. **Add Team Members**

   - In the team details, click "Users" tab
   - Click "+" to add existing users to the team
   - Select users and assign them to the team
4. **Assign Team Permissions**

   - Teams can be granted permissions to resources
   - All team members inherit team permissions
   - Navigate to any resource (Project, Inventory, etc.)
   - Add the team to the resource permissions

*📸 Screenshot needed: Team creation and member assignment*

#### Team Permission Examples

**Development Team Permissions**:

```
Projects:
- Development Projects: Use, Read, Update
- Production Projects: Read only

Inventories:
- Development Servers: Use, Read, Update, Adhoc
- Production Servers: Read only

Job Templates:
- Development Deployments: Execute, Read, Update
- Production Deployments: Read only
```

**Operations Team Permissions**:

```
Projects:
- All Projects: Use, Read, Update, Admin

Inventories:
- All Inventories: Use, Read, Update, Admin, Adhoc

Job Templates:
- All Templates: Execute, Read, Update, Admin

Credentials:
- Infrastructure Credentials: Use, Read
```

### Permission Management Best Practices

#### Security Best Practices

1. **Principle of Least Privilege**

   - Grant minimum permissions necessary for job function
   - Review permissions regularly
   - Remove access when users change roles
2. **Role Hierarchy**

   ```
   System Administrator (Few users)
   ↓
   Organization Admin (Department leads)
   ↓
   Team Admin (Team leads)
   ↓
   Normal Users (Team members)
   ↓
   System Auditor (Compliance/monitoring)
   ```
3. **Team-Based Permissions**

   - Use teams for consistent permission sets
   - Assign permissions to teams rather than individuals
   - Easier to manage and audit
4. **Regular Audits**

   - Review user access quarterly
   - Remove inactive users
   - Verify permission assignments

#### Access Control Examples

**Example 1: Multi-Environment Setup**

```
Organizations:
- Production-Ops
- Development-Team
- QA-Team

Users:
- prod-admin (System Admin)
- dev-lead (Development-Team Admin)
- qa-lead (QA-Team Admin)
- developer1 (Development-Team Member)
- tester1 (QA-Team Member)
```

**Example 2: Project-Based Access**

```
Project: Web Application Deployment
- Development Team: Execute, Read, Update
- QA Team: Execute, Read
- Operations Team: Execute, Read, Update, Admin
- Security Team: Read (audit access)
```

**Example 3: Environment Isolation**

```
Production Environment:
- Only Operations Team has full access
- Development Team has read-only access
- QA Team has no access

Development Environment:
- Development Team has full access
- QA Team has execute access
- Operations Team has admin access
```

### User Management Workflow

#### Step 2.6: Complete User Setup Workflow

1. **Create Organization** (if needed)

   - Define organization structure
   - Set resource limits
2. **Create User Account**

   - Add user with appropriate user type
   - Assign to organization(s)
3. **Assign Base Permissions**

   - Set organization role (Member/Admin/Auditor)
   - Add to appropriate teams
4. **Grant Resource Access**

   - Assign project permissions
   - Grant inventory access
   - Provide credential usage rights
   - Enable job template execution
5. **Test Access**

   - Have user log in and verify access
   - Test job template execution
   - Verify resource visibility
6. **Document Access**

   - Record permission assignments
   - Document team memberships
   - Note any special access requirements

### Common Permission Scenarios

#### Scenario 1: New Developer Onboarding

```yaml
User: new-developer
Organization: Development-Team (Member)
Team: Frontend-Developers
Permissions:
  - Development Projects: Use, Read
  - Development Inventory: Use, Read
  - Development Credentials: Use
  - Development Job Templates: Execute, Read
  - Production Resources: Read only (for reference)
```

#### Scenario 2: DevOps Engineer

```yaml
User: devops-engineer
Organization: Operations (Admin)
Teams: 
  - Infrastructure-Team
  - Deployment-Team
Permissions:
  - All Projects: Use, Read, Update
  - All Inventories: Use, Read, Update, Adhoc
  - Infrastructure Credentials: Use, Read, Update
  - All Job Templates: Execute, Read, Update
```

#### Scenario 3: Security Auditor

```yaml
User: security-auditor
User Type: System Auditor
Organizations: All (Auditor role)
Permissions:
  - All Resources: Read only
  - Job History: Read access
  - Audit Logs: Read access
  - No Execute permissions
```

#### Scenario 4: Contractor/Temporary Access

```yaml
User: contractor-temp
Organization: Project-Team (Member)
Permissions:
  - Specific Project: Use, Read
  - Limited Inventory: Use, Read
  - Shared Credentials: Use only
  - Specific Templates: Execute only
  - Time-limited access (manual removal after project)
```

---

## Step 3: Configure GitHub Integration

Before creating projects, you need to set up credentials for GitHub access.

### Create GitHub Credentials

1. **Navigate to Credentials**

   - Click "Credentials" in the left navigation menu
   - Click the "+" button to add new credentials
2. **Configure Source Control Credentials**

   - **Name**: "GitHub Access Token"
   - **Organization**: Default (or your organization)
   - **Credential Type**: "Source Control"
   - **Username**: Your GitHub username
   - **Password/Token**: Your GitHub Personal Access Token
3. **Generate GitHub Personal Access Token** (if needed)

   - Go to GitHub.com → Settings → Developer settings → Personal access tokens
   - Generate new token with `repo` scope permissions
   - Copy the token and paste it as the password in Tower

*📸 Screenshot needed: Credential creation form*

---

## Step 4: Create Your First Project

Projects in Tower connect to your source control repository containing playbooks.

### Create Project from This Repository

1. **Navigate to Projects**

   - Click "Projects" in the left navigation menu
   - Click the "+" button to create a new project
2. **Configure Project Settings**

   - **Name**: "Cognitech Infrastructure Automation"
   - **Description**: "Windows server automation playbooks"
   - **Organization**: Default
   - **Source Control Credential Type**: Git
   - **Source Control URL**: `https://github.com/KahBrightTech/cognitech-terraform-network-repo.git`
   - **Source Control Branch/Tag/Commit**: `main`
   - **Source Control Credential**: Select "GitHub Access Token" (created in Step 2)
3. **Update Options**

   - ☑️ Clean
   - ☑️ Delete on Update
   - ☑️ Update Revision on Launch
4. **Save and Sync**

   - Click "Save"
   - Wait for the project to sync (green indicator means success)

*📸 Screenshot needed: Project creation form*

---

## Step 5: Set Up Inventory

Inventory defines the hosts where your playbooks will run.

### Create Windows Server Inventory

1. **Navigate to Inventories**

   - Click "Inventories" in the left navigation menu
   - Click the "+" button → "Inventory"
2. **Configure Inventory**

   - **Name**: "Windows Servers"
   - **Description**: "Windows servers for automation"
   - **Organization**: Default
3. **Add Hosts**

   - Click on your newly created inventory
   - Click "Hosts" tab
   - Click "+" to add hosts
   - **Host Name**: `windows-server-01`
   - **Variables** (in YAML format):

   ```yaml
   ansible_host: 10.0.1.10
   ansible_connection: winrm
   ansible_winrm_transport: ntlm
   ansible_winrm_server_cert_validation: ignore
   ansible_port: 5986
   ```
4. **Add More Hosts** (repeat as needed)

*📸 Screenshot needed: Inventory host configuration*

---

## Step 6: Configure Credentials

Set up authentication credentials for connecting to your Windows servers.

### Create Windows Machine Credentials

1. **Navigate to Credentials**

   - Click "Credentials" in the left navigation menu
   - Click the "+" button
2. **Configure Windows Credentials**

   - **Name**: "Windows Administrator"
   - **Description**: "Admin credentials for Windows servers"
   - **Organization**: Default
   - **Credential Type**: "Machine"
   - **Username**: `Administrator`
   - **Password**: Your Windows admin password
3. **Save Credentials**

   - Click "Save"

*📸 Screenshot needed: Machine credential form*

---

## Step 7: Create Job Template

Job Templates define how playbooks are executed.

### Create Your First Job Template

1. **Navigate to Templates**

   - Click "Templates" in the left navigation menu
   - Click the "+" button → "Job Template"
2. **Configure Job Template**

   - **Name**: "Windows Server Setup"
   - **Description**: "Install IIS and Chrome on Windows servers"
   - **Job Type**: Run
   - **Inventory**: "Windows Servers"
   - **Project**: "Cognitech Infrastructure Automation"
   - **Playbook**: `windows-setup.yml`
   - **Credentials**: "Windows Administrator"
   - **Verbosity**: 1 (Verbose)
3. **Advanced Options**

   - ☑️ Enable Privilege Escalation (if needed)
   - ☑️ Prompt on Launch → Extra Variables (optional)
4. **Save Template**

   - Click "Save"

*📸 Screenshot needed: Job template configuration*

---

## Step 8: Run Your First Playbook

Now execute your first automated deployment!

### Launch the Job

1. **Launch Job Template**

   - From the Templates list, click the "🚀" (rocket) icon next to "Windows Server Setup"
   - Or click on the template name and then "Launch"
2. **Monitor Job Execution**

   - You'll be redirected to the job output page
   - Watch real-time output as the playbook executes
   - Green checkmarks indicate successful tasks
   - Red X marks indicate failures
3. **Job Results**

   - **Success**: All tasks completed successfully
   - **Failed**: Check the error output for troubleshooting
   - **Running**: Job is still in progress
4. **View Job Details**

   - Click on individual tasks to see detailed output
   - Use the job history to track all executions
   - Access logs for debugging

*📸 Screenshot needed: Job execution output*

### Verify Results

After successful completion:

1. **Check Windows Servers**

   - IIS should be installed and running
   - Self-signed SSL certificate configured
   - Chrome browser installed
2. **Access IIS**

   - Navigate to `https://your-server-ip`
   - You should see the IIS welcome page

**🎉 Congratulations! You've successfully run your first Ansible playbook from GitHub using Tower!**

---

## Complete Web UI Navigation

The Ansible Tower web interface is organized into several main sections. Below is comprehensive coverage of every menu option and feature.

### Navigation Menu Structure

The left navigation panel contains the following main sections:

1. **Dashboard** - Overview and quick access
2. **Jobs** - Job management and history
3. **Schedules** - Automated job scheduling
4. **Projects** - Source code management
5. **Inventories** - Host and group management
6. **Credentials** - Authentication management
7. **Templates** - Job and workflow templates
8. **Organizations** - Multi-tenancy management
9. **Users** - User account management
10. **Teams** - Team and role management
11. **Settings** - System configuration

*📸 Screenshot needed: Main navigation menu expanded*

### Complete Feature Reference

This section provides detailed explanations of every web UI feature and navigation option.

### 1. Dashboard

The Dashboard provides a comprehensive overview of your Ansible Tower environment.

#### Main Dashboard Elements

**Job Status Overview**

- Recent job activity graph
- Success/failure rates
- Running jobs counter
- Failed jobs alerts

*📸 Screenshot needed: Dashboard overview with job statistics*

**Quick Actions Panel**

- Launch Job Template button
- Launch Workflow button
- Quick access to recent templates

**System Information**

- Tower version
- License information
- Subscription status
- System health indicators

#### Dashboard Navigation Options

- **Refresh Data**: Updates dashboard metrics in real-time
- **Time Range Selector**: Choose different time periods for job statistics
- **Filter Options**: Filter by organization, project, or job type

### 2. Jobs Section

The Jobs section manages all job execution and monitoring.

#### 2.1 Jobs List View

**Column Information**

- **ID**: Unique job identifier
- **Name**: Job template name
- **Status**: Current job status (Successful, Failed, Running, Pending)
- **Type**: Job type (Job Template, Workflow, Ad Hoc)
- **Started**: Job start time
- **Finished**: Job completion time
- **Templates**: Associated template

*📸 Screenshot needed: Jobs list view with various job statuses*

**Action Buttons**

- **Launch**: Start a new job
- **Relaunch**: Restart a previous job
- **Cancel**: Stop a running job
- **Delete**: Remove job history

#### 2.2 Job Details View

When you click on a specific job, you'll see:

**Job Information Panel**

- Job template details
- Launch user and time
- Execution environment
- Inventory used
- Credentials applied

**Job Output Console**

- Real-time Ansible playbook output
- Color-coded status indicators
- Expandable task details
- Error highlighting

*📸 Screenshot needed: Job details view showing console output*

**Job Statistics**

- Total tasks executed
- Success/failure counts
- Execution time breakdown
- Host statistics

### 3. Schedules Section

Manage automated job execution.

#### 3.1 Schedules List

**Schedule Properties**

- **Name**: Schedule identifier
- **Type**: Job Template or Workflow
- **Next Run**: Next scheduled execution
- **Frequency**: Recurring pattern
- **Enabled**: Active status toggle

*📸 Screenshot needed: Schedules list with various recurring patterns*

#### 3.2 Creating a New Schedule

**Schedule Configuration Options**

- **Name and Description**: Identification fields
- **Start Date/Time**: Initial execution time
- **Local Time Zone**: Time zone selection
- **Repeat Frequency**: Options include:
  - None (run once)
  - Minute
  - Hour
  - Day
  - Week
  - Month
  - Year

**Advanced Repeat Options**

- Custom intervals (every X hours/days/weeks)
- Specific weekdays
- Month-specific patterns
- End date configuration

*📸 Screenshot needed: Schedule creation dialog with frequency options*

### 4. Projects Section

Manage source code repositories and project synchronization.

#### 4.1 Projects List

**Project Information**

- **Name**: Project identifier
- **Description**: Project purpose
- **Organization**: Associated organization
- **SCM Type**: Source control type (Git, SVN, etc.)
- **SCM URL**: Repository URL
- **Status**: Sync status and last update

*📸 Screenshot needed: Projects list showing different SCM types*

#### 4.2 Project Configuration

**Source Control Options**

- **Git**: GitHub, GitLab, Bitbucket repositories
- **Subversion**: SVN repositories
- **Red Hat Insights**: Integration with Red Hat Insights
- **Archive**: Upload ZIP/TAR files

**Project Settings**

- **SCM Branch/Tag/Commit**: Specific version control
- **SCM Credential**: Authentication for private repositories
- **Update Revision on Launch**: Auto-sync before jobs
- **Delete on Update**: Clean workspace before sync
- **Cache Timeout**: How long to cache project data

*📸 Screenshot needed: Project creation form with SCM options*

#### 4.3 Project Synchronization

**Manual Sync Options**

- **Update Project**: Refresh from source
- **View Sync Output**: See synchronization logs
- **Schedule Sync**: Automate project updates

### 5. Inventories Section

Manage hosts, groups, and variables for your infrastructure.

#### 5.1 Inventories List

**Inventory Types**

- **Inventory**: Static host definitions
- **Smart Inventory**: Dynamic host filtering
- **Constructed Inventory**: Generated from other inventories

**Inventory Information**

- **Name**: Inventory identifier
- **Organization**: Associated organization
- **Type**: Inventory type indicator
- **Total Hosts**: Number of managed hosts
- **Total Groups**: Number of host groups
- **Has Active Failures**: Error indicator

*📸 Screenshot needed: Inventories list showing different types*

#### 5.2 Inventory Management

**Hosts Tab**

- **Add Hosts**: Manual host addition
- **Import Hosts**: Bulk host import
- **Host Details**: Individual host configuration
- **Host Variables**: YAML/JSON variable definition

*📸 Screenshot needed: Hosts tab with host list and variables*

**Groups Tab**

- **Create Groups**: Organizational host grouping
- **Nested Groups**: Hierarchical group structure
- **Group Variables**: Shared group settings
- **Group Relationships**: Parent/child group management

**Sources Tab**

- **Inventory Sources**: Dynamic inventory providers
- **Cloud Providers**: AWS, Azure, GCP integration
- **Custom Scripts**: Dynamic inventory scripts
- **Sync Status**: Source synchronization status

*📸 Screenshot needed: Inventory sources configuration*

#### 5.3 Smart Inventories

**Smart Inventory Features**

- **Host Filters**: Advanced host selection criteria
- **Search Syntax**: Ansible facts-based filtering
- **Dynamic Updates**: Automatic host list updates
- **Variable Inheritance**: Inherited from source inventories

### 6. Credentials Section

Manage authentication information for various systems.

#### 6.1 Credential Types

**Machine Credentials**

- SSH key authentication
- Username/password authentication
- Privilege escalation settings
- SSH key passphrase protection

**Cloud Credentials**

- **Amazon Web Services**: Access/secret keys, STS tokens
- **Microsoft Azure**: Service principal, subscription info
- **Google Cloud Platform**: Service account authentication
- **OpenStack**: Keystone authentication

**Source Control Credentials**

- **Git**: Username/password, SSH keys
- **Subversion**: Username/password authentication

**Network Credentials**

- Network device authentication
- SNMP credentials
- Custom network protocols

*📸 Screenshot needed: Credential types selection menu*

#### 6.2 Credential Management

**Creating Credentials**

- **Credential Type**: Select appropriate type
- **Organization**: Assign to organization
- **Name and Description**: Identification
- **Credential Details**: Type-specific fields

**Security Features**

- **Encrypted Storage**: All sensitive data encrypted
- **Role-Based Access**: Control credential visibility
- **Audit Trail**: Track credential usage
- **External Credential Storage**: Integration with external vaults

*📸 Screenshot needed: Credential creation form for AWS credentials*

### 7. Templates Section

Define reusable job configurations and workflows.

#### 7.1 Template Types

**Job Templates**

- Single playbook execution
- Parameter customization
- Survey prompts for user input
- Credential combinations

**Workflow Job Templates**

- Multi-step job orchestration
- Conditional execution paths
- Success/failure handling
- Complex automation workflows

*📸 Screenshot needed: Template types selection*

#### 7.2 Job Template Configuration

**Basic Settings**

- **Name and Description**: Template identification
- **Job Type**: Run or Check (dry-run)
- **Inventory**: Target hosts
- **Project**: Source code repository
- **Playbook**: Ansible playbook file
- **Credentials**: Authentication methods

**Advanced Options**

- **Forks**: Parallel execution limit
- **Limit**: Host subset filtering
- **Verbosity**: Output detail level
- **Job Slicing**: Parallel job distribution
- **Timeout**: Maximum execution time

*📸 Screenshot needed: Job template configuration form*

**Prompt Options**

- **Prompt on Launch**: User input fields
- **Survey**: Custom input forms
- **Variable Prompts**: Runtime variable input
- **Credential Prompts**: Runtime credential selection

#### 7.3 Workflow Templates

**Workflow Designer**

- **Visual Workflow Editor**: Drag-and-drop interface
- **Node Types**: Job templates, project sync, inventory sync
- **Convergence**: Multiple paths leading to single node
- **Approval Nodes**: Manual intervention points

*📸 Screenshot needed: Workflow designer interface*

**Workflow Logic**

- **Success Paths**: Green connections
- **Failure Paths**: Red connections
- **Always Paths**: Blue connections
- **Conditional Logic**: Advanced routing rules

### 8. Organizations Section

Manage multi-tenant environments and resource segregation.

#### 8.1 Organization Management

**Organization Properties**

- **Name and Description**: Organization identification
- **Max Hosts**: Host limit enforcement
- **Custom Virtual Environment**: Python environment selection
- **Instance Groups**: Execution environment assignment

**Organization Resources**

- **Users**: Assigned organization members
- **Admins**: Organization administrators
- **Projects**: Associated source code
- **Inventories**: Managed infrastructure
- **Job Templates**: Available automation
- **Teams**: Organized user groups

*📸 Screenshot needed: Organization details with resource tabs*

#### 8.2 Multi-Tenancy Features

**Resource Isolation**

- Organization-specific visibility
- Cross-organization sharing controls
- Resource access permissions
- Audit trail segregation

### 9. Users Section

Manage user accounts and access permissions.

#### 9.1 User Management

**User Properties**

- **Username**: Login identifier
- **Email**: Contact information
- **First/Last Name**: Display name
- **Superuser**: Administrative privileges
- **System Auditor**: Read-only system access

**Authentication Options**

- **Local Authentication**: Tower-managed passwords
- **LDAP Integration**: Active Directory integration
- **SAML**: Single sign-on capabilities
- **Social Authentication**: OAuth providers

*📸 Screenshot needed: User management interface*

#### 9.2 User Permissions

**Organization Roles**

- **Member**: Basic organization access
- **Admin**: Organization administration
- **Auditor**: Read-only organization access

**Object-Level Permissions**

- **Use**: Execute resources
- **Read**: View resource details
- **Update**: Modify resources
- **Delete**: Remove resources
- **Admin**: Full resource control

### 10. Teams Section

Organize users and manage group permissions.

#### 10.1 Team Management

**Team Properties**

- **Name and Description**: Team identification
- **Organization**: Associated organization
- **Members**: Team user list

**Team Permissions**

- **Inherited Permissions**: From organization roles
- **Direct Permissions**: Specific resource access
- **Role Assignment**: Team-level role grants

*📸 Screenshot needed: Team management with permissions matrix*

### 11. Settings Section

Configure system-wide Tower settings and integrations.

#### 11.1 Authentication Settings

**Authentication Methods**

- **Local Users**: Built-in authentication
- **LDAP Configuration**: Active Directory integration
- **RADIUS**: Network authentication
- **TACACS+**: Device authentication
- **SAML**: Single sign-on setup
- **Social Auth**: GitHub, Google, Azure AD

*📸 Screenshot needed: Authentication settings configuration*

#### 11.2 System Settings

**General Settings**

- **Custom Logo**: Branding customization
- **Custom Login Info**: Login page messaging
- **Activity Stream**: Audit logging configuration
- **Cleanup Jobs**: Automatic job history removal

**Notification Settings**

- **Email**: SMTP configuration
- **Slack**: Webhook integration
- **Webhook**: Custom HTTP notifications
- **Grafana**: Metrics integration

**Job Settings**

- **Default Job Timeout**: System-wide timeout
- **Default Inventory Update Timeout**: Sync timeout
- **Job Event Cleanup**: Event history management
- **Activity Stream Settings**: Audit configuration

#### 11.3 License and Subscription

**License Management**

- **Current License**: License details
- **Host Count**: Used vs. available hosts
- **Expiration**: License expiry date
- **Upload New License**: License replacement

## Advanced Configuration Options

### Initial Configuration Checklist

After installation, complete these configuration steps:

#### 1. Organization Setup

- [ ] Create organizations for different teams/environments
- [ ] Define resource allocation limits
- [ ] Configure custom virtual environments if needed

#### 2. User and Team Management

- [ ] Configure authentication method (LDAP/SAML)
- [ ] Create user accounts
- [ ] Organize users into teams
- [ ] Assign appropriate permissions

#### 3. Credential Configuration

- [ ] Add machine credentials for SSH access
- [ ] Configure cloud provider credentials
- [ ] Set up source control credentials
- [ ] Test credential connectivity

#### 4. Project Setup

- [ ] Add source code repositories
- [ ] Configure project synchronization
- [ ] Test playbook access
- [ ] Set up automatic updates

#### 5. Inventory Configuration

- [ ] Create static inventories
- [ ] Configure dynamic inventory sources
- [ ] Set up smart inventories
- [ ] Verify host connectivity

#### 6. Template Creation

- [ ] Create job templates for common tasks
- [ ] Configure surveys for user input
- [ ] Set up workflow templates for complex automation
- [ ] Test template execution

### Best Practices

#### Security Best Practices

1. **Use Role-Based Access Control**: Implement least privilege principle
2. **Secure Credentials**: Use external credential storage when possible
3. **Enable Audit Logging**: Monitor all user activities
4. **Regular License Updates**: Keep subscriptions current
5. **Network Security**: Implement proper firewall rules

#### Operational Best Practices

1. **Project Organization**: Use clear naming conventions
2. **Template Standards**: Implement consistent template patterns
3. **Inventory Management**: Keep inventories up-to-date
4. **Job Monitoring**: Set up notifications for critical jobs
5. **Regular Backups**: Backup Tower configuration and database

---

## Infrastructure Connection Guide

This comprehensive section covers connecting Ansible Tower to your infrastructure, including AWS accounts, Linux servers, and Windows servers with WinRM configuration.

### Connecting to AWS Accounts

#### Prerequisites for AWS Integration

Before setting up AWS integration, ensure you have:

- **AWS Account**: Active AWS account with appropriate permissions
- **IAM Access**: Permission to create IAM users, roles, and policies
- **Network Access**: Ansible Tower can reach AWS API endpoints
- **Target Instances**: EC2 instances with appropriate security groups

#### Method 1: IAM User with Access Keys (Development/Testing)

**Step 1: Create Dedicated IAM User**

1. **Create Service Account**:
   ```bash
   # Using AWS CLI
   aws iam create-user --user-name ansible-tower-service
   
   # Add user to appropriate group (if exists)
   aws iam add-user-to-group --user-name ansible-tower-service --group-name ansible-operators
   ```

2. **Create Access Keys**:
   ```bash
   aws iam create-access-key --user-name ansible-tower-service
   ```
   
   Save the output securely - you'll need both `AccessKeyId` and `SecretAccessKey`.

**Step 2: Attach Required Policies**

Create a custom policy for least privilege access:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EC2Management",
            "Effect": "Allow",
            "Action": [
                "ec2:Describe*",
                "ec2:StartInstances",
                "ec2:StopInstances",
                "ec2:RebootInstances",
                "ec2:GetConsoleOutput",
                "ec2:GetPasswordData"
            ],
            "Resource": "*"
        },
        {
            "Sid": "DynamicInventory",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeImages",
                "ec2:DescribeKeyPairs",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSubnets",
                "ec2:DescribeVpcs",
                "ec2:DescribeRegions",
                "ec2:DescribeAvailabilityZones"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SSMAccess",
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeInstances",
                "ssm:DescribeInstanceInformation",
                "ssm:SendCommand",
                "ssm:ListCommands",
                "ssm:ListCommandInvocations",
                "ssm:GetCommandInvocation"
            ],
            "Resource": "*"
        },
        {
            "Sid": "S3Access",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::your-ansible-bucket/*",
                "arn:aws:s3:::your-ansible-bucket"
            ]
        }
    ]
}
```

**Step 3: Apply the Policy**

```bash
# Save policy as ansible-tower-policy.json, then:
aws iam create-policy --policy-name AnsibleTowerExecutionPolicy --policy-document file://ansible-tower-policy.json

# Attach to user
aws iam attach-user-policy --user-name ansible-tower-service --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/AnsibleTowerExecutionPolicy
```

#### Method 2: IAM Role (Production Recommended)

**Step 1: Create IAM Role**

```bash
# Create trust policy for EC2
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

# Create the role
aws iam create-role --role-name AnsibleTowerExecutionRole --assume-role-policy-document file://trust-policy.json
```

**Step 2: Attach Policies to Role**

```bash
# Attach the custom policy created earlier
aws iam attach-role-policy --role-name AnsibleTowerExecutionRole --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/AnsibleTowerExecutionPolicy

# Create instance profile
aws iam create-instance-profile --instance-profile-name AnsibleTowerInstanceProfile

# Add role to instance profile
aws iam add-role-to-instance-profile --instance-profile-name AnsibleTowerInstanceProfile --role-name AnsibleTowerExecutionRole
```

**Step 3: Attach to Ansible Tower Instance**

```bash
# Attach instance profile to your Ansible Tower EC2 instance
aws ec2 associate-iam-instance-profile --instance-id i-YOUR_INSTANCE_ID --iam-instance-profile Name=AnsibleTowerInstanceProfile
```

#### Adding AWS Credentials to Ansible Tower

**For Access Keys Method**:

1. Navigate to **Credentials** → **+** → **Add**
2. Configure:
   - **Name**: `AWS Production Account`
   - **Description**: `AWS credentials for EC2 management`
   - **Organization**: Your organization
   - **Credential Type**: `Amazon Web Services`
   - **Access Key**: Your AWS Access Key ID
   - **Secret Key**: Your AWS Secret Access Key
   - **STS Token**: Leave blank (unless using temporary credentials)

**For IAM Role Method**:

1. Same steps as above, but leave **Access Key** and **Secret Key** blank
2. The EC2 instance will automatically use the attached IAM role

#### Configuring Dynamic AWS Inventory

**Step 1: Create Dynamic Inventory**

1. **Inventories** → **+** → **Inventory**
2. **Name**: `AWS Dynamic Inventory - Production`
3. **Description**: `Auto-discovered production EC2 instances`

**Step 2: Add Inventory Source**

1. Click **Sources** tab → **+**
2. Configure:
   - **Name**: `AWS EC2 Auto-Discovery`
   - **Source**: `Amazon EC2`
   - **Credential**: Select your AWS credential
   - **Regions**: `us-east-1,us-west-2` (your regions)
   - **Instance Filters**: 
     ```yaml
     instance-state-name: running
     tag:Environment: production
     ```
   - **Update on Launch**: ✅
   - **Overwrite**: ✅
   - **Cache Timeout**: `300` seconds

**Step 3: Test the Connection**

```bash
# Manual test (from Ansible Tower server)
ansible-inventory -i aws_ec2.yml --list

# Test with Ansible Tower credential
# This will be done automatically when you sync the inventory
```

### Connecting to Linux Servers

#### Prerequisites for Linux Connection

- **SSH Access**: SSH service running on target servers (usually port 22)
- **User Account**: Dedicated service account with appropriate sudo privileges
- **Network Access**: Ansible Tower can reach Linux servers on SSH port
- **SSH Keys**: Key-based authentication configured (recommended)

#### Method 1: SSH Key Authentication (Recommended)

**Step 1: Generate SSH Key Pair on Ansible Tower**

```bash
# On Ansible Tower server, as awx user or service account
sudo -u awx ssh-keygen -t rsa -b 4096 -C "ansible-tower@your-domain.com" -f /var/lib/awx/.ssh/ansible_tower_rsa

# Set proper permissions
sudo chown awx:awx /var/lib/awx/.ssh/ansible_tower_rsa*
sudo chmod 600 /var/lib/awx/.ssh/ansible_tower_rsa
sudo chmod 644 /var/lib/awx/.ssh/ansible_tower_rsa.pub
```

**Step 2: Create Service User on Target Linux Servers**

```bash
# On each target Linux server
# Create dedicated ansible user
sudo useradd -m -s /bin/bash ansible-svc
sudo usermod -aG wheel ansible-svc  # For RHEL/CentOS
# OR
sudo usermod -aG sudo ansible-svc   # For Ubuntu/Debian

# Set up SSH directory
sudo mkdir -p /home/ansible-svc/.ssh
sudo chmod 700 /home/ansible-svc/.ssh
sudo chown ansible-svc:ansible-svc /home/ansible-svc/.ssh
```

**Step 3: Deploy Public Key to Target Servers**

```bash
# Copy the public key content from Ansible Tower
sudo cat /var/lib/awx/.ssh/ansible_tower_rsa.pub

# On each target server, add to authorized_keys
sudo -u ansible-svc bash << 'EOF'
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDExampleKey... ansible-tower@your-domain.com" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
EOF
```

**Step 4: Configure Sudo Access**

```bash
# Create sudoers file for ansible service account
sudo visudo -f /etc/sudoers.d/ansible-svc

# Add the following content:
# Ansible Tower service account
ansible-svc ALL=(ALL) NOPASSWD:ALL

# For more restrictive access, specify only needed commands:
# ansible-svc ALL=(ALL) NOPASSWD: /bin/systemctl, /usr/bin/yum, /usr/bin/apt, /bin/cp, /bin/chown, /bin/chmod
```

**Step 5: Test SSH Connection**

```bash
# From Ansible Tower server
sudo -u awx ssh -i /var/lib/awx/.ssh/ansible_tower_rsa ansible-svc@target-server-ip

# Test sudo access
sudo -u awx ssh -i /var/lib/awx/.ssh/ansible_tower_rsa ansible-svc@target-server-ip sudo whoami
```

#### Method 2: Password Authentication (Less Secure)

**Step 1: Create Service User with Password**

```bash
# On target Linux servers
sudo useradd -m -s /bin/bash ansible-svc
sudo usermod -aG wheel ansible-svc  # or sudo group

# Set password
sudo passwd ansible-svc
# Enter a strong password
```

**Step 2: Configure SSH to Allow Password Authentication**

```bash
# Edit SSH configuration
sudo nano /etc/ssh/sshd_config

# Ensure these settings:
PasswordAuthentication yes
PermitRootLogin no
MaxAuthTries 3

# Restart SSH service
sudo systemctl restart sshd
```

#### Adding Linux Server Credentials to Ansible Tower

**For SSH Key Method**:

1. **Credentials** → **+** → **Add**
2. Configure:
   - **Name**: `Linux Servers SSH Key`
   - **Description**: `SSH key for Linux server access`
   - **Organization**: Your organization
   - **Credential Type**: `Machine`
   - **Username**: `ansible-svc`
   - **SSH Private Key**: Paste the content of `/var/lib/awx/.ssh/ansible_tower_rsa`
   - **Private Key Passphrase**: Leave blank if no passphrase
   - **Privilege Escalation Method**: `sudo`
   - **Privilege Escalation Username**: `root`

**For Password Method**:

1. Same as above, but:
   - **Password**: Enter the user password
   - Leave **SSH Private Key** blank

#### Creating Linux Server Inventory

**Static Inventory Method**:

1. **Inventories** → **+** → **Inventory**
2. **Name**: `Linux Production Servers`
3. **Hosts** tab → **+** → **Host**
4. Add each server:
   ```ini
   # Host details
   Name: web-server-01
   Description: Production web server
   Variables:
   ansible_host: 10.0.1.10
   ansible_user: ansible-svc
   ansible_become: yes
   environment: production
   role: webserver
   ```

**Dynamic Inventory with AWS Integration**:

The AWS dynamic inventory (configured above) will automatically discover Linux EC2 instances. Group them using tags:

```yaml
# In your playbooks, target by AWS tags
hosts: tag_OS_linux
# or
hosts: tag_Environment_production:&tag_OS_linux
```

### Connecting to Windows Servers with WinRM

#### Prerequisites for Windows Connection

- **Windows PowerShell 3.0+**: Required for WinRM communication
- **WinRM Service**: Windows Remote Management service enabled
- **Network Access**: Ansible Tower can reach Windows servers on WinRM ports (5985/5986)
- **User Account**: Local administrator or domain account with administrative privileges
- **Certificate**: SSL certificate for HTTPS communication (recommended)

#### Step 1: Configure WinRM on Windows Servers

**Basic WinRM Configuration**:

```powershell
# Run as Administrator on each Windows server
# Enable WinRM service
Enable-PSRemoting -Force

# Configure WinRM for HTTP (port 5985) - for testing only
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'

# Configure WinRM for HTTPS (port 5986) - recommended for production
# First, create a self-signed certificate
$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation Cert:\LocalMachine\My
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$env:COMPUTERNAME`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"

# Configure authentication methods
winrm set winrm/config/service/auth '@{Basic="true";Kerberos="true";Negotiate="true";Certificate="false";CredSSP="false"}'

# Configure WinRM settings
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="4294967295"}'
winrm set winrm/config/service '@{MaxShellsPerUser="2147483647"}'
winrm set winrm/config/service '@{MaxProcessesPerShell="2147483647"}'
winrm set winrm/config/service '@{MaxMemoryPerShellMB="2147483647"}'
winrm set winrm/config/service '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2147483647"}'

# Configure firewall rules
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
New-NetFirewallRule -DisplayName "WinRM HTTPS" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow
```

**Advanced WinRM Configuration for Production**:

```powershell
# Enhanced security configuration
winrm set winrm/config/service '@{AllowUnencrypted="false"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="1500"}'
winrm set winrm/config/service '@{EnumerationTimeoutms="240000"}'
winrm set winrm/config/service '@{MaxPacketRetrievalTimeSeconds="120"}'

# Configure client certificate authentication (optional)
winrm set winrm/config/service/auth '@{Certificate="true"}'

# Set execution policy for PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Enable PowerShell script execution
winrm set winrm/config/service '@{EnableCompatibilityHttpListener="true"}'
```

#### Step 2: Prepare SSL Certificate for HTTPS (Production)

**Option A: Self-Signed Certificate (Testing)**:

```powershell
# Create self-signed certificate with extended validity
$cert = New-SelfSignedCertificate `
    -DnsName $env:COMPUTERNAME, "localhost", "127.0.0.1" `
    -CertStoreLocation Cert:\LocalMachine\My `
    -FriendlyName "WinRM HTTPS Certificate" `
    -NotAfter (Get-Date).AddYears(5)

# Configure HTTPS listener
winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$env:COMPUTERNAME`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"
```

**Option B: Enterprise Certificate (Production)**:

```powershell
# Request certificate from domain CA
$template = "Computer" # or "WebServer"
certreq -new -f -q -config "CA-SERVER\CA-NAME" -template $template cert-request.inf cert-response.cer

# Import certificate
certreq -accept cert-response.cer

# Find certificate thumbprint
$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.Subject -like "*$env:COMPUTERNAME*"}
$cert.Thumbprint

# Configure HTTPS listener with enterprise certificate
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$env:COMPUTERNAME`";CertificateThumbprint=`"$($cert.Thumbprint)`"}"
```

#### Step 3: Create Windows Service Account

**Domain Environment**:

```powershell
# Create domain service account (run on domain controller)
New-ADUser -Name "ansible-svc" `
    -UserPrincipalName "ansible-svc@yourdomain.com" `
    -SamAccountName "ansible-svc" `
    -DisplayName "Ansible Tower Service" `
    -Description "Service account for Ansible Tower automation" `
    -PasswordNeverExpires $true `
    -CannotChangePassword $true `
    -Enabled $true

# Set password
Set-ADAccountPassword -Identity "ansible-svc" -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "YourStrongPassword123!" -Force)

# Add to necessary groups
Add-ADGroupMember -Identity "Domain Admins" -Members "ansible-svc"
# OR for limited access:
Add-ADGroupMember -Identity "Server Operators" -Members "ansible-svc"
```

**Standalone Server**:

```powershell
# Create local administrator account
$password = ConvertTo-SecureString -AsPlainText "YourStrongPassword123!" -Force
New-LocalUser -Name "ansible-svc" `
    -Password $password `
    -Description "Ansible Tower Service Account" `
    -PasswordNeverExpires `
    -UserMayNotChangePassword

# Add to Administrators group
Add-LocalGroupMember -Group "Administrators" -Member "ansible-svc"
```

#### Step 4: Test WinRM Connection

**From Ansible Tower Server**:

```bash
# Install winrm python module
sudo pip3 install pywinrm

# Test connection
python3 << 'EOF'
import winrm

# Test HTTP connection
session = winrm.Session('windows-server-ip:5985', auth=('ansible-svc', 'YourStrongPassword123!'))
result = session.run_cmd('ipconfig')
print(result.std_out.decode('utf-8'))

# Test HTTPS connection
session = winrm.Session('windows-server-ip:5986', auth=('ansible-svc', 'YourStrongPassword123!'), transport='ssl', server_cert_validation='ignore')
result = session.run_ps('Get-ComputerInfo | Select-Object WindowsProductName, TotalPhysicalMemory')
print(result.std_out.decode('utf-8'))
EOF
```

#### Step 5: Add Windows Credentials to Ansible Tower

1. **Credentials** → **+** → **Add**
2. Configure:
   - **Name**: `Windows Servers WinRM`
   - **Description**: `WinRM credentials for Windows server access`
   - **Organization**: Your organization
   - **Credential Type**: `Machine`
   - **Username**: `ansible-svc` (or `DOMAIN\ansible-svc` for domain accounts)
   - **Password**: `YourStrongPassword123!`

#### Step 6: Create Windows Server Inventory

**Static Inventory**:

1. **Inventories** → **+** → **Inventory**
2. **Name**: `Windows Production Servers`
3. **Hosts** tab → **+** → **Host**
4. Add each server:
   ```yaml
   # Host: windows-server-01
   # Variables:
   ansible_host: 10.0.1.20
   ansible_user: ansible-svc
   ansible_password: "{{ vault_windows_password }}"
   ansible_connection: winrm
   ansible_winrm_transport: ssl  # or ntlm for HTTP
   ansible_winrm_server_cert_validation: ignore  # for self-signed certs
   ansible_port: 5986  # or 5985 for HTTP
   ansible_winrm_operation_timeout_sec: 60
   ansible_winrm_read_timeout_sec: 70
   environment: production
   os_family: windows
   role: web-server
   ```

**Group Variables for Windows Servers**:

```yaml
# In Inventories → Groups → Windows_Servers → Variables
ansible_connection: winrm
ansible_winrm_transport: ssl
ansible_winrm_server_cert_validation: ignore
ansible_port: 5986
ansible_winrm_operation_timeout_sec: 60
ansible_winrm_read_timeout_sec: 70
ansible_become: no
ansible_become_method: runas
ansible_become_user: Administrator
```

#### Advanced WinRM Security Configuration

**Configure Certificate-Based Authentication**:

```powershell
# Enable certificate authentication
winrm set winrm/config/service/auth '@{Certificate="true"}'

# Create client certificate mapping (advanced setup)
winrm create winrm/config/service/certmapping?Issuer=ISSUER+Subject=SUBJECT+URI=URI '@{UserName="USERNAME";Password="PASSWORD"}'
```

**PowerShell Execution Policy**:

```powershell
# Set appropriate execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Configure PowerShell logging (optional)
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" -Name "EnableModuleLogging" -Value 1 -PropertyType DWORD -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames" -Name "*" -Value "*" -PropertyType String -Force
```

#### Troubleshooting WinRM Connection Issues

**Common Issues and Solutions**:

1. **Connection Timeout**:
   ```bash
   # Increase timeout values in inventory
   ansible_winrm_operation_timeout_sec: 120
   ansible_winrm_read_timeout_sec: 130
   ```

2. **Certificate Validation Errors**:
   ```bash
   # For self-signed certificates
   ansible_winrm_server_cert_validation: ignore
   
   # For proper certificates
   ansible_winrm_ca_trust_path: /path/to/ca-bundle.crt
   ```

3. **Authentication Failures**:
   ```powershell
   # Check WinRM authentication methods
   winrm get winrm/config/service/auth
   
   # Enable basic authentication if needed
   winrm set winrm/config/service/auth '@{Basic="true"}'
   ```

4. **Network Connectivity**:
   ```bash
   # Test port connectivity
   telnet windows-server-ip 5986
   
   # Check firewall rules
   sudo nmap -p 5985,5986 windows-server-ip
   ```

**Testing Ansible Connection**:

```bash
# Test Windows connectivity from Ansible Tower
ansible windows-servers -m win_ping -i inventory.yml
ansible windows-servers -m setup -i inventory.yml
ansible windows-servers -m win_shell -a "Get-ComputerInfo" -i inventory.yml
```

---

## Repository and Integration Information

This section provides information about the repository structure, available roles, and integration options.

## Repository Structure and Roles

This repository contains Ansible roles and playbooks for infrastructure automation, particularly focused on Windows Server configuration. The roles are organized at the repository root level for easy discovery and integration with Ansible Tower.

### Repository Structure

```
cognitech-terraform-network-repo/
├── roles/                      # Ansible roles (root level)
│   ├── iis-setup/             # IIS installation and SSL configuration
│   └── chrome-installation/   # Google Chrome installation
├── inventory/                 # Inventory files
│   └── hosts                 # Host definitions
├── windows-setup.yml         # Main Windows configuration playbook
├── ansible.cfg              # Ansible configuration
├── Ansible-tower/           # Ansible Tower documentation and setup
├── Terraform/               # Terraform infrastructure code
└── PythonScripts/          # Python automation scripts
```

### Role Discovery

Ansible automatically finds roles in the following order:

1. `./roles/` (current directory) ✅ **This repository's setup**
2. `~/.ansible/roles/`
3. `/etc/ansible/roles/`
4. Directories in `ansible.cfg` roles_path

## Available Ansible Roles

### iis-setup

Installs and configures IIS with SSL certificates:

- Installs IIS with all required features
- Creates self-signed SSL certificates
- Configures HTTPS binding on port 443
- Starts and verifies IIS service

**Role Variables:**

- `certificate_subject`: Certificate subject (default: "CN={{local-hostname}}")
- `site_name`: IIS site name (default: "Default Web Site")
- `ssl_port`: SSL port (default: 443)

**Usage in Tower:**

- Create a Project pointing to this repository
- Create a Job Template using the `windows-setup.yml` playbook
- Configure inventory with Windows hosts

### chrome-installation

Installs Google Chrome browser:

- Downloads Chrome installer
- Performs silent installation
- Verifies successful installation
- Handles alternative installation methods (MSI fallback)

**Role Variables:**

- `chrome_download_url`: Primary download URL
- `chrome_alt_url`: Alternative MSI download URL
- `temp_dir`: Temporary directory for installers
- `silent_install`: Enable silent installation
- `verify_installation`: Enable installation verification

## Using Roles and Playbooks

### Running Playbooks Locally

```bash
# From repository root directory
ansible-playbook windows-setup.yml

# With specific inventory
ansible-playbook -i inventory/hosts windows-setup.yml

# Limit to specific hosts
ansible-playbook windows-setup.yml --limit "windows-server-01"

# Check mode (dry run)
ansible-playbook windows-setup.yml --check
```

### Using with Ansible Tower

#### Setting up Projects in Tower

1. **Create a Project**:

   - Navigate to Projects → Add
   - **Name**: "Cognitech Infrastructure Automation"
   - **SCM Type**: Git
   - **SCM URL**: Your repository URL
   - **SCM Branch**: main
   - **SCM Update Options**: Check "Update Revision on Launch"
2. **Create Inventory**:

   - Navigate to Inventories → Add → Inventory
   - **Name**: "Windows Servers"
   - Add hosts manually or sync from AWS/Azure
3. **Create Job Templates**:

   - Navigate to Templates → Add → Job Template
   - **Name**: "Windows Server Setup"
   - **Job Type**: Run
   - **Inventory**: Windows Servers
   - **Project**: Cognitech Infrastructure Automation
   - **Playbook**: windows-setup.yml
   - **Credentials**: Windows credentials

#### Inventory Configuration for Windows

```ini
[windows_servers]
windows-server-01 ansible_host=10.0.1.10
windows-server-02 ansible_host=10.0.1.11

[windows_servers:vars]
ansible_user=Administrator
ansible_password={{ vault_windows_password }}
ansible_connection=winrm
ansible_winrm_transport=ntlm
ansible_winrm_server_cert_validation=ignore
ansible_port=5986
```

### Creating Custom Playbooks

Example playbook using the roles:

```yaml
---
- name: Configure Windows Server with IIS and Chrome
  hosts: windows_servers
  gather_facts: true
  
  vars:
    site_name: "Default Web Site"
    certificate_subject: "CN={{ ansible_hostname }}"
  
  roles:
    - iis-setup
    - chrome-installation
  
  post_tasks:
    - name: Display access information
      debug:
        msg: 
          - "IIS is now available at:"
          - "  HTTP:  http://{{ ansible_hostname }}"
          - "  HTTPS: https://{{ ansible_hostname }}"
          - "Google Chrome has been installed"
```

## Integration with Terraform

These Ansible roles can be integrated with Terraform for complete infrastructure automation:

### Terraform Integration Example

```hcl
# In your Terraform configuration
resource "null_resource" "configure_server" {
  provisioner "local-exec" {
    command = "ansible-playbook -i inventory/hosts windows-setup.yml --limit ${aws_instance.server.private_ip}"
  }
  
  depends_on = [aws_instance.server]
}

# Or using Ansible Tower API
resource "ansible_tower_job_template" "windows_setup" {
  name         = "Windows Server Setup"
  job_type     = "run"
  inventory    = ansible_tower_inventory.windows.id
  project      = ansible_tower_project.cognitech.id
  playbook     = "windows-setup.yml"
  
  provisioner "local-exec" {
    command = "tower-cli job launch --job-template='${ansible_tower_job_template.windows_setup.name}' --extra-vars='target_host=${aws_instance.server.private_ip}'"
  }
}
```

### Prerequisites for Integration

- Ansible 2.9+
- Windows hosts with WinRM configured
- Appropriate network access and credentials
- PowerShell 3.0+ on target Windows hosts

### Security Considerations

- Use Ansible Vault for sensitive variables
- Configure WinRM with proper certificates in production
- Store credentials securely using Tower credential types
- Implement least-privilege access for service accounts

## Troubleshooting

### Common Issues and Solutions

#### 1. Installation Issues

**Problem**: Installation fails with subscription errors
**Solution**:

- Verify Red Hat credentials
- Check subscription status
- Ensure proper network connectivity to Red Hat servers

**Problem**: Database connection errors
**Solution**:

- Verify PostgreSQL service status
- Check database credentials in inventory file
- Ensure PostgreSQL is accepting connections

#### 2. Web UI Access Issues

**Problem**: Cannot access web interface
**Solution**:

- Check if services are running: `systemctl status automation-controller`
- Verify firewall settings allow port 443/80
- Check SSL certificate validity

**Problem**: Login failures
**Solution**:

- Verify admin password in inventory file
- Check authentication configuration
- Review user account status

#### 3. Job Execution Issues

**Problem**: Jobs fail with credential errors
**Solution**:

- Verify credential configuration
- Test SSH connectivity manually
- Check privilege escalation settings

**Problem**: Playbook not found errors
**Solution**:

- Verify project synchronization status
- Check playbook path in job template
- Ensure proper file permissions

#### 4. Performance Issues

**Problem**: Slow job execution
**Solution**:

- Increase forks setting
- Check system resources (CPU, memory)
- Optimize playbook performance

**Problem**: Web UI slow response
**Solution**:

- Check database performance
- Monitor system resource usage
- Consider scaling recommendations

### Log Locations

Important log files for troubleshooting:

- **Tower Service**: `/var/log/tower/`
- **PostgreSQL**: `/var/log/postgresql/`
- **Nginx**: `/var/log/nginx/`
- **System Logs**: `/var/log/messages` or `/var/log/syslog`

### Support Resources

- **Red Hat Documentation**: [https://docs.ansible.com/](https://docs.ansible.com/)
- **Community Forums**: [https://forum.ansible.com/](https://forum.ansible.com/)
- **Red Hat Support**: Available with active subscription
- **GitHub Issues**: For community version issues

## Adding Ansible Playbooks from GitHub

Once your Ansible Tower is set up, you'll want to integrate your Ansible playbooks from GitHub repositories. This section provides a complete guide for connecting GitHub repositories to Ansible Tower.

### Step 1: Prepare Your GitHub Repository

First, ensure your GitHub repository is properly structured for Ansible Tower:

**Required Repository Structure:**

```
your-ansible-repo/
├── playbooks/
│   ├── site.yml
│   ├── webserver.yml
│   └── database.yml
├── roles/
│   ├── common/
│   ├── apache/
│   └── mysql/
├── group_vars/
├── host_vars/
└── inventory/
    └── hosts
```

**Best Practices for GitHub Repository:**

- Place playbooks in a `playbooks/` directory or root directory
- Use clear, descriptive names for your playbooks
- Include a `requirements.yml` file if you use external roles
- Add proper documentation in README files

### Step 2: Create Credentials for GitHub Access

You'll need to set up credentials in Ansible Tower to access your GitHub repository.

#### For Public Repositories:

No credentials needed, but it's still recommended to use a GitHub token for better rate limits.

#### For Private Repositories:

You'll need either SSH keys or a GitHub personal access token.

**Option A: Using SSH Keys**

1. Generate SSH key pair on your Ansible Tower server:

   ```bash
   ssh-keygen -t rsa -b 4096 -C "ansible-tower@yourcompany.com"
   ```
2. Add the public key to your GitHub repository:

   - Go to GitHub → Repository → Settings → Deploy keys
   - Click "Add deploy key"
   - Paste your public key content
   - Give it a descriptive title like "Ansible Tower Access"

**Option B: Using Personal Access Token**

1. Generate a GitHub Personal Access Token:
   - Go to GitHub → Settings → Developer settings → Personal access tokens
   - Click "Generate new token"
   - Select appropriate scopes (usually `repo` for private repos)
   - Copy the generated token

### Step 3: Add Credentials in Ansible Tower

1. **Login to Ansible Tower Web UI**

   - Navigate to `https://your-tower-server/`
   - Login with your admin credentials
2. **Create New Credential**

   - Go to **Credentials** in the left navigation
   - Click the **+** (Add) button
   - Fill in the credential details:

**For SSH Key Method:**

- **Name**: `GitHub SSH Key` (or descriptive name)
- **Description**: `SSH access to GitHub repositories`
- **Organization**: Select your organization
- **Credential Type**: `Source Control`
- **Username**: `git`
- **SSH Private Key**: Paste your private key content

**For Personal Access Token Method:**

- **Name**: `GitHub Token` (or descriptive name)
- **Description**: `Token access to GitHub repositories`
- **Organization**: Select your organization
- **Credential Type**: `Source Control`
- **Username**: Your GitHub username
- **Password**: Your personal access token

*📸 Screenshot needed: Credential creation form for GitHub access*

### Step 4: Create a Project in Ansible Tower

1. **Navigate to Projects**

   - Click **Projects** in the left navigation menu
   - Click the **+** (Add) button
2. **Configure Project Settings**

   - **Name**: `My Ansible Playbooks` (or descriptive name)
   - **Description**: `Ansible playbooks from GitHub repository`
   - **Organization**: Select your organization
   - **SCM Type**: `Git`
   - **SCM URL**: Your GitHub repository URL
     - For SSH: `git@github.com:username/repository-name.git`
     - For HTTPS: `https://github.com/username/repository-name.git`
   - **SCM Branch/Tag/Commit**: `main` (or your default branch)
   - **SCM Credential**: Select the credential you created in Step 3
3. **Additional Project Options**

   - **SCM Update Options**:
     - ☑️ **Clean**: Remove any local modifications
     - ☑️ **Delete on Update**: Delete the local repository before updating
     - ☑️ **Update Revision on Launch**: Update before each job launch
   - **Cache Timeout**: `0` (always update) or set a reasonable timeout
4. **Save the Project**

   - Click **Save**
   - The project will automatically sync from GitHub

*📸 Screenshot needed: Project creation form with GitHub repository settings*

### Step 5: Verify Project Synchronization

1. **Check Sync Status**

   - After saving, you should see the project status change to "Successful"
   - If there are issues, click on the project name to view sync logs
2. **Manual Sync (if needed)**

   - Click the sync button (↻) next to your project
   - Monitor the output for any errors

*📸 Screenshot needed: Project synchronization status and logs*

### Step 6: Create Job Templates

Now you can create job templates that use your GitHub playbooks:

1. **Navigate to Templates**

   - Click **Templates** in the left navigation
   - Click **+** and select **Job Template**
2. **Configure Job Template**

   - **Name**: `Deploy Web Server` (example)
   - **Description**: `Deploy and configure web server`
   - **Job Type**: `Run`
   - **Inventory**: Select your target inventory
   - **Project**: Select the GitHub project you created
   - **Playbook**: Select from dropdown (your playbooks will appear here)
   - **Credentials**: Select appropriate machine credentials for target hosts
   - **Verbosity**: Choose output detail level
3. **Advanced Options**

   - Configure forks, job slicing, timeouts as needed
   - Set up surveys if you want user input
   - Configure privilege escalation if needed

*📸 Screenshot needed: Job template creation with GitHub project playbook selection*

### Step 7: Test Your Setup

1. **Launch a Test Job**
   - Go to your newly created job template
   - Click the **Launch** button (🚀)
   - Monitor the job execution
   - Verify the playbook runs successfully

### Step 8: Set Up Automatic Updates (Optional)

To keep your playbooks automatically updated:

1. **Project Auto-Update**

   - In your project settings, enable "Update Revision on Launch"
   - This ensures the latest code is always used
2. **Scheduled Project Sync**

   - Go to **Schedules**
   - Create a new schedule for project synchronization
   - Set it to run periodically (e.g., every hour or daily)

### Example Configuration

Here's a complete example configuration:

**GitHub Repository**: `https://github.com/mycompany/ansible-playbooks.git`

**Project Configuration**:

```
Name: Company Ansible Playbooks
SCM Type: Git
SCM URL: https://github.com/mycompany/ansible-playbooks.git
SCM Branch: main
SCM Credential: GitHub Token
Update on Launch: ✓
```

**Job Template Configuration**:

```
Name: Deploy LAMP Stack
Project: Company Ansible Playbooks
Playbook: playbooks/lamp-stack.yml
Inventory: Production Servers
Credentials: SSH Key for Production
```

### Troubleshooting GitHub Integration

**Issue**: Project sync fails with authentication error
**Solution**:

- Verify your GitHub credentials are correct
- For private repos, ensure your token/key has proper permissions
- Check if the repository URL is correct

**Issue**: Playbooks don't appear in the dropdown
**Solution**:

- Ensure playbooks are in the correct directory structure
- Verify the project sync completed successfully
- Check that playbook files have `.yml` or `.yaml` extensions

**Issue**: Job fails with "playbook not found"
**Solution**:

- Verify the playbook path in your repository
- Ensure the project sync is up to date
- Check file permissions and naming

### GitHub Integration Best Practices

1. **Repository Organization**

   - Use clear directory structures
   - Separate playbooks, roles, and variables
   - Include documentation
2. **Version Control**

   - Use tags for stable releases
   - Create separate branches for development
   - Test playbooks before merging to main
3. **Security**

   - Use SSH keys or tokens instead of passwords
   - Limit credential access to necessary users
   - Regularly rotate access tokens
4. **Updates**

   - Set up automated project synchronization
   - Monitor sync status and failures
   - Test new playbooks in development environment first

---

## AWS Integration and Server Targeting

This section covers how to set up AWS credentials in Ansible Tower and configure playbooks to target specific servers using AWS tags.

### Setting Up AWS Credentials in Ansible Tower

#### Step 1: Create AWS IAM User or Role

**Option A: IAM User with Access Keys (Recommended for Development)**

1. **Create IAM User**:

   - Log into AWS Console → IAM → Users
   - Click "Add user"
   - Username: `ansible-tower-service`
   - Access type: ☑️ Programmatic access
   - Click "Next: Permissions"
2. **Attach Policies**:

   - **For EC2 Management**: `AmazonEC2FullAccess` or custom policy
   - **For S3 Access**: `AmazonS3ReadOnlyAccess` or `AmazonS3FullAccess`
   - **For Systems Manager**: `AmazonSSMFullAccess` (for dynamic inventories)
   - **For CloudFormation**: `CloudFormationFullAccess` (if managing infrastructure)
3. **Custom Policy Example** (Least Privilege):

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "ec2:Describe*",
                   "ec2:StartInstances",
                   "ec2:StopInstances",
                   "ec2:RebootInstances",
                   "ssm:*",
                   "s3:GetObject",
                   "s3:ListBucket"
               ],
               "Resource": "*"
           }
       ]
   }
   ```
4. **Save Access Keys**:

   - Copy the Access Key ID and Secret Access Key
   - Store them securely (you'll need them for Ansible Tower)

**Option B: IAM Role (Recommended for Production)**

1. **Create IAM Role**:

   - AWS Console → IAM → Roles → Create role
   - Select "AWS service" → "EC2"
   - Attach the same policies as above
   - Role name: `AnsibleTowerExecutionRole`
2. **Attach Role to Ansible Tower EC2 Instance**:

   - Go to EC2 Console → Instances
   - Select your Ansible Tower instance
   - Actions → Security → Modify IAM role
   - Select the role you created

#### Step 2: Add AWS Credentials in Ansible Tower

1. **Navigate to Credentials**:

   - Login to Ansible Tower Web UI
   - Go to **Credentials** in left navigation
   - Click **+** (Add) button
2. **Configure AWS Credential**:

   - **Name**: `AWS Production Account` (or descriptive name)
   - **Description**: `AWS credentials for EC2 management`
   - **Organization**: Select your organization
   - **Credential Type**: `Amazon Web Services`

**For Access Keys Method**:

- **Access Key**: Your AWS Access Key ID
- **Secret Key**: Your AWS Secret Access Key
- **STS Token**: Leave blank (unless using temporary credentials)

**For IAM Role Method**:

- Leave Access Key and Secret Key blank
- The EC2 instance will use the attached IAM role automatically

3. **Regional Settings** (Optional):
   - **Region**: Specify default AWS region (e.g., `us-east-1`)

*📸 Screenshot needed: AWS credential creation form with fields filled*

### Setting Up Dynamic AWS Inventory

#### Step 3: Create AWS Dynamic Inventory

1. **Navigate to Inventories**:

   - Go to **Inventories** in left navigation
   - Click **+** and select **Inventory**
2. **Create Base Inventory**:

   - **Name**: `AWS Dynamic Inventory`
   - **Description**: `Automatically discovered AWS EC2 instances`
   - **Organization**: Select your organization
   - Click **Save**
3. **Add Inventory Source**:

   - In your new inventory, click the **Sources** tab
   - Click **+** (Add) button
   - Configure the source:
   - **Name**: `AWS EC2 Source`
   - **Description**: `Auto-discover EC2 instances`
   - **Source**: `Amazon EC2`
   - **Credential**: Select your AWS credential
   - **Regions**: Select regions to scan (e.g., `us-east-1, us-west-2`)
   - **Instance Filters**: Use to filter instances (optional)
   - **Update on Launch**: ☑️ (recommended)
   - **Cache Timeout**: `300` (5 minutes)

*📸 Screenshot needed: AWS inventory source configuration*

#### Step 4: Configure Instance Filters (Optional)

To limit which instances are discovered, use instance filters:

**Filter Examples**:

```yaml
# Only running instances
instance-state-name: running

# Specific VPC
vpc-id: vpc-12345678

# Instances with specific tag
tag:Environment: production

# Multiple filters (AND operation)
instance-state-name: running
tag:Application: web
```

### Targeting Servers by AWS Tags

#### Method 1: Using Smart Inventories

1. **Create Smart Inventory**:

   - Go to **Inventories** → **+** → **Smart Inventory**
   - **Name**: `Production Web Servers`
   - **Description**: `Production web servers based on tags`
   - **Organization**: Select your organization
2. **Configure Host Filter**:

   - **Host Filter**: Use Ansible Tower search syntax

   **Examples**:

   ```bash
   # Target instances with specific tag
   ansible_ec2_tag_Environment:production

   # Target by multiple tags
   ansible_ec2_tag_Environment:production and ansible_ec2_tag_Role:webserver

   # Target by instance type
   ansible_ec2_instance_type:t3.medium

   # Complex filtering
   ansible_ec2_tag_Environment:production and (ansible_ec2_tag_Role:webserver or ansible_ec2_tag_Role:database)
   ```

*📸 Screenshot needed: Smart inventory creation with host filters*

#### Method 2: Using Playbook-Level Targeting

**In Your Ansible Playbooks**:

```yaml
---
- name: Configure Web Servers
  hosts: "tag_Environment_production:&tag_Role_webserver"
  become: yes
  vars:
    ansible_user: ec2-user
  
  tasks:
    - name: Install Apache
      yum:
        name: httpd
        state: present
    
    - name: Start Apache service
      service:
        name: httpd
        state: started
        enabled: yes

- name: Configure Database Servers  
  hosts: "tag_Environment_production:&tag_Role_database"
  become: yes
  vars:
    ansible_user: ec2-user
  
  tasks:
    - name: Install MySQL
      yum:
        name: mysql-server
        state: present
```

**Host Pattern Examples**:

```yaml
# Single tag
hosts: tag_Environment_production

# Multiple tags (AND)
hosts: "tag_Environment_production:&tag_Role_webserver"

# Multiple tags (OR)
hosts: "tag_Environment_production:tag_Environment_staging"

# Exclude certain tags
hosts: "tag_Environment_production:!tag_Status_maintenance"

# Combine with other patterns
hosts: "tag_Role_webserver:&us-east-1*"
```

#### Method 3: Using Group Variables by Tags

Ansible Tower automatically creates groups based on AWS tags. You can set variables for these groups:

1. **Navigate to Your Inventory**:

   - Go to the AWS Dynamic Inventory you created
   - Click the **Groups** tab
2. **Find Tag-Based Groups**:

   - Groups are automatically created like:
     - `tag_Environment_production`
     - `tag_Role_webserver`
     - `tag_Application_myapp`
3. **Set Group Variables**:

   - Click on a group (e.g., `tag_Environment_production`)
   - Go to **Variables** tab
   - Add YAML/JSON variables:

```yaml
# Variables for production environment
ansible_user: ec2-user
ansible_become: yes
log_level: info
backup_enabled: true

# Application-specific variables
app_environment: production
database_host: prod-db.company.com
redis_host: prod-redis.company.com
```

### Advanced AWS Integration Examples

#### Example 1: Multi-Environment Playbook

```yaml
---
- name: Deploy Application to Multiple Environments
  hosts: "{{ target_environment | default('tag_Environment_development') }}"
  become: yes
  vars:
    ansible_user: ec2-user
  
  tasks:
    - name: Set environment-specific variables
      set_fact:
        app_config: "{{ environment_configs[ansible_ec2_tag_Environment] }}"
      vars:
        environment_configs:
          development:
            db_host: dev-db.company.com
            log_level: debug
          staging:
            db_host: staging-db.company.com
            log_level: info
          production:
            db_host: prod-db.company.com
            log_level: warn
  
    - name: Deploy application
      template:
        src: app.conf.j2
        dest: /etc/myapp/config.yml
      notify: restart application
    
  handlers:
    - name: restart application
      service:
        name: myapp
        state: restarted
```

#### Example 2: Conditional Tasks Based on Tags

```yaml
---
- name: Server Configuration Based on Role
  hosts: tag_Environment_production
  become: yes
  
  tasks:
    - name: Install web server packages
      yum:
        name: "{{ item }}"
        state: present
      loop:
        - httpd
        - php
        - php-mysql
      when: "'webserver' in ansible_ec2_tag_Role"
    
    - name: Install database packages
      yum:
        name: "{{ item }}"
        state: present
      loop:
        - mysql-server
        - mysql
      when: "'database' in ansible_ec2_tag_Role"
    
    - name: Configure firewall for web servers
      firewalld:
        port: "{{ item }}"
        permanent: yes
        state: enabled
        immediate: yes
      loop:
        - 80/tcp
        - 443/tcp
      when: "'webserver' in ansible_ec2_tag_Role"
```

### Job Template Configuration for AWS

#### Creating Job Templates with AWS Targeting

1. **Create Job Template**:

   - **Name**: `Deploy to Production Web Servers`
   - **Inventory**: Select your AWS Dynamic Inventory or Smart Inventory
   - **Project**: Your GitHub project
   - **Playbook**: Select your playbook
   - **Credentials**:
     - Add your AWS credential
     - Add SSH credential for EC2 instances
2. **Advanced Options**:

   - **Limit**: Use to further filter hosts (e.g., `tag_Role_webserver`)
   - **Extra Variables**: Pass environment-specific variables

   ```yaml
   target_environment: tag_Environment_production
   app_version: "{{ app_version | default('latest') }}"
   ```

*📸 Screenshot needed: Job template with AWS credentials and targeting*

### Best Practices for AWS Integration

#### Security Best Practices

1. **Use IAM Roles**: Prefer IAM roles over access keys for production
2. **Least Privilege**: Grant only necessary permissions
3. **Rotate Credentials**: Regularly rotate access keys
4. **Encrypt Sensitive Data**: Use Ansible Vault for sensitive variables
5. **Network Security**: Use private subnets and bastion hosts when possible

#### Tagging Best Practices

1. **Consistent Tagging Strategy**:

   ```
   Environment: production|staging|development
   Role: webserver|database|cache|loadbalancer
   Application: myapp|billing|reporting
   Team: devops|platform|application
   CostCenter: engineering|marketing|sales
   ```
2. **Automation-Friendly Tags**:

   - Use consistent case (lowercase recommended)
   - Avoid spaces (use hyphens or underscores)
   - Use meaningful values
3. **Required Tags Policy**:

   - Enforce tagging through AWS Config rules
   - Use AWS Organizations SCPs to require tags
   - Implement cost allocation tags

#### Performance Optimization

1. **Inventory Caching**: Set appropriate cache timeouts
2. **Regional Filtering**: Limit inventory to necessary regions
3. **Instance Filtering**: Use filters to reduce inventory size
4. **Parallel Execution**: Configure appropriate fork counts
5. **Connection Optimization**: Use persistent connections when possible

### Troubleshooting AWS Integration

**Issue**: Inventory sync fails with permission errors
**Solution**:

- Verify AWS credentials have necessary permissions
- Check IAM policies include `ec2:Describe*`
- Ensure regions are accessible

**Issue**: Hosts not appearing in inventory
**Solution**:

- Check instance filters in inventory source
- Verify instances are in running state
- Confirm tags are applied to instances
- Review inventory sync logs

**Issue**: Playbook can't connect to hosts
**Solution**:

- Verify SSH credentials are correct
- Check security groups allow SSH access
- Confirm key pair is associated with instances
- Test manual SSH connection

**Issue**: Wrong hosts being targeted
**Solution**:

- Review host patterns in playbooks
- Check smart inventory filters
- Verify tag values are correct
- Use `--limit` parameter for testing

---

## Conclusion

This comprehensive guide covers Ansible Tower setup, web UI navigation, GitHub integration, and the complete repository structure for infrastructure automation. The repository includes:

- **Ansible Tower Setup**: Automated installation script and configuration
- **Ready-to-Use Roles**: IIS setup and Chrome installation roles
- **Terraform Integration**: Examples for infrastructure automation
- **Complete Documentation**: Step-by-step guides for all components

### Getting Started Quick Reference

1. **Set up Ansible Tower**: Use the provided installation script
2. **Configure Projects**: Point Tower to this repository
3. **Create Inventories**: Define your Windows server inventory
4. **Deploy Infrastructure**: Use Terraform modules from the `/Terraform` directory
5. **Configure Servers**: Run the `windows-setup.yml` playbook via Tower
6. **Monitor and Maintain**: Use Tower's dashboard for ongoing operations

### Repository Benefits

- **Complete Infrastructure as Code**: Terraform + Ansible integration
- **Standardized Roles**: Reusable components for common tasks
- **Enterprise Ready**: Designed for Ansible Tower/AWX integration
- **Well Documented**: Comprehensive guides and examples
- **Security Focused**: Best practices for credential management

For additional support or questions specific to this implementation, refer to the role-specific README files, Terraform documentation, or contact your system administrator.

**Note**: Screenshots referenced in this guide should be captured from your actual Ansible Tower installation to provide visual context for each section described above.
