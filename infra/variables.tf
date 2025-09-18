variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "key_name" {
  description = "SSH key name in AWS"
  default     = "murali26jul2025"   # <-- replace with your actual EC2 key pair name
}

variable "aws_ami" {
  description = "Ubuntu 22.04 AMI id"
  default     = "ami-053b0d53c279acc90"   # <-- change to latest Ubuntu AMI in your region
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "project_tag" {
  description = "Project tag to label AWS resources"
  default     = "jenkins-sonar-minikube-demo"
}
