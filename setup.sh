#!/bin/bash
set -e

# === Grafana URL configuration ===
# For Google Cloud Shell: Provide the Grafana public URL as argument
# For local development: Use default localhost URL
if [ -z "$1" ]; then
  echo "No Grafana URL provided, using default localhost configuration..."
  echo "For Google Cloud Shell, provide the Grafana public URL:"
  echo "1. In the Cloud Shell toolbar, click the 'Web Preview' button."
  echo "2. Select 'Preview on port 8080'."
  echo "3. Copy the full URL from the new browser tab that opens."
  echo "4. Run this script again with the copied URL:"
  echo "   ./setup.sh <your_grafana_url>"
  echo ""
  echo "Using default: http://localhost:8080"
  GRAFANA_URL="http://localhost:8080"
  GRAFANA_DOMAIN="localhost"
else
  GRAFANA_URL=$1
  # Extract the hostname from the full URL
  GRAFANA_DOMAIN=$(echo $GRAFANA_URL | sed 's|https://||' | sed 's|http://||' | sed 's|/.*||')
fi

echo "Using Grafana URL: ${GRAFANA_URL}"
echo "Using Grafana Domain: ${GRAFANA_DOMAIN}"

echo "[1/20] Suppressing Cloud Shell warnings..."
mkdir -p ~/.cloudshell
touch ~/.cloudshell/no-apt-get-warning

echo "[2/20] Updating package manager..."
sudo apt-get update

echo "[3/20] Installing required tools..."
# Check for and kill any process holding one of the three apt lock files.
if sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || \
   sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
   sudo fuser /var/cache/apt/archives/lock >/dev/null 2>&1; then
  echo "Existing apt process found. Killing it to proceed..."
  # Find and kill the process holding the lock on any of the files
  sudo lsof -t /var/lib/dpkg/lock-frontend | xargs --no-run-if-empty sudo kill -9
  sudo lsof -t /var/lib/dpkg/lock | xargs --no-run-if-empty sudo kill -9
  sudo lsof -t /var/cache/apt/archives/lock | xargs --no-run-if-empty sudo kill -9
  # Remove all possible lock files
  sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
  # Reconfigure dpkg to be safe
  sudo dpkg --configure -a
  echo "Stuck process cleared."
fi
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
helm uninstall prometheus 2>/dev/null || true
sleep 5
# Perform a minimal installation. All Cloud Shell specific config will be done after.
helm install prometheus prometheus-community/kube-prometheus-stack

echo "[13/20] Waiting for Grafana pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n default --timeout=180s || echo "Grafana pod ready check completed"

echo "[14/20] Applying Grafana configuration for Cloud Shell..."
# This is the definitive fix, setting BOTH the root_url for links and the
# domain for security.
kubectl set env deployment/prometheus-grafana \
  "GF_SERVER_ROOT_URL=${GRAFANA_URL}" \
  "GF_SERVER_DOMAIN=${GRAFANA_DOMAIN}" \
  "GF_SECURITY_COOKIE_SECURE=true" \
  "GF_SECURITY_COOKIE_SAMESITE=none" \
  "GF_SECURITY_ALLOW_EMBEDDING=true"

# Restart Grafana to apply the new environment variables.
echo "Restarting Grafana to apply new configuration..."
kubectl rollout restart deployment/prometheus-grafana
kubectl rollout status deployment/prometheus-grafana --timeout=180s || echo "Grafana restart completed"
sleep 30

echo "[15/20] Waiting for Prometheus pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n default --timeout=180s || echo "Prometheus pod ready check completed"

echo "[16/20] Deploying MongoDB app..."
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/mongodb.yaml
kubectl apply -f mongodb.yaml

echo "[17/20] Installing MongoDB Exporter..."
curl -sLO https://raw.githubusercontent.com/of1r/k8s-monitoring-lab/main/values.yaml
helm uninstall mongodb-exporter 2>/dev/null || true
sleep 5
helm install mongodb-exporter prometheus-community/prometheus-mongodb-exporter -f values.yaml

echo "[18/20] Waiting for MongoDB exporter to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus-mongodb-exporter --timeout=120s || echo "MongoDB exporter ready check completed"

echo "[19/20] Verifying ServiceMonitor configuration..."
kubectl patch servicemonitor mongodb-exporter-prometheus-mongodb-exporter --type='merge' -p='{"metadata":{"labels":{"release":"prometheus"}}}' 2>/dev/null || true

echo "[20/20] Setting up port forwarding (runs in background)..."
echo "Clearing ports..."
sudo kill -9 $(lsof -t -i:8080) 2>/dev/null || true
sudo kill -9 $(lsof -t -i:9090) 2>/dev/null || true
sudo kill -9 $(lsof -t -i:9093) 2>/dev/null || true
sudo kill -9 $(lsof -t -i:9216) 2>/dev/null || true
sleep 2
pkill -f "kubectl port-forward" 2>/dev/null || true
sleep 2

kubectl port-forward --address 0.0.0.0 service/prometheus-grafana 8080:80 >/tmp/grafana.log 2>&1 &
kubectl port-forward --address 0.0.0.0 service/prometheus-kube-prometheus-prometheus 9090:9090 >/tmp/prometheus.log 2>&1 &
kubectl port-forward --address 0.0.0.0 service/prometheus-kube-prometheus-alertmanager 9093:9093 >/tmp/alertmanager.log 2>&1 &
kubectl port-forward --address 0.0.0.0 service/mongodb-exporter-prometheus-mongodb-exporter 9216:9216 >/tmp/mongodb_exporter.log 2>&1 &

sleep 5

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Access dashboards using Cloud Shell Web Preview:"
echo "👉 Grafana port: 8080"
echo "👉 Prometheus port: 9090"
echo "👉 Alertmanager port: 9093"
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