# Packaging and Uploading Lambda Function to S3

This guide explains how to compress your Lambda function code and upload it to an S3 bucket for deployment.

## 1. Prepare Your Lambda Function Directory
- Ensure your Lambda function code (e.g., `eks_instance_tagger_lambda.py`) and any dependencies (if needed) are in a single directory.
- If you have dependencies, install them into a subfolder (e.g., `python/`) as described in the Lambda Layers README.


## 2. Compress the Lambda Function

### Windows (PowerShell):

If your function has no external dependencies:

```powershell
Compress-Archive -Path eks_instance_tagger_lambda.py -DestinationPath function.zip
```

If your function has dependencies (e.g., in a `python/` folder):

```powershell
Compress-Archive -Path eks_instance_tagger_lambda.py, python\* -DestinationPath function.zip
```

> Note: The above command will include all files in the `python` folder. Adjust as needed for your structure.

---

### Linux/macOS (bash):

If your function has no external dependencies:

```sh
zip function.zip eks_instance_tagger_lambda.py
```

If your function has dependencies (e.g., in a `python/` folder):

```sh
zip -r function.zip eks_instance_tagger_lambda.py python/
```

- This will create `function.zip` containing your code and dependencies.

## 3. Upload the ZIP to S3

You can use the AWS CLI to upload the ZIP file to your S3 bucket:

```sh
aws s3 cp function.zip s3://<your-bucket-name>/lambda/function.zip
```

- Replace `<your-bucket-name>` with your actual S3 bucket name.
- You can organize your S3 path as needed.

## 4. Deploy the Lambda Function
- In the AWS Lambda console, choose "Upload from S3" and provide the S3 URI (e.g., `s3://<your-bucket-name>/lambda/function.zip`).
- Or, use infrastructure-as-code tools (e.g., Terraform, CloudFormation) to reference the S3 object.

---

**Tip:**
- Always re-zip and re-upload after making changes to your code or dependencies.
- For large dependencies, consider using Lambda Layers (see the layers README).
