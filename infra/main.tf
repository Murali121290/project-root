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

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_tag}-igw"
  }
}

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

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
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
    from_port   = 80
    to_port     = 80
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

  # Add port for Minikube services if needed
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort range for Minikube"
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

# Single instance that runs all three services
resource "aws_instance" "ci_cd_server" {
  ami                         = var.aws_ami
  instance_type               = "t3.large"  # Sufficient for all three services
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.allow_web.id]
  associate_public_ip_address = true
  
  # Increase storage size for all services
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "${var.project_tag}-root-volume"
    }
  }

  tags = {
    Name        = "${var.project_tag}-ci-cd-server"
    Project     = var.project_tag
    Role        = "ci-cd-server"
    Components  = "jenkins,sonarqube,minikube"
  }

  # Use a combined user data script
  user_data = templatefile("${path.module}/userdata/combined_user_data.sh", {
    minikube_memory = "4g"
    minikube_cpus   = 2
  })
}
