# 1. Tell Terraform to build in AWS
provider "aws" {
  region = "us-east-1"
}

# 2. Upload the Public SSH Key we just copied
resource "aws_key_pair" "app_key" {
  key_name   = "jenkins-tf-key"
  public_key = file("jenkins-tf-key.pub")
}

# 3. Create a Firewall (Security Group)
resource "aws_security_group" "app_sg" {
  name        = "java-app-security-group"
  description = "Allow SSH and HTTP traffic"

  # Allow SSH from anywhere (so Jenkins can log in)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Web Traffic to the Java App (Port 8080)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow the server to download updates from the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Build the actual EC2 Server
resource "aws_instance" "app_server" {
  ami           = "ami-0c7217cdde317cfec" # Standard Ubuntu 22.04 in us-east-1
  instance_type = "t2.micro"              # Free tier!
  key_name      = aws_key_pair.app_key.key_name
  
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  # 5. The Magic Step: Run this bash script the moment the server boots up!
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io docker-compose
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "Jenkins-Provisioned-App-Server"
  }
}

# 6. Output the Public IP address so Jenkins knows where to deploy!
output "server_public_ip" {
  value = aws_instance.app_server.public_ip
}