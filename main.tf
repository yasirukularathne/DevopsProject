terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Ensures compatibility with recent AWS provider versions
    }
  }
  required_version = ">= 1.0.0" # Ensures Terraform version is compatible
}

provider "aws" {
  region = "eu-north-1" # Specify the AWS region
}

# Step 1: Create Security Group in Default VPC
resource "aws_security_group" "devops_sg" {
  name        = "My-security-group"
  description = "Allow SSH, HTTP, HTTPS, and custom ports"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (Not secure for production)
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP access from anywhere
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS access from anywhere
  }
  
  # Fixed port ranges - start port must be less than or equal to end port
  ingress {
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access to ports 5000-5555
  }
  
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access to ports 3000-5173
  }
  
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow access to port 27017 (MongoDB)
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "My-security-group"
  }
}

# Step 2: Create EC2 Instance with Security Group
resource "aws_instance" "free_tier_instance" {
  ami           = "ami-0c1ac8a41498c1a9c" # Ubuntu AMI ID
  instance_type = "t3.micro"              # Free tier eligible instance type
  key_name      = "devops"
  
  # Attach Security Group by ID
  vpc_security_group_ids = [aws_security_group.devops_sg.id]
  
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu  # Allow the 'ubuntu' user to run Docker without sudo
              newgrp docker
              EOF
  
  tags = {
    Name = "FreeTierUbuntuInstance" # Tag for the instance
  }
}

output "instance_id" {
  description = "The ID of the created EC2 instance"
  value       = aws_instance.free_tier_instance.id
}

output "instance_public_ip" {
  description = "The public IP of the created EC2 instance"
  value       = aws_instance.free_tier_instance.public_ip
}
