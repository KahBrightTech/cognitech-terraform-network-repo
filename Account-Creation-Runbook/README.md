### New Account Creation Steps
- This runbook is designed to guide you through the process of creating a new account in our system. Please follow the steps outlined below to ensure a smooth and successful account creation. 
#### Step 1: Run the CFN Template
- Use the provided CloudFormation (CFN) templates located at Account-Creation-Runbook\01-CFN-Prereqs to created the necessary prerequisites for account creation. 
##### Oder of CFN Template Execution:
- First update all the parameters located at ssm-parameter.yaml file with the correct values for the new account and then run the template with the below cli command: 
```bash
   aws cloudformation create-stack \
     --stack-name account-parameters \
     --template-body file://Cloudformation/Initializing-account-for-terraform/primary-region-cfn-stacks/ssm-parameter.yaml `
     --region us-east-1
```
Using powershell
```
   aws cloudformation create-stack `
     --stack-name account-parameters `
     --template-body file://Cloudformation/Initializing-account-for-terraform/primary-region-cfn-stacks/ssm-parameter.yaml `
     --region us-east-1
```
- Once complete run the main template with the below cli command: 
```bash
   aws cloudformation create-stack \
     --stack-name account-creation-prereqs \
     --template-body file://Cloudformation/Initializing-account-for-terraform/primary-region-cfn-stacks/account-creation-prereqs.yaml `
     --region us-east-1
```
using powershell
```
   aws cloudformation create-stack `
     --stack-name account-creation-prereqs `
     --template-body file://Cloudformation/Initializing-account-for-terraform/primary-region-cfn-stacks/account-creation-prereqs.yaml `
     --region us-east-1
```
- Ensure that the stacks located at C:\Users\Owner\Downloads\GitRepos\cognitech-repos\cognitech-terraform-network-repo\Account-Creation-Runbook\01-CFN-Prereqs\primary-region-cfn-stacks are ran first before proceeding to the next folder. 

#### Step 2: Create the Account