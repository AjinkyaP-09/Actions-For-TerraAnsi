provider "aws" {
  region = var.aws_region # Uses the AWS region defined in variables.tf
}

#resource "aws_key_pair" "deployer_key" {
#  key_name   = var.key_pair_name
#  public_key = file("${path.module}/ssh-key.pub")
#  tags = {
#    Project = var.project_tag # Apply a project tag for resource organization
#  }
#}

# --- Terraform Remote State Backend Configuration ---
# This block configures Terraform to store its state file in an S3 bucket
# and use a DynamoDB table for state locking.
# This is crucial for CI/CD environments to persist state between runs
# and prevent concurrent modifications.
terraform {
  backend "s3" {
    bucket         = "ajinkya-pame-terraform-state-bucket" # <<< IMPORTANT: Use the actual bucket name you created
    key            = "terraform.tfstate"                    # Path to the state file within the bucket
    region         = "ap-south-1"                            # <<< IMPORTANT: Use the actual region where your S3 bucket is
    dynamodb_table = "actions-for-terraansi"    # <<< IMPORTANT: Use the actual DynamoDB table name you created
    encrypt        = true                                   # Encrypts the state file at rest
  }
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content              = tls_private_key.ssh_key.private_key_pem
  filename             = "${path.module}/id_rsa_deployer.pem"
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "aws_key_pair" "deployer_key" {
  key_name   = var.key_pair_name
  public_key = tls_private_key.ssh_key.public_key_openssh
  tags = {
    Project = var.project_tag
  }
}


# --- Security Group ---
# This resource creates an AWS Security Group to control inbound and outbound traffic for the EC2 instance.
resource "aws_security_group" "docker_sg" {
  name        = "${var.project_tag}-sg" # Name of the security group
  description = "Allow SSH and HTTP traffic to EC2 instance for Docker setup"
  vpc_id      = data.aws_vpc.default.id # Associates with the default VPC

  # Ingress rule: Allow SSH traffic (port 22) from any IP address.
  # WARNING: 0.0.0.0/0 allows access from anywhere on the internet.
  # For production environments, restrict this to known IP ranges.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH from anywhere"
  }

  # Egress rule: Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # -1 indicates all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allows outbound traffic to any IP
    description = "Allow all outbound traffic"
  }

  tags = {
    Name    = "${var.project_tag}-SecurityGroup"
    Project = var.project_tag
  }
}

# --- EC2 Instance ---
# This resource defines the EC2 instance that will be launched.
resource "aws_instance" "docker_instance" {
  ami           = var.ami_id           # AMI ID for the instance, from variables.tf
  instance_type = var.instance_type    # Instance type (e.g., t2.micro), from variables.tf
  key_name      = aws_key_pair.deployer_key.key_name # Associates the created key pair for SSH access
  vpc_security_group_ids = [aws_security_group.docker_sg.id] # Attaches the security group

  # Use a data source to automatically select a default public subnet within the default VPC.
  # This helps ensure the instance is reachable on the internet.
#  subnet_id = data.aws_subnet.default.id

  # user_data script executes commands on the instance when it first launches.
  # It updates package lists and installs Python 3 and pip, which are essential for Ansible.
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y python3 python3-pip -qq # -qq for quiet installation
              EOF

  tags = {
    Name    = "${var.project_tag}-Instance"
    Project = var.project_tag
  }

  # Define explicit dependencies to ensure resources are created in the correct order.
  # The key pair and security group must exist before the instance can be launched.
  depends_on = [
    aws_key_pair.deployer_key,
    aws_security_group.docker_sg
  ]
}

# --- Data Sources (for default VPC and Subnet) ---
# Data source to fetch information about the default VPC in the AWS account.
data "aws_vpc" "default" {
  default = true # Filters for the default VPC
}

# Data source to fetch information about a default subnet within the default VPC.
# This ensures the instance is placed in a public subnet to receive a public IP.
#data "aws_subnet" "default" {
#  vpc_id                  = data.aws_vpc.default.id
#  map_public_ip_on_launch = true                  # Ensures the subnet maps public IPs to new instances
#  availability_zone       = "${var.aws_region}a"  # Selects a subnet in the first AZ of the region for simplicity
#  filter {
#    name   = "default-for-az"
#    values = ["true"] # Filters for the default subnet within that AZ
#  }
#}

# --- Outputs ---
# Define outputs to easily retrieve important information about the created resources.
output "instance_public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.docker_instance.public_ip # Exports the public IP of the EC2 instance
}

output "instance_id" {
  description = "The ID of the EC2 instance."
  value       = aws_instance.docker_instance.id # Exports the ID of the EC2 instance
}

output "private_key_pem" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

