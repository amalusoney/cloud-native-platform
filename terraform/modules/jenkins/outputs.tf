output "jenkins_instance_id" {
  description = "The EC2 Instance ID of the Jenkins host"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "The permanent Elastic Public IP for Jenkins"
  value       = aws_eip.jenkins_eip.public_ip
}