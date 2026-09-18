# Security Group for Jenkins Controller
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-${var.environment}-jenkins-sg"
  description = "Security group for Jenkins controller host"
  vpc_id      = var.vpc_id

  # Inbound SSH (Port 22)
  ingress {
    description = "Allow SSH from administrator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Inbound Jenkins Web Interface (Port 8080)
  ingress {
    description = "Allow Jenkins Web UI traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Outbound rule: Allow all outbound traffic to internet
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-jenkins-sg"
    Environment = var.environment
  }
}