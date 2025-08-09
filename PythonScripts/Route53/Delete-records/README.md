# 🗑️ DNS Record Deleter - Advanced Bulk Delete Tool

A sophisticated web-based tool for safely deleting DNS records in bulk from AWS Route53 using Excel spreadsheets.

## ⚠️ IMPORTANT WARNING

**This tool PERMANENTLY DELETES DNS records. Always backup your data and verify records before deletion!**

## 🚀 Features

- **🌐 Web-based UI**: Clean, intuitive Streamlit interface
- **📊 Bulk Operations**: Delete multiple DNS records from Excel files
- **✅ Data Validation**: Comprehensive validation with detailed error messages
- **🔍 Safety Checks**: Exact matching and zone validation
- **📋 Record Preview**: View existing records and export functionality
- **📈 Progress Tracking**: Real-time deletion progress with results
- **📥 Results Export**: Download deletion results as CSV
- **🎯 Multi-type Support**: A, AAAA, CNAME, MX, TXT, SRV, PTR records

## 📋 Prerequisites

- **Python 3.7+** installed on your system
- **AWS CLI configured** with appropriate permissions
- **AWS Route53 access** (list and delete DNS records)

### Required AWS Permissions

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:ListHostedZones",
                "route53:ListResourceRecordSets",
                "route53:ChangeResourceRecordSets"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🛠️ Installation

### Method 1: Automatic Installation
Simply run the batch file - it will handle dependency installation:
```cmd
run_dns_deleter.bat
```

### Method 2: Manual Installation
```bash
# Install required packages
pip install streamlit boto3 pandas openpyxl

# Run the application
streamlit run delete_dns_record.py --server.port 8502
```

## 🚀 Quick Start

### Option 1: Full Launcher (Recommended for first-time users)
```cmd
.\run_dns_deleter.bat
```

### Option 2: Quick Launch
```cmd
.\delete.bat
```

### Option 3: PowerShell Function (After adding to profile)
```powershell
delete-dns
```

## 📖 How to Use

### Step 1: Download Template
1. Open the DNS Record Deleter web interface
2. Select your hosted zone
3. Click "📋 Download Sample Excel Template"
4. This creates a template with your zone's domain name

### Step 2: Prepare Your Data
Fill in the Excel template with records to delete:

| Column | Required | Description | Example |
|--------|----------|-------------|---------|
| `name` | Yes | DNS record name | `old.example.com` |
| `type` | Yes | Record type | `A`, `CNAME`, `MX` |
| `value` | Yes | Current record value | `192.168.1.100` |
| `ttl` | No | Time to live (defaults to 300) | `300` |

#### Example Data:
```
name                type    value               ttl
old.example.com     A       192.168.1.100      300
temp.example.com    CNAME   old.example.com     300
test.example.com    A       192.168.1.101      600
```

### Step 3: Upload and Validate
1. Upload your Excel file using the file uploader
2. Review the validation results
3. Check the "Records to Delete" preview
4. Verify all data is correct

### Step 4: Delete Records
1. ✅ Check the confirmation box: "I understand that this will permanently delete the DNS records above"
2. Click "🗑️ DELETE DNS RECORDS"
3. Monitor the progress bar
4. Review the results summary

### Step 5: Download Results
After deletion, download the CSV results file containing:
- Success/failure status for each record
- Error messages for failed deletions
- Timestamps for all operations

## 🎯 Supported Record Types

| Type | Description | Example Value |
|------|-------------|---------------|
| **A** | IPv4 address | `192.168.1.1` |
| **AAAA** | IPv6 address | `2001:db8::1` |
| **CNAME** | Canonical name | `example.com` |
| **MX** | Mail exchange | `10 mail.example.com` |
| **TXT** | Text record | `"v=spf1 include:_spf.google.com ~all"` |
| **SRV** | Service record | `10 5 443 target.example.com` |
| **PTR** | Pointer record | `example.com` |

## ⚙️ Configuration

### AWS Credentials
Ensure AWS credentials are configured using one of these methods:

1. **AWS CLI** (Recommended):
   ```bash
   aws configure
   ```

2. **Environment Variables**:
   ```cmd
   set AWS_ACCESS_KEY_ID=your_access_key
   set AWS_SECRET_ACCESS_KEY=your_secret_key
   set AWS_DEFAULT_REGION=us-east-1
   ```

3. **IAM Roles** (for EC2 instances)

### Adding PowerShell Function

Add this function to your PowerShell profile for quick access:

```powershell
function delete-dns {
    Set-Location "c:\Users\kbrig\Downloads\GitRepos\cognitech-repos\cognitech-terraform-network-repo\PythonScripts\Route53\Delete-records"
    & streamlit run delete_dns_record.py --server.port 8502 --server.headless false
}
```

To find your PowerShell profile location:
```powershell
$PROFILE
```

## 🛡️ Safety Features

### Data Validation
- **Exact Matching**: Record name, type, and value must match exactly
- **Zone Verification**: Records must belong to the selected hosted zone
- **Format Validation**: DNS names and IP addresses are validated
- **Empty Value Checks**: Prevents deletion with missing data

### Safety Checks
- **Double Confirmation**: Checkbox confirmation required
- **Visual Warnings**: Clear warning messages about permanent deletion
- **Record Preview**: Shows exactly what will be deleted
- **Existing Records View**: Compare against current DNS records

### Error Handling
- **Graceful Failures**: Individual record failures don't stop the process
- **Detailed Errors**: Specific error messages for troubleshooting
- **Transaction Safety**: Each record is deleted individually
- **Result Tracking**: Complete audit trail of all operations

## 🔧 Troubleshooting

### Common Issues

#### 1. "No hosted zones found"
**Cause**: AWS credentials not configured or insufficient permissions
**Solution**: 
- Run `aws configure` to set up credentials
- Verify Route53 permissions in IAM

#### 2. "Record not found" errors
**Cause**: Record doesn't exist or values don't match exactly
**Solution**:
- Use "Show Existing Records" to verify current values
- Ensure exact match of name, type, and value
- Check for trailing spaces or case differences

#### 3. "Invalid DNS record name format"
**Cause**: Malformed DNS names in Excel data
**Solution**:
- Use proper domain format: `subdomain.domain.com`
- Remove special characters except dots and hyphens
- Ensure no leading/trailing spaces

#### 4. "Permission denied" errors
**Cause**: Insufficient AWS permissions
**Solution**:
- Add Route53 permissions to your IAM user/role
- Verify you have `ChangeResourceRecordSets` permission

#### 5. Application won't start
**Cause**: Missing dependencies or Python issues
**Solution**:
```cmd
# Reinstall dependencies
pip install --user --upgrade streamlit boto3 pandas openpyxl

# Check Python version (requires 3.7+)
python --version
```

### Advanced Troubleshooting

#### Debug Mode
Run with verbose output:
```cmd
streamlit run delete_dns_record.py --server.port 8502 --logger.level debug
```

#### Network Issues
If the browser doesn't open automatically:
1. Look for the URL in the terminal output (usually `http://localhost:8502`)
2. Open it manually in your browser
3. Check if port 8502 is available

#### AWS Profile Selection
To use a specific AWS profile:
```cmd
set AWS_PROFILE=your-profile-name
streamlit run delete_dns_record.py
```

## 📁 File Structure

```
Delete-records/
├── delete_dns_record.py          # Main Streamlit application
├── run_dns_deleter.bat           # Full launcher with dependency check
├── delete.bat                    # Quick launcher
├── README.md                     # This documentation
├── __pycache__/                  # Python cache (auto-generated)
└── dns_records_to_delete_template.xlsx  # Sample template (downloaded)
```

## 🔄 Comparison with Create-records

| Feature | Create Tool | Delete Tool |
|---------|-------------|-------------|
| **Purpose** | Add new DNS records | Remove existing records |
| **Port** | 8501 | 8502 |
| **Validation** | Create/update validation | Exact match validation |
| **Safety** | Duplicate checking | Double confirmation |
| **Batch File** | `dns.bat` | `delete.bat` |
| **PowerShell** | `dns` | `delete-dns` |

## 🔗 Related Tools

- **Create-records**: For adding new DNS records (`../Create-records/`)
- **AWS Route53 Console**: Web-based AWS management
- **AWS CLI**: Command-line Route53 management

## 📞 Support

### Getting Help
1. Check this README for common solutions
2. Review error messages in the web interface
3. Check AWS CloudTrail logs for API issues
4. Verify AWS permissions and credentials

### Best Practices
- **Always backup** DNS records before bulk deletion
- **Test with a few records** before large operations
- **Use existing records view** to verify current state
- **Keep audit logs** of deletion results
- **Double-check zone selection** before deletion

## 🔒 Security Considerations

- **Credentials**: Keep AWS credentials secure and rotate regularly
- **Permissions**: Use least-privilege IAM policies
- **Audit**: Monitor Route53 API calls via CloudTrail
- **Backup**: Export DNS records before major changes
- **Access**: Restrict tool access to authorized personnel only

---

## 📚 Additional Resources

- [AWS Route53 Documentation](https://docs.aws.amazon.com/route53/)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [AWS CLI Configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [Python boto3 Route53 Guide](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/route53.html)

---

**⚠️ Remember: DNS record deletion is permanent. Always verify your data and keep backups!**
