#!/bin/bash
set -e

echo "[1/10] Starting Minikube..."
minikube start --driver=docker

echo "[2/10] Enabling kubectl..."
alias kubectl="minikube kubectl --"
echo "alias kubectl='minikube kubectl --'" >> ~/.bashrc

echo "[3/10] Installing Helm..."
curl -sSL https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm.tar.gz linux-amd64

echo "[4/10] Adding Prometheus Community repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "[5/10] Installing Prometheus Stack..."
helm install prometheus prometheus-community/kube-prometheus-stack

echo "[6/10] Waiting for Grafana pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n default --timeout=180s

echo "[7/10] Waiting for Prometheus pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n default --timeout=180s

echo "[8/10] Deploying MongoDB app..."
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/mongodb.yaml
kubectl apply -f mongodb.yaml

echo "[9/10] Installing MongoDB Exporter..."
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/values.yaml
helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f values.yaml

echo "[10/10] Setting up port forwarding (runs in background)..."
kubectl port-forward deployment/prometheus-grafana 3000:3000 >/dev/null 2>&1 &
kubectl port-forward service/prometheus-kube-prometheus-prometheus 9090 >/dev/null 2>&1 &
kubectl port-forward service/mongodb-exporter-prometheus-mongodb-exporter 9216 >/dev/null 2>&1 &

sleep 5
echo ""
echo "🎉 Setup complete!"
echo ""
echo "Access dashboards using Cloud Shell Web Preview:"
echo "👉 Grafana port: 3000"
echo "👉 Prometheus port: 9090"
echo "👉 MongoDB Exporter port: 9216"