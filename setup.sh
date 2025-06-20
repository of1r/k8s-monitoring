#!/bin/bash

set -e

echo "[1/10] Updating packages..."
sudo apt-get update -y

echo "[2/10] Installing Docker..."
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
newgrp docker <<EOF
echo "Docker group updated"
EOF

echo "[3/10] Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo "[4/10] Starting Minikube..."
minikube start --driver=docker

echo "[5/10] Installing Helm..."
curl -LO https://get.helm.sh/helm-v3.13.3-linux-amd64.tar.gz
tar -xzf helm-v3.13.3-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64 helm-v3.13.3-linux-amd64.tar.gz

echo "[6/10] Deploying Prometheus stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack

echo "[7/10] Waiting for Grafana to be ready..."
kubectl wait --for=condition=available deployment/prometheus-grafana --timeout=180s

echo "[8/10] Deploying MongoDB and exporter..."
curl -O https://raw.githubusercontent.com/of1r/k8s-monitoring/main/mongodb.yaml
kubectl apply -f mongodb.yaml

curl -O https://raw.githubusercontent.com/of1r/k8s-monitoring/main/values.yaml
helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f values.yaml

echo "[9/10] Setting up Web Preview port-forwarding (background)..."
kubectl port-forward svc/prometheus-grafana 3000:80 &
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward svc/mongodb-exporter-prometheus-mongodb-exporter 9216:9216 &

echo "[10/10] Setup complete."
echo ""
echo "✔ You can now access the dashboards via Web Preview (top-right menu):"
echo " - Grafana: http://localhost:3000"
echo " - Prometheus: http://localhost:9090"
echo " - MongoDB Exporter: http://localhost:9216"