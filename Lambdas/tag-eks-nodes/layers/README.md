# Creating and Zipping Lambda Layers for tag-eks-nodes

This guide explains how to create and package Lambda layers for the `tag-eks-nodes` function.

## Prerequisites
- Python 3.x installed
- pip installed
- Access to a terminal or command prompt

## Steps

### 1. Prepare the Directory Structure

Navigate to the `layers` directory:

```
cd C:/Users/Owner/Downloads/GitRepos/cognitech-repos/cognitech-terraform-network-repo/Lambdas/tag-eks-nodes/layers
```

Create a folder for your Python dependencies (e.g., `python`):

```
mkdir -p python
```

### 2. Install Python Dependencies

Install the required packages listed in `requirements.txt` into the `python` directory:

```
pip install -r requirements.txt -t python
```

### 3. Zip the Layer

From inside the `layers` directory, run:

**On Windows:**
```
powershell Compress-Archive -Path python\* -DestinationPath layer.zip
```

**On Linux/macOS:**
```
zip -r layer.zip python
```

This creates a `layer.zip` file containing your dependencies in the correct structure for AWS Lambda.

### 4. Upload the Layer to AWS Lambda

- Go to the AWS Lambda console.
- Choose "Layers" > "Create layer".
- Upload the `layer.zip` file.
- Specify compatible runtimes (e.g., Python 3.8, 3.9, etc.).
- Add the layer to your Lambda function.

---

**Note:**
- Ensure the `python` directory is at the root of the zip file (not nested inside another folder).
- You can update the layer by repeating these steps and uploading a new zip.
