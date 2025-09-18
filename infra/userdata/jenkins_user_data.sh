#!/bin/bash
set -e
apt-get update -y
apt-get install -y docker.io git openjdk-11-jdk unzip
systemctl enable --now docker
# give jenkins directory persistent storage
mkdir -p /var/jenkins_home
chown 1000:1000 /var/jenkins_home || true

# run Jenkins LTS container
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v /var/jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
