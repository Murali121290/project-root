#!/bin/bash
set -e
apt-get update -y
apt-get install -y curl docker.io conntrack socat
systemctl enable --now docker

cat >/home/ubuntu/start_minikube.sh <<'EOF'
#!/bin/bash
set -e
# install kubectl
KUBEV="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"
curl -LO https://storage.googleapis.com/kubernetes-release/release/${KUBEV}/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/

# install minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
mv minikube /usr/local/bin/

# start minikube
minikube start --driver=docker --kubernetes-version=stable
EOF

chmod +x /home/ubuntu/start_minikube.sh
chown ubuntu:ubuntu /home/ubuntu/start_minikube.sh
