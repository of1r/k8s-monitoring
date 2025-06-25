# k8s-monitoring-lab

A complete Kubernetes monitoring stack with Prometheus, Grafana, MongoDB, and MongoDB Exporter.

## 🚀 Launch in Google Cloud Shell

Click the button below to launch and auto-deploy the monitoring stack (Minikube, Prometheus, Grafana, MongoDB) in Google Cloud Shell:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/of1r/k8s-monitoring-lab&cloudshell_working_dir=.&cloudshell_startup=setup.sh)

### What happens automatically:
1. ✅ Repository clones to Cloud Shell
2. ✅ Setup script runs automatically  
3. ✅ Minikube starts with Docker driver
4. ✅ Prometheus stack deploys (Prometheus + Grafana)
5. ✅ MongoDB deploys with monitoring
6. ✅ MongoDB Exporter deploys
7. ✅ Port forwarding starts for dashboard access

### Access your dashboards:
- **Grafana**: http://localhost:8080 (admin/prom-operator)
- **Prometheus**: http://localhost:9090  
- **Alertmanager**: http://localhost:9093
- **MongoDB Exporter**: http://localhost:9216

## 🔧 Manual Setup

If you prefer to run locally or the auto-setup doesn't work:

### Prerequisites
- Docker
- Minikube (installed automatically by script)
- kubectl (installed automatically by script)
- Helm (installed automatically by script)

### Setup Instructions

```bash
# Clone the repository
git clone https://github.com/of1r/k8s-monitoring-lab.git
cd k8s-monitoring-lab

# Make executable and run
chmod +x setup.sh

# For local development (default):
./setup.sh

# For Google Cloud Shell, you need to provide the Grafana public URL:
# 1. In the Cloud Shell toolbar, click the 'Web Preview' button
# 2. Select 'Preview on port 8080'
# 3. Copy the full URL from the new browser tab that opens
# 4. Run the script with the copied URL:
./setup.sh <your_grafana_url>
```

## 🧪 Testing Your Setup

After running the setup, verify everything is working:

```bash
# Check if all pods are running
kubectl get pods

# Check if all services are available
kubectl get services

# Check Prometheus targets
kubectl port-forward --address 0.0.0.0 service/prometheus-kube-prometheus-prometheus 9090:9090 &
# Then visit http://localhost:9090 → Status → Targets

# Check MongoDB metrics
# In Prometheus, query: mongodb_up (should return 1)
```

## 🔧 Troubleshooting

### Grafana Login Issues
If Grafana shows "logged in" but redirects back to login page:
- Wait 30 seconds for Grafana to fully restart after setup
- Clear browser cache or use incognito mode
- Ensure you're using the correct Grafana URL that was provided to the setup script

### Common Issues
1. **Port forwarding stopped**: Restart with the commands shown in setup output
2. **CORS issues**: Clear browser cache or use incognito mode
3. **Pods not ready**: Check with `kubectl get pods` and `kubectl describe pod <pod-name>`
4. **MongoDB Exporter not showing in Prometheus**: Check if ServiceMonitor labels are correct

### Manual Commands
```bash
# Check status
kubectl get pods
kubectl get services

# Restart port forwarding
pkill -f 'kubectl port-forward' && sleep 2
kubectl port-forward --address 0.0.0.0 service/prometheus-grafana 8080:80 &
kubectl port-forward --address 0.0.0.0 service/prometheus-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward --address 0.0.0.0 service/prometheus-kube-prometheus-alertmanager 9093:9093 &
kubectl port-forward --address 0.0.0.0 service/mongodb-exporter-prometheus-mongodb-exporter 9216:9216 &

# Check logs
kubectl logs -l app.kubernetes.io/name=grafana
kubectl logs -l app.kubernetes.io/name=prometheus
kubectl logs -l app.kubernetes.io/name=prometheus-mongodb-exporter
```

## 📁 Project Files

- `setup.sh` - Main setup script (requires Grafana URL parameter)
- `mongodb.yaml` - MongoDB deployment and service configuration
- `values.yaml` - MongoDB Exporter Helm values configuration
- `README.md` - This file

## 🎯 What You Get

- **Prometheus**: Metrics collection and storage
- **Grafana**: Beautiful dashboards and visualization
- **MongoDB**: Sample database for monitoring
- **MongoDB Exporter**: Exports MongoDB metrics to Prometheus
- **Alertmanager**: Alert management (included with Prometheus stack)

## 🔍 Verification Steps

1. **Prometheus**: Go to http://localhost:9090 → Status → Targets
   - Look for `mongodb-exporter-prometheus-mongodb-exporter` target (should be UP)
2. **Grafana**: Login at http://localhost:8080 (admin/prom-operator)
   - Create a new dashboard and query: `mongodb_up`
3. **MongoDB Metrics**: Query `mongodb_up` in Prometheus (should return 1)
4. **Check all pods are running**: `kubectl get pods`

## 📋 Important Notes

- The setup script accepts an optional Grafana URL parameter for Cloud Shell configuration
- For Google Cloud Shell: Provide the Web Preview URL for port 8080 as an argument
- For local development: Run without arguments to use default localhost configuration
- The MongoDB Exporter automatically scrapes metrics from the MongoDB instance
- All components are configured to work together out of the box
