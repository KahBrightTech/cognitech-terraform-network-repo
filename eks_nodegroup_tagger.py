import boto3
import logging
import json
import time
import sys

logger = logging.getLogger()
logger.setLevel(logging.INFO)
logging.basicConfig(format='%(asctime)s %(levelname)s %(message)s')

# Number of times to retry checking for EKS tags (tags may not be
# propagated yet when the instance first enters "running")
MAX_RETRIES = 5
RETRY_DELAY_SECONDS = 10

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Get the instance ID from the EventBridge EC2 state-change event
        instance_id = event.get('detail', {}).get('instance-id')

        if not instance_id:
            raise ValueError("Missing 'instance-id' in event detail")

        ec2_client = boto3.client('ec2')
        ec2_resource = boto3.resource('ec2')

        instance = ec2_resource.Instance(instance_id)
        state = instance.state['Name']
        logger.info(f"Instance {instance_id} is currently {state}")

        if state != 'running':
            logger.info(f"Instance {instance_id} is not running, skipping")
            return {
                'statusCode': 200,
                'body': json.dumps({'Message': f'Instance {instance_id} is {state}, skipping'})
            }

        # Retry loop — EKS/ASG tags may take a moment to propagate
        cluster_name = None
        tags = {}

        for attempt in range(1, MAX_RETRIES + 1):
            # Reload instance to get fresh tags
            instance.reload()
            tags = {t['Key']: t['Value'] for t in instance.tags or []}

            # Check if already tagged by this Lambda
            if tags.get('ManagedBy') == 'eks-instance-tagger-lambda':
                logger.info(f"Instance {instance_id} already tagged by us, skipping")
                return {
                    'statusCode': 200,
                    'body': json.dumps({'Message': f'Instance {instance_id} already tagged, skipping'})
                }

            # Check for EKS ownership via eks:cluster-name tag
            cluster_name = tags.get('eks:cluster-name')

            # Fallback: check for kubernetes.io/cluster/<name> tag
            if not cluster_name:
                for key in tags:
                    if key.startswith('kubernetes.io/cluster/'):
                        cluster_name = key.split('/')[-1]
                        break

            if cluster_name:
                logger.info(f"Found EKS cluster tag on attempt {attempt}: {cluster_name}")
                break

            logger.info(f"Attempt {attempt}/{MAX_RETRIES}: No EKS tags yet on {instance_id}, "
                        f"retrying in {RETRY_DELAY_SECONDS}s...")
            time.sleep(RETRY_DELAY_SECONDS)

        if not cluster_name:
            logger.info(f"Instance {instance_id} is not owned by EKS after {MAX_RETRIES} attempts, skipping")
            return {
                'statusCode': 200,
                'body': json.dumps({'Message': f'Instance {instance_id} is not EKS-managed, skipping'})
            }

        # Find the next available node number for this cluster
        node_number = _get_next_node_number(ec2_client, cluster_name)

        # Build the Name tag: cluster-name-node-1, cluster-name-node-2, etc.
        name_tag = f"{cluster_name}-node-{node_number}"

        # Apply tags
        ec2_client.create_tags(
            Resources=[instance_id],
            Tags=[
                {'Key': 'Name', 'Value': name_tag},
                {'Key': 'ManagedBy', 'Value': 'eks-instance-tagger-lambda'},
            ]
        )
        logger.info(f"Tagged {instance_id} -> {name_tag}")

        return {
            'statusCode': 200,
            'body': json.dumps({
                'InstanceId': instance_id,
                'Name': name_tag,
                'ClusterName': cluster_name,
            })
        }

    except Exception as e:
        logger.error(f"Error occurred: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'Message': str(e)})
        }


def _get_next_node_number(ec2_client, cluster_name):
    """
    Find all existing instances for this cluster that were already tagged
    by us, extract their node numbers, and return the next available number.
    """
    paginator = ec2_client.get_paginator('describe_instances')
    filters = [
        {'Name': 'instance-state-name', 'Values': ['running']},
        {'Name': 'tag:eks:cluster-name', 'Values': [cluster_name]},
        {'Name': 'tag:ManagedBy', 'Values': ['eks-instance-tagger-lambda']},
    ]

    existing_numbers = []
    for page in paginator.paginate(Filters=filters):
        for reservation in page['Reservations']:
            for instance in reservation['Instances']:
                tags = {t['Key']: t['Value'] for t in instance.get('Tags', [])}
                name = tags.get('Name', '')
                # Parse the node number from "cluster-name-node-N"
                prefix = f"{cluster_name}-node-"
                if name.startswith(prefix):
                    try:
                        num = int(name[len(prefix):])
                        existing_numbers.append(num)
                    except ValueError:
                        pass

    if not existing_numbers:
        return 1

    # Return the next number after the highest existing one
    return max(existing_numbers) + 1


# ---------------------------------------------------------------------------
# Local execution — tag all running EKS instances in the account
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    ec2_client = boto3.client('ec2')

    # Find all running instances that have an eks:cluster-name tag
    paginator = ec2_client.get_paginator('describe_instances')
    filters = [
        {'Name': 'instance-state-name', 'Values': ['running']},
        {'Name': 'tag-key', 'Values': ['eks:cluster-name']},
    ]

    instance_ids = []
    for page in paginator.paginate(Filters=filters):
        for reservation in page['Reservations']:
            for instance in reservation['Instances']:
                instance_ids.append(instance['InstanceId'])

    if not instance_ids:
        print("No running EKS instances found in this account/region.")
        sys.exit(0)

    print(f"Found {len(instance_ids)} running EKS instance(s): {instance_ids}")

    for instance_id in instance_ids:
        print(f"\nProcessing {instance_id}...")
        event = {"detail": {"instance-id": instance_id}}
        result = lambda_handler(event, None)
        print(json.dumps(json.loads(result['body']), indent=2))
