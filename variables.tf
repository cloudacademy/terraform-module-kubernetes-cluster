variable "control_plane_ami" {
  description = "Control Plane Node AMI"
  type        = string
}

variable "worker_ami" {
  description = "Worker Node AMI"
  type        = string
}

variable "bastion_ami" {
  description = "Bastion Node AMI"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "availability_zone" {
  description = "The Availability Zone for this cluster"
  type        = string
  default     = "us-west-2b"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR Block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidr_block" {
  description = "Private Subnet CIDR Block"
  type        = string
  default     = "10.0.0.0/19"
}

variable "public_subnet_cidr_block" {
  description = "Pubic Subnet CIDR Block"
  type        = string
  default     = "10.0.128.0/20"
}

variable "admin_ingress_location" {
  description = "CIDR block to allow SSH access to the bastion host and HTTPS access to the Kubernetes API from all locations"
  type        = string
  default     = "0.0.0.0/0"
}

variable "control_plane_type" {
  description = "Control Plane Node Instance Type"
  type        = string
  default     = "t3.medium"
}

variable "worker_type" {
  description = "Worker Node Instance Type"
  type        = string
  default     = "t3.medium"
}

variable "bastion_type" {
  description = "Bastion Node Instance Type"
  type        = string
  default     = "t3.micro"
}

variable "disk_size" {
  description = "Size of the root disk for the EC2 instances, in GiB"
  type        = number
  default     = 12 
}

variable "key_pair_name" {
  description = "Key pair name"
  type        = string
}

variable "control_plane_user_data" {
  description = "User data script"
  type        = string
}

variable "worker1_user_data" {
  description = "User data script"
  type        = string
}

variable "worker2_user_data" {
  description = "User data script"
  type        = string
}

variable "bastion_user_data" {
  description = "User data script"
  type        = string
}