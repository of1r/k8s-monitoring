#!/bin/bash
set -e

echo ""
echo "+==============================================================+"
echo "|                    K8s Monitoring Lab Setup                   |"
echo "|              Prometheus + Grafana + MongoDB Exporter          |"
echo "+==============================================================+"
echo ""

echo "[1/12] Updating package manager..."
sudo apt-get update

echo "[2/12] Installing required tools..."
sudo apt-get install -y curl wget

echo "[3/12] Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    newgrp docker << EONG
    echo "Docker group changes applied successfully."
EONG
else
    echo "Docker is already installed, skipping installation..."
fi

echo "[4/12] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl is already installed, skipping installation..."
fi

echo "[5/12] Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
else
    echo "Minikube is already installed, skipping installation..."
fi

echo "[6/12] Starting Minikube..."
minikube start --cpus 4 --memory 8192 --driver=docker

echo "[7/12] Setting up kubectl..."
alias kubectl="minikube kubectl --"
echo "alias kubectl='minikube kubectl --'" >> ~/.bashrc

echo "[8/12] Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl -sSL https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz -o helm.tar.gz
    tar -zxvf helm.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf helm.tar.gz linux-amd64
else
    echo "Helm is already installed, skipping installation..."
fi

echo "[9/12] Installing Prometheus Stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm uninstall prometheus 2>/dev/null || true
sleep 5
helm install prometheus prometheus-community/kube-prometheus-stack \
  --set prometheus.prometheusSpec.externalLabels.cluster=minikube

echo "[10/12] Deploying MongoDB and Exporter..."
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/mongodb.yaml
kubectl apply -f mongodb.yaml
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/values.yaml
helm uninstall mongodb-exporter 2>/dev/null || true
sleep 5
helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f values.yaml

echo "[11/12] Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n default --timeout=180s || echo "Grafana ready"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n default --timeout=180s || echo "Prometheus ready"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus-mongodb-exporter --timeout=120s || echo "MongoDB exporter ready"

echo "[12/12] Setting up external access..."
kubectl patch svc prometheus-grafana -p '{"spec":{"type":"NodePort"}}'
kubectl patch svc prometheus-kube-prometheus-prometheus -p '{"spec":{"type":"NodePort"}}'
kubectl patch svc prometheus-kube-prometheus-alertmanager -p '{"spec":{"type":"NodePort"}}'
kubectl patch svc mongodb-exporter-prometheus-mongodb-exporter -p '{"spec":{"type":"NodePort"}}'

echo ""
echo "🎉 Setup complete!"
echo ""
echo "=== Access URLs ==="
echo "Grafana: $(minikube service prometheus-grafana --url)"
echo "Prometheus: $(minikube service prometheus-kube-prometheus-prometheus --url)"
echo "Alertmanager: $(minikube service prometheus-kube-prometheus-alertmanager --url)"
echo "MongoDB Exporter: $(minikube service mongodb-exporter-prometheus-mongodb-exporter --url)"
echo ""
echo "Default Grafana credentials: admin / prom-operator"
echo ""