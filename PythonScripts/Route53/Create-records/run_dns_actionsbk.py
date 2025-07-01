# run_dns_action.py

import argparse
from create_dns_records import create_dns_record

def main():
    parser = argparse.ArgumentParser(description="Create DNS record (A or CNAME) in Route 53")
    parser.add_argument('--zone-id', required=True, help='Route 53 Hosted Zone ID')
    parser.add_argument('--name', required=True, help='DNS record name (e.g. test.example.com.)')
    parser.add_argument('--type', required=True, choices=['A', 'CNAME'], help='DNS record type')
    parser.add_argument('--value', required=True, help='Target value (IP for A, FQDN for CNAME)')
    parser.add_argument('--ttl', type=int, default=300, help='Time-to-live (default: 300)')

    args = parser.parse_args()

    try:
        change_id = create_dns_record(
            zone_id=args.zone_id,
            record_name=args.name,
            record_type=args.type,
            target_value=args.value,
            ttl=args.ttl
        )
        print(f"✅ Success: Change ID = {change_id}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == '__main__':
    main()
