# 1. Dynamic AMI Query: Automatically fetches the latest official Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. IAM Role for Jenkins (Allows Jenkins to interact with AWS services securely)
resource "aws_iam_role" "jenkins_role" {
  name = "${var.project_name}-${var.environment}-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-role"
    Environment = var.environment
  }
}

# Attach AmazonEC2ContainerRegistryPowerUser (Allows Jenkins to push/pull Docker images to ECR)
resource "aws_iam_role_policy_attachment" "jenkins_ecr" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Attach IAM policy to describe EKS clusters
resource "aws_iam_policy" "jenkins_eks_describe" {
  name        = "${var.project_name}-${var.environment}-jenkins-eks-describe"
  description = "Allows Jenkins to describe EKS clusters for deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_eks" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_eks_describe.arn
}

# 3. IAM Instance Profile (Binds the IAM Role to the EC2 instance)
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.project_name}-${var.environment}-jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

# 4. Jenkins EC2 Instance
resource "aws_instance" "jenkins" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name             = var.key_name
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name

  root_block_device {
    volume_size           = 30 # Up to 30 GB is AWS Free Tier eligible
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-controller"
    Environment = var.environment
    Role        = "Jenkins-Controller"
  }
}

# 5. Elastic IP for Jenkins (Gives Jenkins a permanent, static Public IP)
resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-eip"
    Environment = var.environment
  }
}