# Ansible Playbooks and Roles

This directory contains Ansible playbooks and roles for infrastructure automation and configuration management.

## Directory Structure

```
playbooks/
├── README.md          # This file
├── site.yml           # Main site playbook
├── inventory/         # Inventory files (hosts, groups)
├── group_vars/        # Group-specific variables
├── host_vars/         # Host-specific variables
└── roles/             # Custom Ansible roles
    └── example-role/  # Example role structure
```

## Roles

Custom roles are stored in the `roles/` directory. Each role follows the standard Ansible role structure:

- `tasks/` - Main tasks for the role
- `handlers/` - Handlers triggered by notify
- `templates/` - Jinja2 templates
- `files/` - Static files to copy
- `vars/` - Role variables
- `defaults/` - Default variable values
- `README.md` - Role documentation

## Usage

### Running Playbooks

```bash
# Run the main site playbook
ansible-playbook -i inventory/hosts site.yml

# Run with specific tags
ansible-playbook -i inventory/hosts site.yml --tags "configuration"

# Run on specific hosts
ansible-playbook -i inventory/hosts site.yml --limit "webservers"

# Check mode (dry run)
ansible-playbook -i inventory/hosts site.yml --check
```

### Creating New Roles

```bash
# Create a new role structure
ansible-galaxy init roles/new-role-name
```

## Best Practices

1. **Role Organization**: Keep roles focused on a single responsibility
2. **Variable Naming**: Use descriptive names with role prefix
3. **Documentation**: Include README.md for each role
4. **Idempotency**: Ensure tasks can run multiple times safely
5. **Testing**: Test roles with different scenarios

## Integration with Terraform

These playbooks can be integrated with Terraform deployments for:
- Post-deployment configuration
- Software installation and setup
- Security hardening
- Monitoring setup

## Requirements

- Ansible 2.9 or higher
- Python 3.6 or higher on target hosts
- Appropriate SSH access and sudo permissions
