#!/bin/bash

set -e

echo "==== Updating system ===="
sudo dnf update -y

echo "==== Installing dependencies ===="
sudo dnf install -y curl wget tar unzip conntrack bash-completion git

echo "==== Installing Docker CE ===="
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user

echo "==== Applying docker group immediately ===="
newgrp docker <<EONG

echo "==== Installing Minikube ===="
curl -LO https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

echo "==== Starting Minikube ===="
minikube start --driver=docker

echo "==== Configuring kubectl alias ===="
alias kubectl="minikube kubectl --"
echo 'alias kubectl="minikube kubectl --"' >> ~/.bashrc

echo "==== Installing Helm ===="
curl -O https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz
tar -zxvf helm-v3.18.3-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm-v3.18.3-linux-amd64.tar.gz linux-amd64

echo "==== Adding Helm repo ===="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "==== Installing Prometheus Stack ===="
helm install prometheus prometheus-community/kube-prometheus-stack

echo "==== Waiting for Prometheus stack to be ready ===="
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=grafana --timeout=300s || echo "Grafana pod may not be ready yet."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=prometheus --timeout=300s || echo "Prometheus pod may not be ready yet."

echo "==== Patching Grafana service to NodePort ===="
kubectl patch svc prometheus-grafana -p '{"spec": {"type": "NodePort"}}'

echo "==== Downloading MongoDB deployment YAML ===="
curl -L -o mongodb.yaml https://raw.githubusercontent.com/of1r/k8s-monitoring/main/mongodb.yaml

echo "==== Deploying MongoDB ===="
kubectl apply -f mongodb.yaml

echo "==== Downloading values.yaml for MongoDB Exporter ===="
curl -L -o values.yaml https://raw.githubusercontent.com/of1r/k8s-monitoring/main/values.yaml

echo "==== Installing MongoDB Exporter ===="
helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f values.yaml

echo "==== Waiting for MongoDB Exporter pod to be ready ===="
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=prometheus-mongodb-exporter --timeout=180s || echo "MongoDB Exporter pod may not be ready yet."

echo "==== Setup complete! ===="
echo ""
echo "➡️  To access services via SSH tunnel, run this from your local machine:"
echo "ssh -i <your-key>.pem -L 3000:localhost:3000 -L 9090:localhost:9090 -L 9216:localhost:9216 -N ec2-user@<ec2-public-ip>"
echo ""
echo "📊 Grafana:     http://localhost:3000"
echo "📈 Prometheus:  http://localhost:9090"
echo "📦 MongoDB Exp: http://localhost:9216"

EONG
