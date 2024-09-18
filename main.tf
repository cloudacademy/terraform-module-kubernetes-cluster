resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = false
}

resource "aws_s3_bucket" "k8s_logs" {
  bucket        = "k8slogs-${random_string.suffix.result}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "main_public_access_block" {
  bucket = aws_s3_bucket.k8s_logs.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "main_ownership_controls" {
  bucket = aws_s3_bucket.k8s_logs.id
  rule {
    object_ownership = "ObjectWriter"
  }
  depends_on = [aws_s3_bucket_public_access_block.main_public_access_block]
}

resource "aws_ebs_volume" "persistent_volume" {
  size              = 1
  encrypted         = true
  availability_zone = var.availability_zone
  type              = "gp2"

  tags = {
    Name = "PV"
    Type = "PV"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true
    tags = {
    KubernetesCluster = "calabs",
    "kubernetes.io/cluster/calabs" = "owned"
  }
}

resource "aws_vpc_dhcp_options" "dhcp_options" {
  domain_name         = "${var.region}.compute.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "vpc_dhcp_options_association" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.dhcp_options.id
}

resource "aws_internet_gateway" "internet_gateway" {
  tags = {
    Network = "Public"
  }
}

resource "aws_internet_gateway_attachment" "vpc_gateway_attachment" {
  vpc_id             = aws_vpc.vpc.id
  internet_gateway_id = aws_internet_gateway.internet_gateway.id
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_cidr_block
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name                   = "Private subnet"
    Network                = "Private"
    KubernetesCluster      = "calabs"
    "kubernetes.io/cluster/calabs" = "owned"
  }
}

resource "aws_route_table" "private_subnet_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "Private Subnets"
    Network = "Private"
  }
}

resource "aws_route" "private_subnet_route" {
  route_table_id         = aws_route_table.private_subnet_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

resource "aws_route_table_association" "private_subnet_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_subnet_route_table.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr_block
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name                   = "Public subnet"
    Network                = "Public"
    KubernetesCluster      = "calabs"
    "kubernetes.io/cluster/calabs" = "owned"
    "kubernetes.io/role/elb"       = "1"
  }
}

resource "aws_route_table" "public_subnet_route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name    = "Public Subnets"
    Network = "Public"
  }
}

resource "aws_route" "public_subnet_route" {
  route_table_id         = aws_route_table.public_subnet_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id

  depends_on = [aws_internet_gateway_attachment.vpc_gateway_attachment]
}

resource "aws_route_table_association" "public_subnet_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_subnet_route_table.id
}

resource "aws_security_group" "cluster_security_group" {
  name        = "k8s-cluster-security-group"
  description = "Enable SSH access via port 22"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ingress_location]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.admin_ingress_location]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.admin_ingress_location]
  }

  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = [var.admin_ingress_location]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.admin_ingress_location]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.admin_ingress_location]
  }

  tags = {
    Name                   = "k8s-cluster-security-group"
    KubernetesCluster      = "calabs"
    "kubernetes.io/cluster/calabs" = "owned"
  }
}

resource "aws_security_group" "bastion_security_group" {
  name        = "k8s-bastion-security-group"
  description = "Enable limited bastion access"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ingress_location]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.admin_ingress_location]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.admin_ingress_location]
  }

  ingress {
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    cidr_blocks = [var.admin_ingress_location]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.admin_ingress_location]
  }

  tags = {
    Name = "k8s-bastion-security-group"
  }
}

resource "aws_iam_role" "control_plane_role" {
  name = "control_plane_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "ControlPlanePolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ec2:*",
            "elasticloadbalancing:*",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:BatchGetImage",
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:UpdateAutoScalingGroup",
            "ec2messages:*",
            "ssmmessages:CreateControlChannel",
            "ssm:ListAssociations",
            "ssm:ListInstanceAssociations",
            "ssmmessages:CreateControlChannel",
            "ssm:UpdateInstanceInformation",
            "s3:Get*",
            "s3:List*",
            "s3:Put*"
          ]
          Resource = "*"
        },
        {
          Effect = "Deny"
          Action = [
            "ec2:RunInstances"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "control_plane_instance_profile" {
  name = "control_plane_instance_profile"
  role = aws_iam_role.control_plane_role.name
}

resource "aws_network_interface" "control_plane_ni" {
  description = "ControlPlane Network Interface"
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.0.100"]

  security_groups = [aws_security_group.cluster_security_group.id]

  tags = {
    Name = "k8s-control-plane"
  }
}

resource "aws_instance" "control_plane" {
  ami                         = var.control_plane_ami
  instance_type               = var.control_plane_type
  iam_instance_profile        = aws_iam_instance_profile.control_plane_instance_profile.name
  key_name                    = var.key_pair_name
  user_data                   = base64encode(var.control_plane_user_data)

  credit_specification {
    cpu_credits = "standard"
  }

  network_interface {
    network_interface_id = aws_network_interface.control_plane_ni.id
    device_index         = 0
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 12
    delete_on_termination = true
    encrypted = false
  }

  tags = {
    Name                   = "k8s-control-plane"
    KubernetesCluster      = "calabs"
    "kubernetes.io/cluster/calabs" = "owned"
  }
}

resource "aws_iam_role" "worker_role" {
  name = "worker_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "WorkerPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ec2:AttachVolume",
            "ec2:CreateVolume",
            "ec2:CreateSnapshot",
            "ec2:CreateTags",
            "ec2:DeleteSnapshot",
            "ec2:DeleteTags",
            "ec2:DeleteVolume",
            "ec2:DetachVolume",
            "ec2:ModifyVolume",
            "ec2:Describe*",
            "ec2:Get*",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:BatchGetImage",
            "ec2messages:*",
            "ssmmessages:CreateControlChannel",
            "ssm:ListAssociations",
            "ssm:ListInstanceAssociations",
            "ssmmessages:CreateControlChannel",
            "ssm:UpdateInstanceInformation"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "worker_instance_profile" {
  name = "worker_instance_profile"
  role = aws_iam_role.worker_role.name
}

resource "aws_network_interface" "worker1_ni" {
  description = "Worker 1 Network Interface"
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.0.10"]

  security_groups = [aws_security_group.cluster_security_group.id]

  tags = {
    Name = "k8s-worker1"
  }
}

resource "aws_instance" "worker1" {
  ami                         = var.worker_ami
  instance_type               = var.worker_type
  iam_instance_profile        = aws_iam_instance_profile.worker_instance_profile.name
  key_name                    = var.key_pair_name
  user_data                   = base64encode(var.worker1_user_data)

  credit_specification {
    cpu_credits = "standard"
  }

  network_interface {
    network_interface_id = aws_network_interface.worker1_ni.id
    device_index         = 0
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    volume_size = 12
    delete_on_termination = true
    encrypted = false
  }

  tags = {
    Name                   = "k8s-worker1"
    KubernetesCluster      = "calabs"
    "kubernetes.io/cluster/calabs" = "owned"
  }
}

resource "aws_network_interface" "worker2_ni" {
  description = "Worker 2 Network Interface"
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.0.11"]

  security_groups = [aws_security_group.cluster_security_group.id]

  tags = {
    Name = "k8s-worker2"
  }
}

resource "aws_instance" "worker2" {
  ami                         = var.worker_ami
  instance_type               = var.worker_type
  iam_instance_profile        = aws_iam_instance_profile.worker_instance_profile.name
  key_name                    = var.key_pair_name
  user_data                   = base64encode(var.worker2_user_data)

  credit_specification {
    cpu_credits = "standard"
  }

  network_interface {
    network_interface_id = aws_network_interface.worker2_ni.id
    device_index         = 0
  }

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_type           = "gp2"
    volume_size           = 12
    delete_on_termination = true
    encrypted             = false
  }

  tags = {
    Name                   = "k8s-worker2"
    KubernetesCluster      = "calabs"
    "kubernetes.io/cluster/calabs" = "owned"
  }
}

resource "aws_iam_role" "bastion_role" {
  name = "BastionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "BastionPolicy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ec2:Describe*",
            "ec2:Get*",
            "s3:Get*",
            "s3:List*",
            "ec2messages:*",
            "ssmmessages:CreateControlChannel",
            "ssm:ListAssociations",
            "ssm:ListInstanceAssociations",
            "ssmmessages:CreateControlChannel",
            "ssm:UpdateInstanceInformation"
          ]
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_iam_instance_profile" "bastion_instance_profile" {
  name = "BastionInstanceProfile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_network_interface" "bastion_ni" {
  description = "Bastion Network Interface"
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["10.0.128.5"]

  security_groups = [aws_security_group.cluster_security_group.id]

  tags = {
    Name = "k8s-bastion"
  }
}

resource "aws_instance" "bastion" {
  ami                         = var.bastion_ami
  instance_type               = var.bastion_type
  iam_instance_profile        = aws_iam_instance_profile.bastion_instance_profile.name
  key_name                    = var.key_pair_name
  user_data                   = base64encode(var.bastion_user_data)

  credit_specification {
    cpu_credits = "standard"
  }

  network_interface {
    network_interface_id = aws_network_interface.bastion_ni.id
    device_index         = 0
  }

  tags = {
    Name                   = "k8s-bastion"
    KubernetesCluster      = "calabs"
  }
}