#!/bin/bash
set -ex

# Update system
apt-get update -y
apt-get upgrade -y

# Install common dependencies
apt-get install -y \
    docker.io \
    openjdk-11-jdk \
    maven \
    git \
    curl \
    wget

# Add user to docker group
usermod -aG docker ubuntu

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
apt-get update
apt-get install -y jenkins

# Install SonarQube (using Docker)
docker run -d --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:community

# Start Minikube
sudo -u ubuntu minikube start --memory=${minikube_memory} --cpus=${minikube_cpus} --driver=docker

# Enable services to start on boot
systemctl enable jenkins
systemctl start jenkins

# Create a health check script
cat > /usr/local/bin/health-check.sh << 'EOF'
#!/bin/bash
echo "Checking services:"
echo "Jenkins: $(systemctl is-active jenkins)"
echo "Docker: $(systemctl is-active docker)"
echo "SonarQube: $(docker inspect -f '{{.State.Status}}' sonarqube)"
echo "Minikube: $(sudo -u ubuntu minikube status | grep host)"
EOF

chmod +x /usr/local/bin/health-check.sh

echo "All services installed successfully!"
