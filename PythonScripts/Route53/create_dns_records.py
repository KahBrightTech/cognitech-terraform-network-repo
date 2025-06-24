# dns_manager.py

import boto3

def create_dns_record(zone_id, record_name, record_type, target_value, ttl=300):
    client = boto3.client('route53')

    if record_type not in ['A', 'CNAME']:
        raise ValueError(f"Unsupported record type: {record_type}. Use 'A' or 'CNAME'.")

    change_batch = {
        'Comment': f'Creating {record_type} record for {record_name}',
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

    response = client.change_resource_record_sets(
        HostedZoneId=zone_id,
        ChangeBatch=change_batch
    )

    return response['ChangeInfo']['Id']
