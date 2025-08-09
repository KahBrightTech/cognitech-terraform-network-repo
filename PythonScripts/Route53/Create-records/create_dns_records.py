# Enhanced DNS Manager with Fancy UI
# Bulk DNS Record Creation from Excel Spreadsheet

import boto3
import streamlit as st
import pandas as pd
import time
from typing import List, Dict, Tuple
import re
from datetime import datetime
import io

class DNSRecordManager:
    def __init__(self):
        self.client = boto3.client('route53')
        self.supported_types = ['A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV', 'PTR']
    
    def validate_record_name(self, name: str) -> bool:
        """Validate DNS record name format"""
        pattern = r'^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.?$'
        return bool(re.match(pattern, name))
    
    def validate_ip_address(self, ip: str) -> bool:
        """Validate IP address format"""
        ipv4_pattern = r'^(\d{1,3}\.){3}\d{1,3}$'
        ipv6_pattern = r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$'
        return bool(re.match(ipv4_pattern, ip)) or bool(re.match(ipv6_pattern, ip))
    
    def get_hosted_zones(self) -> List[Dict]:
        """Retrieve all hosted zones"""
        try:
            response = self.client.list_hosted_zones()
            zones = []
            for zone in response['HostedZones']:
                zones.append({
                    'id': zone['Id'].replace('/hostedzone/', ''),
                    'name': zone['Name'],
                    'record_count': zone['ResourceRecordSetCount']
                })
            return zones
        except Exception as e:
            st.error(f"Error retrieving hosted zones: {str(e)}")
            return []
    
    def create_dns_record(self, zone_id: str, record_name: str, record_type: str, 
                         target_value: str, ttl: int = 300) -> Tuple[bool, str]:
        """Create a single DNS record"""
        try:
            if record_type not in self.supported_types:
                return False, f"Unsupported record type: {record_type}"
            
            change_batch = {
                'Comment': f'Creating {record_type} record for {record_name} via Bulk Upload',
                'Changes': [
                    {
                        'Action': 'UPSERT',
                        'ResourceRecordSet': {
                            'Name': record_name,
                            'Type': record_type,
                            'TTL': ttl,
                            'ResourceRecords': [{'Value': target_value}]
                        }
                    }
                ]
            }

            response = self.client.change_resource_record_sets(
                HostedZoneId=zone_id,
                ChangeBatch=change_batch
            )
            
            return True, response['ChangeInfo']['Id']
            
        except Exception as e:
            return False, str(e)
    
    def create_bulk_dns_records(self, zone_id: str, records: List[Dict]) -> List[Dict]:
        """Create multiple DNS records with progress tracking"""
        results = []
        progress_bar = st.progress(0)
        status_text = st.empty()
        
        for i, record in enumerate(records):
            status_text.text(f"Processing record {i+1} of {len(records)}: {record['name']}")
            
            success, result = self.create_dns_record(
                zone_id=zone_id,
                record_name=record['name'],
                record_type=record['type'],
                target_value=record['value'],
                ttl=record.get('ttl', 300)
            )
            
            results.append({
                'name': record['name'],
                'type': record['type'],
                'value': record['value'],
                'ttl': record.get('ttl', 300),
                'success': success,
                'result': result,
                'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            })
            
            # Update progress
            progress_bar.progress((i + 1) / len(records))
            time.sleep(0.1)  # Small delay to show progress
        
        status_text.text("✅ All records processed!")
        return results

def validate_excel_data(df: pd.DataFrame, zone_name: str = None) -> Tuple[bool, List[str], pd.DataFrame]:
    """Validate uploaded Excel data"""
    errors = []
    manager = DNSRecordManager()
    
    # Check required columns
    required_columns = ['name', 'type', 'value']
    missing_columns = [col for col in required_columns if col not in df.columns]
    
    if missing_columns:
        errors.append(f"Missing required columns: {', '.join(missing_columns)}")
        return False, errors, df
    
    # Add TTL column if missing and ensure it's integer
    if 'ttl' not in df.columns:
        df['ttl'] = 300
    else:
        # Convert TTL column to integer to avoid float issues
        df['ttl'] = df['ttl'].fillna(300).astype(int)
    
    # Clean zone name for comparison
    clean_zone = zone_name.rstrip('.') if zone_name else None
    
    # Clean and validate data
    cleaned_df = df.copy()
    
    for index, row in df.iterrows():
        # Clean data first
        record_name = str(row['name']).strip() if pd.notna(row['name']) else ''
        record_type = str(row['type']).upper().strip() if pd.notna(row['type']) else ''
        record_value = str(row['value']).strip() if pd.notna(row['value']) else ''
        
        # Check for empty values
        if not record_name:
            errors.append(f"Row {index + 1}: Record name cannot be empty")
            continue
            
        if not record_type:
            errors.append(f"Row {index + 1}: Record type cannot be empty")
            continue
            
        if not record_value:
            errors.append(f"Row {index + 1}: Record value cannot be empty")
            continue
        
        # Validate record name format
        if not manager.validate_record_name(record_name):
            errors.append(f"Row {index + 1}: Invalid DNS record name format '{record_name}'. Use valid domain names like 'www.example.com'")
        
        # Validate zone match
        if clean_zone and not (record_name == clean_zone or record_name.endswith(f'.{clean_zone}')):
            errors.append(f"Row {index + 1}: Record '{record_name}' does not belong to zone '{clean_zone}'. Use '{clean_zone}' or subdomains like 'www.{clean_zone}'")
        
        # Validate record type
        if record_type not in manager.supported_types:
            errors.append(f"Row {index + 1}: Unsupported record type '{record_type}'. Supported types: {', '.join(manager.supported_types)}")
        
        # Validate IP for A records
        if record_type == 'A' and not manager.validate_ip_address(record_value):
            errors.append(f"Row {index + 1}: Invalid IP address '{record_value}' for A record")
        
        # Store cleaned data
        cleaned_df.at[index, 'name'] = record_name
        cleaned_df.at[index, 'type'] = record_type
        cleaned_df.at[index, 'value'] = record_value
        cleaned_df.at[index, 'ttl'] = int(row['ttl']) if pd.notna(row['ttl']) else 300
    
    return len(errors) == 0, errors, cleaned_df

def create_sample_excel(zone_name=None):
    """Create a sample Excel file for download"""
    # Use the selected zone or default to example.com
    domain = zone_name.rstrip('.') if zone_name else 'example.com'
    
    sample_data = {
        'name': [f'www.{domain}', f'api.{domain}', f'mail.{domain}'],
        'type': ['A', 'CNAME', 'A'],
        'value': ['192.168.1.1', f'www.{domain}', '192.168.1.2'],
        'ttl': [300, 300, 600]
    }
    
    df = pd.DataFrame(sample_data)
    output = io.BytesIO()
    with pd.ExcelWriter(output, engine='openpyxl') as writer:
        df.to_excel(writer, index=False, sheet_name='DNS_Records')
    
    return output.getvalue()

def main():
    st.set_page_config(
        page_title="🌐 DNS Record Manager",
        page_icon="🌐",
        layout="wide",
        initial_sidebar_state="expanded"
    )
    
    # Custom CSS for styling
    st.markdown("""
    <style>
    .main-header {
        background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 1rem;
        border-radius: 10px;
        text-align: center;
        margin-bottom: 2rem;
    }
    .success-box {
        background-color: #d4edda;
        border: 1px solid #c3e6cb;
        color: #155724;
        padding: 1rem;
        border-radius: 5px;
        margin: 1rem 0;
    }
    .error-box {
        background-color: #f8d7da;
        border: 1px solid #f5c6cb;
        color: #721c24;
        padding: 1rem;
        border-radius: 5px;
        margin: 1rem 0;
    }
    </style>
    """, unsafe_allow_html=True)
    
    # Header
    st.markdown("""
    <div class="main-header">
        <h1>🌐 Advanced DNS Record Manager</h1>
        <p>Bulk create DNS records from Excel spreadsheets with ease!</p>
    </div>
    """, unsafe_allow_html=True)
    
    # Initialize DNS manager
    dns_manager = DNSRecordManager()
    
    # Sidebar configuration
    st.sidebar.header("⚙️ Configuration")
    
    # Get hosted zones
    with st.sidebar:
        st.subheader("📍 Select Hosted Zone")
        zones = dns_manager.get_hosted_zones()
        
        if not zones:
            st.error("No hosted zones found or unable to connect to AWS Route53")
            st.stop()
        
        zone_options = {f"{zone['name']} ({zone['record_count']} records)": zone['id'] 
                       for zone in zones}
        
        selected_zone_name = st.selectbox(
            "Choose a hosted zone:",
            options=list(zone_options.keys())
        )
        
        selected_zone_id = zone_options[selected_zone_name]
        
        st.success(f"✅ Zone ID: `{selected_zone_id}`")
    
    # Main content area
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.header("📊 Upload DNS Records")
        
        # Download sample template
        st.subheader("📥 Download Sample Template")
        
        # Get the selected zone name for the template
        selected_zone_info = next((zone for zone in zones if zone['id'] == selected_zone_id), None)
        zone_name = selected_zone_info['name'] if selected_zone_info else 'example.com'
        
        sample_excel = create_sample_excel(zone_name)
        
        st.download_button(
            label="📋 Download Sample Excel Template",
            data=sample_excel,
            file_name="dns_records_template.xlsx",
            mime="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        )
        
        st.info("💡 **Template columns:** `name`, `type`, `value`, `ttl` (optional)")
        
        # File upload
        uploaded_file = st.file_uploader(
            "Choose an Excel file",
            type=['xlsx', 'xls'],
            help="Upload an Excel file with DNS record data"
        )
        
        if uploaded_file is not None:
            try:
                # Read the Excel file
                df = pd.read_excel(uploaded_file)
                
                st.success(f"✅ File uploaded successfully! Found {len(df)} records.")
                
                # Display raw data
                with st.expander("👀 View Raw Data"):
                    st.dataframe(df, use_container_width=True)
                
                # Validate data
                is_valid, errors, cleaned_df = validate_excel_data(df, zone_name)
                
                if not is_valid:
                    st.error("❌ Validation Errors:")
                    for error in errors:
                        st.error(f"• {error}")
                else:
                    st.success("✅ All records validated successfully!")
                    
                    # Display cleaned data
                    st.subheader("📋 Validated Records")
                    st.dataframe(cleaned_df, use_container_width=True)
                    
                    # Process records button
                    if st.button("🚀 Create DNS Records", type="primary", use_container_width=True):
                        st.subheader("⏳ Processing Records...")
                        
                        records_to_create = cleaned_df.to_dict('records')
                        results = dns_manager.create_bulk_dns_records(selected_zone_id, records_to_create)
                        
                        # Display results
                        st.subheader("📊 Results Summary")
                        
                        successful = [r for r in results if r['success']]
                        failed = [r for r in results if not r['success']]
                        
                        col_success, col_failed = st.columns(2)
                        
                        with col_success:
                            st.metric("✅ Successful", len(successful))
                        
                        with col_failed:
                            st.metric("❌ Failed", len(failed))
                        
                        # Detailed results
                        if successful:
                            st.success("✅ Successfully Created Records:")
                            success_df = pd.DataFrame(successful)
                            st.dataframe(success_df[['name', 'type', 'value', 'timestamp']], 
                                       use_container_width=True)
                        
                        if failed:
                            st.error("❌ Failed Records:")
                            failed_df = pd.DataFrame(failed)
                            st.dataframe(failed_df[['name', 'type', 'value', 'result']], 
                                       use_container_width=True)
                        
                        # Download results
                        results_df = pd.DataFrame(results)
                        csv = results_df.to_csv(index=False)
                        
                        st.download_button(
                            label="📥 Download Results CSV",
                            data=csv,
                            file_name=f"dns_creation_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                            mime="text/csv"
                        )
                        
            except Exception as e:
                st.error(f"❌ Error reading Excel file: {str(e)}")
    
    with col2:
        st.header("📚 Instructions")
        
        st.markdown("""
        ### 🚀 How to Use:
        
        1. **📥 Download** the sample template
        2. **✏️ Fill in** your DNS records:
           - `name`: DNS record name
           - `type`: Record type (A, CNAME, etc.)
           - `value`: Target value/IP
           - `ttl`: Time to live (optional)
        3. **📤 Upload** your Excel file
        4. **✅ Review** validated data
        5. **🚀 Click** "Create DNS Records"
        
        ### 📋 Supported Record Types:
        - **A**: IPv4 address
        - **AAAA**: IPv6 address  
        - **CNAME**: Canonical name
        - **MX**: Mail exchange
        - **TXT**: Text record
        - **SRV**: Service record
        - **PTR**: Pointer record
        
        ### 💡 Tips:
        - Use FQDN (fully qualified domain names)
        - Ensure IP addresses are valid
        - TTL defaults to 300 seconds
        - Records are created with UPSERT action
        """)
        
        # AWS Configuration Status
        st.subheader("🔧 AWS Configuration")
        try:
            # Test AWS connection
            zones = dns_manager.get_hosted_zones()
            if zones:
                st.success("✅ AWS Route53 Connected")
                st.info(f"📍 Found {len(zones)} hosted zones")
            else:
                st.warning("⚠️ No hosted zones found")
        except Exception as e:
            st.error(f"❌ AWS Connection Error: {str(e)}")

if __name__ == "__main__":
    main()
