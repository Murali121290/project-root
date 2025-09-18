provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.project_tag}-vpc"
  }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name = "${var.project_tag}-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_tag}-igw"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_tag}-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group (with restricted SSH access)
resource "aws_security_group" "allow_web" {
  name        = "${var.project_tag}-sg"
  description = "Allow SSH, HTTP, Jenkins, Sonar"
  vpc_id      = aws_vpc.main.id

  # SSH - restricted to your IP (replace with your actual IP)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting to your IP: ["YOUR_IP/32"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Jenkins
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SonarQube
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_tag}-sg"
  }
}

# Jenkins Instance
resource "aws_instance" "jenkins" {
  ami                         = var.aws_ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_web.id]
  associate_public_ip_address = true
  
  tags = {
    Name    = "${var.project_tag}-jenkins"
    Project = var.project_tag
    Role    = "jenkins"
  }
  user_data = file("${path.module}/userdata/jenkins_user_data.sh")
}

# SonarQube Instance
resource "aws_instance" "sonar" {
  ami                         = var.aws_ami
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_web.id]
  associate_public_ip_address = true
  
  tags = {
    Name    = "${var.project_tag}-sonar"
    Project = var.project_tag
    Role    = "sonarqube"
  }
  user_data = file("${path.module}/userdata/sonarqube_user_data.sh")
}

# Minikube Instance (larger instance type)
resource "aws_instance" "minikube" {
  ami                         = var.aws_ami
  instance_type               = "t3.large"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_web.id]
  associate_public_ip_address = true
  
  tags = {
    Name    = "${var.project_tag}-minikube"
    Project = var.project_tag
    Role    = "minikube"
  }
  user_data = file("${path.module}/userdata/minikube_user_data.sh")
}
