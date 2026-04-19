#!/bin/bash
set -euo pipefail

REGION=$$(TOKEN=$$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") && curl -s -H "X-aws-ec2-metadata-token: $$TOKEN" http://169.254.169.254/latest/meta-data/placement/region)

echo "Checking for SSM Agent on RHEL 9 (region: $$REGION)..."

if rpm -q amazon-ssm-agent &>/dev/null; then
  echo "SSM Agent is already installed."
  sudo systemctl status amazon-ssm-agent --no-pager
else
  echo "SSM Agent not found. Installing..."
  sudo dnf install -y "https://s3.$${REGION}.amazonaws.com/amazon-ssm-$${REGION}/latest/linux_amd64/amazon-ssm-agent.rpm"
  sudo systemctl enable amazon-ssm-agent
  sudo systemctl start amazon-ssm-agent
  echo "SSM Agent installed and running."
  sudo systemctl status amazon-ssm-agent --no-pager
fi