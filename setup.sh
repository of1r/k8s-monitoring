#!/bin/bash
set -e

echo "[1/20] Suppressing Cloud Shell warnings..."
mkdir -p ~/.cloudshell
touch ~/.cloudshell/no-apt-get-warning

echo "[2/20] Updating package manager..."
sudo apt-get update

echo "[3/20] Installing required tools..."
sudo apt-get install -y lsof

echo "[4/20] Installing Docker..."
if ! command -v docker &> /dev/null; then
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
else
    echo "Docker is already installed, skipping installation..."
fi

echo "[5/20] Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl is already installed, skipping installation..."
fi

echo "[6/20] Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
else
    echo "Minikube is already installed, skipping installation..."
fi

echo "[7/20] Starting Minikube..."
# Try hyperkit first (original), fall back to docker if not available
if command -v hyperkit &> /dev/null; then
    minikube start --cpus 4 --memory 8192 --vm-driver hyperkit
else
    echo "Hyperkit not available, using docker driver with Cloud Shell optimized settings..."
    minikube start --cpus 2 --memory 4096 --driver=docker
fi

echo "[8/20] Downloading kubectl for Minikube..."
minikube kubectl -- get po -A

echo "[9/20] Enabling kubectl..."
alias kubectl="minikube kubectl --"
echo "alias kubectl='minikube kubectl --'" >> ~/.bashrc

echo "[10/20] Installing Helm..."
curl -sSL https://get.helm.sh/helm-v3.18.3-linux-amd64.tar.gz -o helm.tar.gz
tar -zxvf helm.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf helm.tar.gz linux-amd64

echo "[11/20] Adding Prometheus Community repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "[12/20] Installing Prometheus Stack..."
helm install prometheus prometheus-community/kube-prometheus-stack --set grafana.config.security.allow_embedding=true --set grafana.config.security.allow_embedding_from_domain="*" --set grafana.config.security.cookie_samesite=none --set grafana.config.security.cookie_secure=false

echo "[13/20] Waiting for Grafana pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n default --timeout=180s

echo "[14/20] Configuring Grafana CORS settings..."
# Apply additional CORS configuration
kubectl patch configmap prometheus-grafana --type='merge' -p='{"data":{"grafana.ini":"[security]\nallow_embedding = true\nallow_embedding_from_domain = *\ncookie_samesite = none\ncookie_secure = false\n\n[server]\nallow_embedding = true\n"}}' 2>/dev/null || true

# Restart Grafana to apply CORS settings
kubectl rollout restart deployment/prometheus-grafana
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n default --timeout=180s

echo "[15/20] Waiting for Prometheus pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n default --timeout=180s

echo "[16/20] Deploying MongoDB app..."
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/mongodb.yaml
kubectl apply -f mongodb.yaml

echo "[17/20] Installing MongoDB Exporter..."
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/values.yaml
helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f values.yaml

echo "[18/20] Waiting for MongoDB exporter to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus-mongodb-exporter --timeout=120s

echo "[19/20] Verifying ServiceMonitor configuration..."
# Ensure the ServiceMonitor has the correct labels
kubectl patch servicemonitor mongodb-exporter-prometheus-mongodb-exporter --type='merge' -p='{"metadata":{"labels":{"release":"prometheus"}}}' 2>/dev/null || true

echo "[20/20] Setting up port forwarding (runs in background)..."

# Kill any processes using our ports
echo "Clearing ports..."
sudo kill -9 $(lsof -t -i:8080) 2>/dev/null || true
sudo kill -9 $(lsof -t -i:9090) 2>/dev/null || true
sudo kill -9 $(lsof -t -i:9216) 2>/dev/null || true
sleep 2

# Kill current forwarding
pkill -f kubectl

# Try service on port 8080
kubectl port-forward --address 0.0.0.0 service/prometheus-grafana 8080:80 >/tmp/grafana.log 2>&1 &
kubectl port-forward --address 0.0.0.0 service/prometheus-kube-prometheus-prometheus 9090:9090 >/tmp/prometheus.log 2>&1 &
kubectl port-forward --address 0.0.0.0 service/mongodb-exporter-prometheus-mongodb-exporter 9216:9216 >/tmp/mongodb_exporter.log 2>&1 &

sleep 5
echo ""
echo "🎉 Setup complete!"
echo ""
echo "Access dashboards using Cloud Shell Web Preview:"
echo "👉 Grafana port: 8080"
echo "👉 Prometheus port: 9090"
echo "👉 MongoDB Exporter port: 9216"
echo ""
echo "Default Grafana credentials:"
echo "Username: admin"
echo "Password: prom-operator"
echo ""
echo "To verify everything is working:"
echo "1. Check Prometheus targets: Go to Prometheus (port 9090) → Status → Targets"
echo "2. Look for mongodb-exporter target (should be UP)"
echo "3. In Prometheus, query: mongodb_up (should return 1)"
echo "4. In Grafana, create a new dashboard and query: mongodb_up"
echo ""
echo "If you see 'No data' in Grafana:"
echo "- Wait 2-3 minutes for first scrape"
echo "- Check time range (set to 'Last 15 minutes')"
echo "- Verify data source is set to 'Prometheus'"
echo ""
echo "If you encounter issues, check the logs:"
echo "cat /tmp/grafana.log"
echo "cat /tmp/mongodb_exporter.log"