provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.project_tag}-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.region}a"
  tags = {
    Name = "${var.project_tag}-subnet"
  }
}

resource "aws_security_group" "allow_web" {
  name        = "${var.project_tag}-sg"
  description = "Allow SSH, HTTP, Jenkins, Sonar"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

resource "aws_instance" "jenkins" {
  ami                    = var.aws_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  tags = {
    Name    = "${var.project_tag}-jenkins"
    Project = var.project_tag
    Role    = "jenkins"
  }
  user_data = file("${path.module}/userdata/jenkins_user_data.sh")
}

resource "aws_instance" "sonar" {
  ami                    = var.aws_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  tags = {
    Name    = "${var.project_tag}-sonar"
    Project = var.project_tag
    Role    = "sonarqube"
  }
  user_data = file("${path.module}/userdata/sonarqube_user_data.sh")
}

resource "aws_instance" "minikube" {
  ami                    = var.aws_ami
  instance_type          = "t3.large"
  key_name               = var.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  tags = {
    Name    = "${var.project_tag}-minikube"
    Project = var.project_tag
    Role    = "minikube"
  }
  user_data = file("${path.module}/userdata/minikube_user_data.sh")
}
