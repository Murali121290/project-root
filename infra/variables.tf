variable "region" { default = "us-east-1" }
variable "key_name" { description = "SSH key name in AWS" }
variable "aws_ami" { description = "Ubuntu AMI id" }
variable "instance_type" { default = "t3.medium" }
variable "project_tag" { default = "jenkins-sonar-minikube-demo" }
