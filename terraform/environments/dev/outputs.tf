output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "jenkins_public_ip" {
  description = "The static Elastic IP of the Jenkins server"
  value       = module.jenkins.jenkins_public_ip
}

output "ssh_command" {
  description = "Command to SSH into Jenkins"
  value       = "ssh -i C:\\Users\\amalu\\Downloads\\devops-key.pem ubuntu@${module.jenkins.jenkins_public_ip}"
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "configure_kubectl_command" {
  description = "Command to connect your local kubectl to the EKS cluster"
  value       = "aws eks update-kubeconfig --region us-east-1 --name ${module.eks.cluster_name}"
}

output "ecr_repository_url" {
  description = "The URL of the Amazon ECR repository"
  value       = module.ecr.repository_url
}

