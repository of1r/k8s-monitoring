#!/bin/bash

set -e

echo "K8s Monitoring Setup"
echo "Checking pre-installed tools..."

# Check what's already installed
if command -v docker &> /dev/null; then
    echo "Docker is already installed"
else
    echo "Docker not found - this script requires Docker"
    exit 1
fi

if command -v kubectl &> /dev/null; then
    echo "kubectl is already installed"
else
    echo "kubectl not found - this script requires kubectl"
    exit 1
fi

if command -v helm &> /dev/null; then
    echo "Helm is already installed"
else
    echo "Installing Helm..."
    curl -sSL https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz -o helm.tar.gz
    tar -zxvf helm.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64 helm.tar.gz
fi

# Check if Minikube is installed
if command -v minikube &> /dev/null; then
    echo "Minikube is already installed"
else
    echo "Installing Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
fi

echo "Starting Minikube..."
minikube start --driver=docker

echo "Adding Prometheus Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "Installing Prometheus stack..."
helm install prometheus prometheus-community/kube-prometheus-stack

echo "Waiting for Grafana deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus-grafana

echo "Deploying MongoDB..."
kubectl apply -f mongodb.yaml

echo "Installing MongoDB exporter..."
helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f values.yaml

echo "Waiting for MongoDB exporter to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mongodb-exporter-prometheus-mongodb-exporter

echo "Setting up port forwarding..."
nohup kubectl port-forward deployment/prometheus-grafana 3000:3000 >/dev/null 2>&1 &
nohup kubectl port-forward service/prometheus-kube-prometheus-prometheus 9090:9090 >/dev/null 2>&1 &
nohup kubectl port-forward service/mongodb-exporter-prometheus-mongodb-exporter 9216:9216 >/dev/null 2>&1 &

echo ""
echo "Setup complete! Your monitoring stack is ready."
echo ""
echo "Access your dashboards:"
echo " - Grafana:    http://localhost:3000 (admin/admin)"
echo " - Prometheus: http://localhost:9090"
echo " - MongoDB Exporter: http://localhost:9216"
echo ""
echo "Note: Cloud Shell sessions are ephemeral. If you close this session,"
echo "you'll need to run this setup again."
