# 🌐 DNS Record Manager

A modern, web-based application for bulk creation of DNS records in AWS Route53. This tool provides a user-friendly interface to upload Excel spreadsheets containing DNS record data and create multiple records at once.

## 🚀 Features

- **Beautiful Web Interface**: Modern Streamlit-based UI with real-time progress tracking
- **Bulk DNS Creation**: Upload Excel files with hundreds of DNS records
- **Multiple Record Types**: Support for A, AAAA, CNAME, MX, TXT, SRV, and PTR records
- **Data Validation**: Automatic validation of DNS names, IP addresses, and record formats
- **Progress Tracking**: Real-time progress bars and status updates
- **Result Export**: Download detailed results in CSV format
- **Error Handling**: Clear feedback on validation errors and creation failures
- **Sample Templates**: Download pre-formatted Excel templates

## 📋 Prerequisites

### Software Requirements
- Python 3.8 or higher
- AWS CLI configured (optional but recommended)
- Internet connection

### AWS Requirements
- AWS Account with Route53 access
- AWS credentials configured (one of the following):
  - AWS CLI configured (`aws configure`)
  - AWS credentials file (`~/.aws/credentials`)
  - Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
  - IAM role (for EC2 instances)

### Required AWS Permissions
Your AWS user/role needs the following Route53 permissions:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ChangeResourceRecordSets",
                "route53:GetChange"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🛠️ Installation

### 1. Clone or Download
Download the script files to your local machine.

### 2. Install Dependencies
```powershell
# Navigate to the script directory
cd "path\to\Create-records"

# Install required packages
pip install --user boto3 streamlit pandas openpyxl
```

### 3. Verify Installation
```powershell
python -c "import streamlit; print('Streamlit version:', streamlit.__version__)"
```

## 🏃‍♂️ Quick Start

### Option 1: Short Command (Recommended)
After setting up the PowerShell function (see setup below):
```powershell
dns
```

### Option 2: Using Short Batch File
```powershell
.\dns.bat
```

### Option 3: Using the Full Batch File (Windows)
1. Double-click `run_dns_manager.bat`
2. The application will automatically open in your browser

### Option 4: Manual Start
```powershell
# Navigate to the script directory
cd "path\to\Create-records"

# Run the application
python -m streamlit run create_dns_records.py
```

### Option 5: Using Full Python Path
```powershell
# If streamlit is not in PATH
C:/Python312/python.exe -m streamlit run create_dns_records.py
```

## 🚀 Setting Up Short Commands

### PowerShell Function Setup (One-time)
```powershell
# Create PowerShell profile if it doesn't exist
New-Item -ItemType Directory -Path (Split-Path $PROFILE) -Force
New-Item -ItemType File -Path $PROFILE -Force

# Add DNS function to profile
Add-Content -Path $PROFILE -Value "function dns { Set-Location 'C:\Users\kbrig\Downloads\GitRepos\cognitech-repos\cognitech-terraform-network-repo\PythonScripts\Route53\Create-records'; python -m streamlit run create_dns_records.py }"

# Reload profile
. $PROFILE
```

**Note**: Update the path in the function to match your actual script location.

### Alternative: Current Session Only
```powershell
# For current PowerShell session only
function dns { Set-Location 'path\to\Create-records'; python -m streamlit run create_dns_records.py }
```

The application will start and automatically open in your browser at `http://localhost:8501`

## 📊 Using the Application

### Step 1: Configure AWS
Ensure your AWS credentials are configured. The application will automatically detect your Route53 hosted zones.

### Step 2: Select Hosted Zone
1. In the sidebar, select the hosted zone where you want to create DNS records
2. The dropdown shows zone names and current record counts

### Step 3: Prepare Your Data
1. Click "📋 Download Sample Excel Template" to get a template
2. Fill in your DNS records with the following columns:
   - `name`: DNS record name (e.g., "www.example.com")
   - `type`: Record type (A, CNAME, MX, etc.)
   - `value`: Target value (IP address, hostname, etc.)
   - `ttl`: Time to live in seconds (optional, defaults to 300)

### Step 4: Upload and Create
1. Upload your Excel file using the file uploader
2. Review the validated data preview
3. Click "🚀 Create DNS Records" to process all records
4. Monitor the real-time progress
5. Download the results CSV for your records

## 📝 Excel File Format

### Required Columns
| Column | Description | Example | Required |
|--------|-------------|---------|----------|
| `name` | DNS record name | www.example.com | ✅ |
| `type` | Record type | A, CNAME, MX | ✅ |
| `value` | Target value | 192.168.1.1 | ✅ |
| `ttl` | Time to live | 300 | ❌ (defaults to 300) |

### Sample Excel Data
```
name                | type  | value           | ttl
www.example.com     | A     | 192.168.1.1    | 300
api.example.com     | CNAME | www.example.com | 300
mail.example.com    | A     | 192.168.1.2    | 600
example.com         | MX    | 10 mail.example.com | 300
```

## 🔧 Adding More Hosted Zones

The application automatically discovers all hosted zones in your AWS account. To add more zones:

### Method 1: AWS Console
1. Go to [AWS Route53 Console](https://console.aws.amazon.com/route53/)
2. Click "Hosted zones" → "Create hosted zone"
3. Enter your domain name
4. Choose "Public hosted zone" or "Private hosted zone"
5. Click "Create hosted zone"
6. Refresh the DNS Manager application

### Method 2: AWS CLI
```bash
# Create a public hosted zone
aws route53 create-hosted-zone \
    --name "yourdomain.com" \
    --caller-reference "$(date +%Y%m%d%H%M%S)"

# Create a private hosted zone for VPC
aws route53 create-hosted-zone \
    --name "internal.company.com" \
    --caller-reference "$(date +%Y%m%d%H%M%S)" \
    --vpc VPCRegion=us-east-1,VPCId=vpc-12345678
```

### Method 3: Terraform
```hcl
resource "aws_route53_zone" "example" {
  name = "example.com"
  
  tags = {
    Environment = "production"
  }
}
```

## 📋 Supported DNS Record Types

| Type | Description | Example Value |
|------|-------------|---------------|
| **A** | IPv4 address | 192.168.1.1 |
| **AAAA** | IPv6 address | 2001:db8::1 |
| **CNAME** | Canonical name | www.example.com |
| **MX** | Mail exchange | 10 mail.example.com |
| **TXT** | Text record | "v=spf1 include:_spf.google.com ~all" |
| **SRV** | Service record | 10 5 443 target.example.com |
| **PTR** | Pointer record | example.com |

## 🚨 Troubleshooting

### Common Issues

#### 1. "No module named streamlit"
**Solution:**
```powershell
pip install --user streamlit
# Or use full path
C:/Python312/python.exe -m pip install --user streamlit
```

#### 2. "No hosted zones found"
**Possible causes:**
- AWS credentials not configured
- No permissions to access Route53
- No hosted zones in your account

**Solution:**
```powershell
# Check AWS credentials
aws sts get-caller-identity

# List hosted zones
aws route53 list-hosted-zones
```

#### 3. Permission Errors
**Solution:**
- Ensure your AWS user has Route53 permissions
- Use `--user` flag when installing Python packages
- Run as administrator if needed

#### 4. "streamlit: command not found"
**Solution:**
```powershell
# Add to PATH or use full path
C:/Python312/python.exe -m streamlit run create_dns_records.py
```

## 🔒 Security Best Practices

### AWS Credentials
- Use IAM roles when possible (for EC2/Lambda)
- Never commit credentials to version control
- Use least-privilege principle for permissions
- Rotate access keys regularly

### Application Security
- Run on trusted networks only
- Use HTTPS in production environments
- Validate all input data
- Monitor DNS changes and access logs

## 📊 Performance Tips

### Large Datasets
- Process records in batches of 100-500
- Use appropriate TTL values (300-3600 seconds)
- Monitor AWS API rate limits
- Consider using Route53 batch operations for very large datasets

## 📞 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review AWS Route53 documentation
3. Check Streamlit documentation for UI issues

## 🔗 Useful Links

- [AWS Route53 Documentation](https://docs.aws.amazon.com/route53/)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [Boto3 Route53 Reference](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/route53.html)

---

## 📋 Quick Reference

### File Structure
```
Create-records/
├── create_dns_records.py    # Main application
├── requirements.txt         # Python dependencies
├── run_dns_manager.bat     # Full batch file
├── dns.bat                 # Short batch file
├── README.md               # This file
└── sample_template.xlsx    # Downloaded from app
```

### Key Commands
```powershell
# Short commands (after setup)
dns                          # PowerShell function
.\dns.bat                   # Short batch file

# Install dependencies
pip install --user -r requirements.txt

# Manual run
python -m streamlit run create_dns_records.py

# Setup PowerShell function
Add-Content -Path $PROFILE -Value "function dns { Set-Location 'path\to\Create-records'; python -m streamlit run create_dns_records.py }"

# Check AWS credentials
aws sts get-caller-identity

# List hosted zones
aws route53 list-hosted-zones
```

---

## 📜 Legacy Script Usage (create_record.py)

For the original command-line script:

```sh
python create_record.py --name test.kahbrigthllc.com test2.kahbrigthllc.com --type A CNAME --value 192.0.2.1 target.example.com
```
- `--zone-id`: The Route53 hosted zone ID
- `--name`: The DNS record name
- `--type`: The DNS record type (e.g., A, CNAME)
- `--value`: The DNS record value (e.g., IP address)

**Happy DNS Management! 🎉**
