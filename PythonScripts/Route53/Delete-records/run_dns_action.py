# delete_dns_record.py

import argparse
from delete_dns_record import delete_dns_record

# Hardcoded zone ID
DEFAULT_ZONE_ID = 'Z0334718LG87PKPVYABM'

def main():
    parser = argparse.ArgumentParser(description="Delete DNS record (A or CNAME) from Route 53")
    # --zone-id is hardcoded
    parser.add_argument('--name', required=True, help='DNS record name (e.g. test.example.com.)')
    parser.add_argument('--type', required=True, choices=['A', 'CNAME'], help='DNS record type')
    parser.add_argument('--value', required=True, help='Target value (IP for A, FQDN for CNAME)')
    parser.add_argument('--ttl', type=int, default=300, help='Time-to-live (must match existing record)')

    args = parser.parse_args()

    try:
        change_id = delete_dns_record(
            zone_id=DEFAULT_ZONE_ID,
            record_name=args.name,
            record_type=args.type,
            target_value=args.value,
            ttl=args.ttl
        )
        print(f"✅ Record deletion requested. Change ID: {change_id}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == '__main__':
    main()
