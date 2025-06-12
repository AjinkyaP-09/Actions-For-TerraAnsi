# variables.tf

# Defines the AWS region where resources will be provisioned.
variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1" # Default to N. Virginia. Change this if your desired region is different.
}

# Defines the EC2 instance type.
variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro" # t2.micro is eligible for AWS Free Tier.
}

# Defines the Amazon Machine Image (AMI) ID to use for the EC2 instance.
variable "ami_id" {
  description = "The ID of the Amazon Machine Image (AMI) to use."
  type        = string
  # IMPORTANT: Find a suitable Ubuntu 22.04 LTS AMI for your chosen AWS region.
  # You can find AMI IDs in the EC2 console under "AMIs" or using AWS CLI/Terraform data sources.
  # Example for us-east-1 (Ubuntu Server 22.04 LTS, HVM, EBS General Purpose (SSD) Volume Type):
  default     = "ami-02521d90e7410d9f0"
}

# Defines the name for the AWS EC2 Key Pair.
variable "key_pair_name" {
  description = "The name for the AWS EC2 Key Pair."
  type        = string
  default     = "terraform-ansible-docker-key" # This name will appear in your AWS EC2 console.
}

# Defines a project tag to apply to all created AWS resources for organization.
variable "project_tag" {
  description = "A tag to apply to all resources."
  type        = string
  default     = "TerraAnsiDocker" # Useful for identifying resources created by this setup.
}
# --- Variables for Terraform Remote Backend (S3) ---
variable "s3_backend_bucket_name" {
  description = "Name of the S3 bucket to store Terraform state."
  type        = string
  # IMPORTANT: Replace with a unique bucket name you've created in S3.
  default     = "actions-for-terraansi" 
}

variable "dynamodb_lock_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking."
  type        = string
  # IMPORTANT: Replace with the DynamoDB table name you've created.
  default     = "Actions-For-TerraAnsi" 
}
