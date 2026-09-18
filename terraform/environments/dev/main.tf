# Automatically fetches the IAM identity running Terraform
data "aws_caller_identity" "current" {}
# 1. Networking Module (Custom VPC & Subnets)
module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.20.0/24"]
  availability_zones   = ["us-east-1a", "us-east-1b"]
  cluster_name         = "cloud-native-eks"
}

# 2. Security Module (Security Groups)
module "security" {
  source = "../../modules/security"
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
}
# 3. Jenkins Compute Module
module "jenkins" {
  source = "../../modules/jenkins"
  project_name      = var.project_name
  environment       = var.environment
  subnet_id         = module.networking.public_subnet_ids[0] # Placed in Public Subnet 1
  security_group_id = module.security.jenkins_sg_id
  key_name          = "devops-key"
  instance_type     = "t3.micro" # Free-tier testing (can resize to t3.medium later)
}

# 4. EKS Kubernetes Cluster Module
module "eks" {
  source = "../../modules/eks"

  project_name        = var.project_name
  environment         = var.environment
  cluster_name        = "cloud-native-eks"
  cluster_version     = "1.31"
  vpc_id              = module.networking.vpc_id
  subnet_ids          = concat(module.networking.public_subnet_ids, module.networking.private_subnet_ids)
  private_subnet_ids  = module.networking.private_subnet_ids
  node_instance_types = ["t3.micro"]
}

# 5. Amazon ECR Module (Container Registry)
module "ecr" {
  source          = "../../modules/ecr"
  repository_name = "cloud-native-app"
  environment     = var.environment
}

