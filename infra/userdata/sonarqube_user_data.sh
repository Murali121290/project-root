#!/bin/bash
set -e
apt-get update -y
apt-get install -y docker.io
systemctl enable --now docker
# Run SonarQube community edition
docker run -d --name sonarqube -p 9000:9000 sonarqube:community
