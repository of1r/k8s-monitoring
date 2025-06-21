#!/bin/bash
set -e

echo "[1/18] Suppressing Cloud Shell warnings..."
mkdir -p ~/.cloudshell
touch ~/.cloudshell/no-apt-get-warning

echo "[2/18] Updating package manager..."
sudo apt-get update

echo "[3/18] Installing required tools..."
sudo apt-get install -y lsof

echo "[4/18] Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
else
    echo "Docker is already installed, skipping installation..."
fi

echo "[5/18] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl is already installed, skipping installation..."
fi

echo "[6/18] Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
else
    echo "Minikube is already installed, skipping installation..."
fi

echo "[7/18] Starting Minikube..."
minikube start --driver=docker

echo "[8/18] Downloading kubectl for Minikube..."
minikube kubectl -- get po -A

echo "[9/18] Enabling kubectl..."
alias kubectl="minikube kubectl --"
echo "alias kubectl='minikube kubectl --'" >> ~/.bashrc

echo "[10/18] Installing Helm..."
curl -sSL https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm.tar.gz linux-amd64

echo "[11/18] Adding Prometheus Community repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "[12/18] Installing Prometheus Stack..."
helm install prometheus prometheus-community/kube-prometheus-stack

echo "[13/18] Waiting for Grafana pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n default --timeout=180s

echo "[14/18] Waiting for Prometheus pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n default --timeout=180s

echo "[15/18] Deploying MongoDB app..."
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/mongodb.yaml
kubectl apply -f mongodb.yaml

echo "[16/18] Installing MongoDB Exporter..."
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/values.yaml
helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f values.yaml

echo "[17/18] Waiting for MongoDB exporter to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus-mongodb-exporter --timeout=120s

echo "[18/18] Setting up port forwarding (runs in background)..."

# Kill any processes using our ports
echo "Clearing ports..."
sudo kill -9 $(lsof -t -i:3000) 2>/dev/null || true
sudo kill -9 $(lsof -t -i:9090) 2>/dev/null || true
sudo kill -9 $(lsof -t -i:9216) 2>/dev/null || true
sleep 2

kubectl port-forward --address 0.0.0.0 deployment/prometheus-grafana 3000:3000 >/tmp/grafana.log 2>&1 &
kubectl port-forward --address 0.0.0.0 service/prometheus-kube-prometheus-prometheus 9090:9090 >/tmp/prometheus.log 2>&1 &
kubectl port-forward --address 0.0.0.0 service/mongodb-exporter-prometheus-mongodb-exporter 9216:9216 >/tmp/mongodb_exporter.log 2>&1 &

sleep 5
echo ""
echo "🎉 Setup complete!"
echo ""
echo "Access dashboards using Cloud Shell Web Preview:"
echo "👉 Grafana port: 3000"
echo "👉 Prometheus port: 9090"
echo "👉 MongoDB Exporter port: 9216"
echo ""
echo "Default Grafana credentials:"
echo "Username: admin"
echo "Password: prom-operator"
echo ""
echo "To verify MongoDB metrics are being scraped:"
echo "1. Go to Prometheus (port 9090)"
echo "2. Check 'Status' → 'Targets' to see mongodb-exporter"
echo "3. Query 'mongodb_up' to verify connection"
echo "4. Wait 1-2 minutes for first scrape"
echo ""
echo "If you encounter issues, check the logs:"
echo "cat /tmp/grafana.log"
echo "cat /tmp/mongodb_exporter.log"