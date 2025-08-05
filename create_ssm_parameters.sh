#!/bin/bash

# Script to create the missing SSM parameters for Ansible installation

# Replace these with your actual Red Hat credentials
REDHAT_USERNAME="njibrigthain200"  # This already works as we can see from the logs
REDHAT_PASSWORD="your_actual_redhat_password_here"  # Replace with your real password

echo "Creating SSM parameters for Ansible installation..."

# Create the username parameter (String type)
aws ssm put-parameter \
    --name "/Standard/ansible/username" \
    --value "$REDHAT_USERNAME" \
    --type "String" \
    --description "Red Hat username for Ansible registration" \
    --overwrite

if [ $? -eq 0 ]; then
    echo "✅ Successfully created username parameter"
else
    echo "❌ Failed to create username parameter"
fi

# Create the password parameter (SecureString type for encryption)
echo "Creating SecureString password parameter..."
aws ssm put-parameter \
    --name "/Standard/ansible/password" \
    --value "$REDHAT_PASSWORD" \
    --type "SecureString" \
    --description "Red Hat password for Ansible registration (encrypted)" \
    --overwrite

if [ $? -eq 0 ]; then
    echo "✅ Successfully created SecureString password parameter"
else
    echo "❌ Failed to create password parameter"
    echo "Common issues:"
    echo "  - Missing KMS permissions"
    echo "  - Missing SSM permissions" 
    echo "  - Invalid parameter name"
fi

echo ""
echo "Verifying parameters were created..."

# Verify the parameters exist
echo "Testing username parameter (String type):"
aws ssm get-parameter --name "/Standard/ansible/username" --query "Parameter.Value" --output text
if [ $? -eq 0 ]; then
    echo "✅ Username parameter verified"
fi

echo ""
echo "Testing password parameter (SecureString type):"
aws ssm get-parameter --name "/Standard/ansible/password" --with-decryption --query "Parameter.Value" --output text >/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Password parameter verified (SecureString decryption successful)"
    # Show parameter info without revealing the value
    aws ssm get-parameter --name "/Standard/ansible/password" --query "Parameter.{Name:Name,Type:Type,Version:Version}" --output table
else
    echo "❌ Password parameter verification failed"
    echo "Possible issues:"
    echo "  - Parameter doesn't exist"
    echo "  - Missing kms:Decrypt permission"
    echo "  - Missing ssm:GetParameter permission"
fi

echo ""
echo "Testing SSM document parameter resolution syntax:"
echo "For String parameter use: {{ ssm:/Standard/ansible/username }}"
echo "For SecureString parameter use: {{ ssm-secure:/Standard/ansible/password }}"

echo ""
echo "SSM Parameter creation complete!"
echo "You can now run your SSM document again."
