#!/bin/bash
set -euo pipefail

echo "Checking for SSM Agent on RHEL 9..."

if rpm -q amazon-ssm-agent &>/dev/null; then
  echo "SSM Agent is already installed."
  sudo systemctl status amazon-ssm-agent --no-pager
else
  echo "SSM Agent not found. Installing..."
  sudo dnf install -y https://s3.amazonaws.com/ec2-downloads-ssm/latest/linux_amd64/amazon-ssm-agent.rpm
  sudo systemctl enable amazon-ssm-agent
  sudo systemctl start amazon-ssm-agent
  echo "SSM Agent installed and running."
  sudo systemctl status amazon-ssm-agent --no-pager
fi