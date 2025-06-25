# Route53 DNS Script Usage

## How to run the scripts

1. Open a terminal and navigate to the `Route53` folder.
2. Run the following command, replacing the arguments as needed:

   ```sh
   python run_dns_actions.py --zone-id Z0334718LG87PKPVYABM --name test.kahbrigthllc.com --type A --value 192.0.2.1
   ```

   - `--zone-id`: The Route53 hosted zone ID
   - `--name`: The DNS record name
   - `--type`: The DNS record type (e.g., A, CNAME)
   - `--value`: The DNS record value (e.g., IP address)