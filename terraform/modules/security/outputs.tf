output "jenkins_sg_id" {
  description = "Security Group ID for Jenkins controller"
  value       = aws_security_group.jenkins_sg.id
}