# 🚀 Terraform & Ansible Docker Deployment with GitHub Actions

This repository provides a robust CI/CD pipeline that provisions an AWS EC2 instance, installs Docker on it using Ansible, and manages the entire lifecycle (creation and destruction) through GitHub Actions.

---

## 📘 Project Overview

This project automates infrastructure provisioning and configuration using:

- **Terraform**: Define and provision AWS EC2 infrastructure.
- **Ansible**: Configure EC2 instance and install Docker.
- **GitHub Actions**: Automate the entire CI/CD pipeline.
- **Docker**: Target application environment.
  
With a simple Git push or manual trigger, you get a fully Docker-ready EC2 instance on AWS.

---

## ✨ Features

- **Automated EC2 Provisioning**: Launch an Ubuntu EC2 instance in the default VPC.
- **Dynamic Security Group**: Allow SSH access (port 22) automatically.
- **SSH Key Management**: Terraform manages key pairs; Ansible uses private key via GitHub Secrets.
- **Docker Installation**: Ansible installs Docker Engine, CLI, Containerd, and Compose.
- **Full Lifecycle Automation**: Create and destroy infrastructure via GitHub Actions.
- **Secure Credentials**: AWS credentials and SSH private keys handled via GitHub Secrets.
- **Remote State Management**: Terraform state is stored securely in an AWS S3 bucket with state locking via DynamoDB, crucial for CI/CD and team collaboration.
---

## 🛠️ Technologies Used

- **Infrastructure as Code**: HashiCorp Terraform
- **Configuration Management**: Ansible
- **Cloud Provider**: Amazon Web Services (AWS)
- **CI/CD**: GitHub Actions
- **Containerization**: Docker

---

## 🔐 Prerequisites

Before you begin, ensure the following:

- ✅ An **active AWS account** with programmatic access (Access key ID + Secret).
- ✅ A **GitHub repository** where the workflows will run.
- ✅ A **public/private SSH key pair** for SSH access.

---

## ⚙️ Setup Instructions

### 1. Generate SSH Key Pair

```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/github-actions-aws-key
 ```


This will create two files: `~/.ssh/github-actions-aws-key` (private key) and `~/.ssh/github-actions-aws-key.pub` (public key).

### 2. Configure GitHub Secrets

In your GitHub repository, go to **Settings > Secrets and variables > Actions** and add the following repository secrets:

- **AWS_ACCESS_KEY_ID**: Your AWS access key ID.
- **AWS_SECRET_ACCESS_KEY**: Your AWS secret access key.
- **SSH_PRIVATE_KEY**: The entire content of your generated private SSH key (`~/.ssh/github-actions-aws-key`). Make sure to copy the content including the `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` lines.

### 3. Create AWS S3 Backend and DynamoDB Table
Terraform requires a remote backend to store its state for CI/CD workflows. You need to manually create an S3 bucket and a DynamoDB table in your AWS account before running the workflows.

- **S3 Bucket for Terraform State:**

  - Go to the AWS S3 console and create a new bucket (e.g., your-github-repo-name-terraform-state).

  - Enable Bucket Versioning on this bucket. This is crucial for state recovery.

  - Keep public access blocked (default and recommended for security).

- **DynamoDB Table for State Locking:**

  - Go to the AWS DynamoDB console and create a new table (e.g., your-github-repo-name-terraform-locks).

 - Set the Primary key to LockID (String type). Use default settings for other options.

> Important: Ensure the bucket name and DynamoDB table name you choose here exactly match the names specified in the backend "s3" block within your main.tf and the variables in variables.tf.

### 4. Place Public SSH Key in Repository

Create a file named `ssh-key.pub` in the root of your repository (the same directory as `main.tf`). Paste the entire content of your public SSH key (`~/.ssh/github-actions-aws-key.pub`) into this file. This file must be committed to your repository.

### 5. Review AMI ID and Region

Open `variables.tf` and verify that the `ami_id` is a valid Ubuntu 22.04 LTS AMI for your chosen `aws_region`.  
The default `aws_region` is `ap-south-1`. If you change it, ensure you update the `TF_VAR_aws_region` environment variable in both `workflow.yml` and `destroy-workflow.yml`.

### 6. Commit and Push

Commit all the project files (including `.github/workflows/workflow.yml`, `.github/workflows/destroy-workflow.yml`, `main.tf`, `variables.tf`, `ansi.yml`, and `ssh-key.pub`) to your `main` branch.

---

## 🚀 Usage

This repository includes two GitHub Actions workflows:

### 1. Provision and Configure Infrastructure

- **Workflow File**: `.github/workflows/workflow.yml`
- **Purpose**: Launches an EC2 instance and installs Docker using Ansible.
- **Triggers**:
  - On every push to the `main` branch.
  - Manually via the "Actions" tab in your GitHub repository (look for "Terraform & Ansible Docker Install").

### 2. Destroy Infrastructure

- **Workflow File**: `.github/workflows/destroy-workflow.yml`
- **Purpose**: Tears down all AWS resources provisioned by Terraform.
- **Triggers**:
  - Manually only via the "Actions" tab in your GitHub repository (look for "Terraform Destroy Infrastructure").

> ⚠️ **WARNING**: This operation is permanent and will delete all associated resources. Use with caution!

---

## 📄 Project Structure
```
.
├── .github/
│   └── workflows/
│       ├── destroy-workflow.yml    # GitHub Actions workflow to destroy infrastructure
│       └── workflow.yml            # GitHub Actions workflow to provision and configure
├── ansi.yml                        # Ansible playbook for Docker installation
├── hosts.ini                       # Ansible inventory (dynamically generated by workflow)
├── main.tf                         # Terraform configuration for AWS infrastructure
├── variables.tf                    # Terraform variables
└── ssh-key.pub                     # Public SSH key used by Terraform (MUST be committed)
```

## Working
1. Create a S3 bucket with unique name and use that in main.tf. Add AWS credentials. ![Screenshot 2025-06-12 161720](https://github.com/user-attachments/assets/63bf8ee5-47e8-42ef-90b5-00d3baa02962) ![Screenshot 2025-06-12 154637](https://github.com/user-attachments/assets/63df9285-c1ad-406e-878a-cb0be3040d2b)

2. Create a DynamoDB table and mention its name in main.tf. ![Screenshot 2025-06-12 162047](https://github.com/user-attachments/assets/4e5fa36b-3e87-400c-85bc-60565a84f824)
3. Push the code to repository and wait for ```Terraform & Ansible Docker Install``` workflow to start.
4. It will create a key pair. ![Screenshot 2025-06-12 154530](https://github.com/user-attachments/assets/21de7e3b-425b-4c1a-8644-4c78e15963f1)
5. A security group. 
![Screenshot 2025-06-12 154511](https://github.com/user-attachments/assets/2177c695-2c46-41e1-adb0-c719d56c7ce2)
6. Desired instance with docker installed and hello-world container execution will be ready.
![Screenshot 2025-06-12 154441](https://github.com/user-attachments/assets/fd0e74df-0c27-430b-91cd-f1fdccc0ebfc)
7. Check that using SSH Connect.
8. The ```Terraform & Ansible Docker Install``` workflow ends here.

![Screenshot 2025-06-12 154555](https://github.com/user-attachments/assets/c86f7710-183d-40f3-bcff-91319bd9b781)
9. It will write ```.tfstate``` file in S3 bucket.![Screenshot 2025-06-12 161731](https://github.com/user-attachments/assets/a9505418-44ae-4a90-82e6-ca29178d3c11)
10. Also entry of LockID in DynamoDB.![Screenshot 2025-06-12 162032](https://github.com/user-attachments/assets/5fc0580a-ba41-46aa-97d7-57395f644dc6)
11. Manually run ```Terraform Destroy Infrastructure``` workflow to destroy resources using ```.tfstate``` file in S3 bucket.
![Screenshot 2025-06-12 154850](https://github.com/user-attachments/assets/94bbe9ec-05f1-42b2-bfc1-f5d865d705c6) ![image](https://github.com/user-attachments/assets/2b181947-5ded-4d21-889b-770678fa866e)

12. Resource Cleanup is done properly.

