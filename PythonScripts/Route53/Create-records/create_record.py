# run_dns_action.py

import argparse
from create_dns_records import create_dns_record

DEFAULT_ZONE_ID = 'Z04956893LRVROGR7SL4U'

def main():
    parser = argparse.ArgumentParser(description="Create one or more DNS records in Route 53")
    parser.add_argument('--names', nargs='+', required=True, help='List of DNS record names')
    parser.add_argument('--types', nargs='+', required=True, help='List of DNS record types (A or CNAME)')
    parser.add_argument('--values', nargs='+', required=True, help='List of target values (IP or FQDN)')
    parser.add_argument('--ttl', type=int, default=300, help='TTL (default: 300)')

    args = parser.parse_args()

    if not (len(args.names) == len(args.types) == len(args.values)):
        print("❌ Error: The number of names, types, and values must be equal.")
        return

    for name, rtype, value in zip(args.names, args.types, args.values):
        try:
            change_id = create_dns_record(
                zone_id=DEFAULT_ZONE_ID,
                record_name=name,
                record_type=rtype,
                target_value=value,
                ttl=args.ttl
            )
            print(f"✅ Created: {name} ({rtype}) -> {value}, Change ID: {change_id}")
        except Exception as e:
            print(f"❌ Failed to create {name}: {e}")

if __name__ == '__main__':
    main()
