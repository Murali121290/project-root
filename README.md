# Jenkins + SonarQube + Minikube Demo

## Overview
This repo demonstrates a CI/CD pipeline with Jenkins, SonarQube, Docker/ECR and Minikube. Requirements:
- Terraform-managed AWS infra (no console EC2 creation)
- Jenkins pipeline that fails Quality Gate first (vulnerable code), then passes after fixes
- Clean shutdown of EC2 to minimize cost

## Architecture
Mermaid diagram:

```mermaid
flowchart LR
  GH[GitHub repo] --> Jenkins[Jenkins]
  Jenkins --> Sonar[SonarQube]
  Jenkins --> Docker[ECR Registry]
  Docker --> Minikube[Minikube (K8s)]
  Sonar --> Jenkins
