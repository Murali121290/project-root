#!/bin/bash
set -ex

# Update system
apt-get update -y
apt-get upgrade -y

# Install Java
apt-get install -y openjdk-17-jdk

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update -y
apt-get install -y jenkins

# Start Jenkins
systemctl start jenkins
systemctl enable jenkins

# Install Docker
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add Jenkins to Docker group
usermod -aG docker jenkins

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
apt-get update && apt-get install -y terraform

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Create setup scripts directory
mkdir -p /opt/scripts

# Create SonarQube setup script
cat > /opt/scripts/sonarqube-setup.sh << 'EOF'
#!/bin/bash
set -ex

# Install Docker Compose
apt-get install -y docker-compose-plugin

# Create SonarQube directory
mkdir -p /opt/sonarqube
cd /opt/sonarqube

# Create docker-compose.yml
cat > docker-compose.yml << 'EOL'
version: "3.8"
services:
  sonarqube:
    image: sonarqube:community
    depends_on:
      - db
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    ports:
      - "9000:9000"
  db:
    image: postgres:13
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonar
    volumes:
      - postgresql_data:/var/lib/postgresql/data
      - postgresql_data_db:/var/lib/postgresql

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql_data:
  postgresql_data_db:
EOL

# Start SonarQube
docker compose up -d

# Wait for SonarQube to start
sleep 60

# Get initial admin password
echo "SonarQube initial admin password:"
docker compose logs sonarqube | grep "Generated admin password" | tail -1
EOF

chmod +x /opt/scripts/sonarqube-setup.sh

# Create Minikube setup script
cat > /opt/scripts/minikube-setup.sh << 'EOF'
#!/bin/bash
set -ex

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --driver=docker --force

# Enable ingress
minikube addons enable ingress

# Verify installation
kubectl get nodes
EOF

chmod +x /opt/scripts/minikube-setup.sh

# Create Jenkins initial setup script
cat > /opt/scripts/jenkins-initial-setup.sh << 'EOF'
#!/bin/bash
set -ex

# Wait for Jenkins to start
sleep 30

# Get initial admin password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "Jenkins initial admin password: $JENKINS_PASSWORD"

# Install suggested plugins (non-interactive)
wget -O /tmp/jenkins-cli.jar http://localhost:8080/jenkins/jnlpJars/jenkins-cli.jar
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins/ -auth admin:$JENKINS_PASSWORD install-plugin workflow-aggregator git github docker-workflow -deploy
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080/jenkins/ -auth admin:$JENKINS_PASSWORD safe-restart
EOF

chmod +x /opt/scripts/jenkins-initial-setup.sh

# Run initial setup in background
nohup /opt/scripts/jenkins-initial-setup.sh > /tmp/jenkins-setup.log 2>&1 &
