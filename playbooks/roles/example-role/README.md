# Example Role

This is an example Ansible role that demonstrates the standard role structure.

## Role Structure

```
example-role/
├── README.md          # This file
├── defaults/
│   └── main.yml       # Default variables
├── files/             # Files to be copied to target hosts
├── handlers/
│   └── main.yml       # Handlers (triggered by notify)
├── tasks/
│   └── main.yml       # Main tasks
├── templates/         # Jinja2 templates
└── vars/
    └── main.yml       # Role variables (higher precedence than defaults)
```

## Usage

To use this role in a playbook:

```yaml
---
- hosts: all
  roles:
    - example-role
```

Or with variables:

```yaml
---
- hosts: all
  roles:
    - role: example-role
      example_variable: "custom_value"
```

## Variables

See `defaults/main.yml` for available variables and their default values.

## Dependencies

None

## License

MIT

## Author Information

Your organization/team
