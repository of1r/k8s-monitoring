#!/bin/bash

set -e

echo "Updating packages and installing Docker..."
sudo apt-get update -y
sudo apt-get install -y docker.io

echo "Enabling and starting Docker..."
sudo usermod -aG docker $USER
newgrp docker <<EONG

echo "Docker group updated."

echo "Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo "Installing kubectl..."
sudo apt-get install -y kubectl

echo "Starting Minikube..."
minikube start --driver=docker

echo "Aliasing kubectl to Minikube's version..."
alias kubectl="minikube kubectl --"

echo "Installing Helm..."
curl -sSL https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64 helm.tar.gz

echo "Adding Prometheus Helm repo and updating..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "Installing Prometheus stack..."
helm install prometheus prometheus-community/kube-prometheus-stack

echo "Waiting for Grafana deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-grafana

echo "Downloading MongoDB manifest and values.yaml..."
curl -LO https://raw.githubusercontent.com/of1r/k8s-monitoring/main/mongodb.yaml
curl -LO https://raw.githubusercontent.com/of1r/k8s-monitoring/main/values.yaml

echo "Deploying MongoDB..."
kubectl apply -f mongodb.yaml

echo "Installing MongoDB exporter via Helm..."
helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f values.yaml

echo "Waiting for MongoDB exporter to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mongodb-exporter-prometheus-mongodb-exporter

echo "Port-forwarding services in the background..."
nohup kubectl port-forward deployment/prometheus-grafana 3000:3000 >/dev/null 2>&1 &
nohup kubectl port-forward service/prometheus-kube-prometheus-prometheus 9090:9090 >/dev/null 2>&1 &
nohup kubectl port-forward service/mongodb-exporter-prometheus-mongodb-exporter 9216:9216 >/dev/null 2>&1 &

IP=$(curl -s ifconfig.me)

echo ""
echo "Setup complete. To access the dashboards from your local machine, run this SSH tunnel:"
echo ""
echo "ssh -L 3000:localhost:3000 -L 9090:localhost:9090 -L 9216:localhost:9216 $USER@$IP"
echo ""
echo "Then open these URLs in your browser:"
echo " - Grafana:    http://localhost:3000"
echo " - Prometheus: http://localhost:9090"
echo " - MongoDB Exporter: http://localhost:9216"

EONG
