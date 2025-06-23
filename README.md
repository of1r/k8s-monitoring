# k8s-monitoring-lab

A complete Kubernetes monitoring stack with Prometheus, Grafana, MongoDB, and MongoDB Exporter.

## 🚀 Launch in Google Cloud Shell

Click the button below to launch and auto-deploy the monitoring stack (Minikube, Prometheus, Grafana, MongoDB) in Google Cloud Shell:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/of1r/k8s-monitoring&cloudshell_working_dir=.&cloudshell_startup=setup.sh)

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

```bash
# Clone the repository
git clone https://github.com/of1r/k8s-monitoring.git
cd k8s-monitoring

# Make executable and run
chmod +x setup.sh
./setup.sh
```

## 🧪 Testing Your Setup

After running the setup, test everything is working:

```bash
chmod +x test-setup.sh
./test-setup.sh
```

This will run comprehensive tests and show you the status of all components.

## 🔧 Troubleshooting

### Grafana Login Issues
If Grafana shows "logged in" but redirects back to login page:

```bash
chmod +x fix-grafana-login.sh
./fix-grafana-login.sh
```

### Common Issues
1. **Port forwarding stopped**: Restart with the commands shown in setup output
2. **CORS issues**: Clear browser cache or use incognito mode
3. **Pods not ready**: Check with `kubectl get pods` and `kubectl describe pod <pod-name>`

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
```

## 📋 Prerequisites

- Docker
- Minikube (installed automatically by script)
- kubectl (installed automatically by script)
- Helm (installed automatically by script)

## 📁 Files

- `setup.sh` - Main setup script
- `test-setup.sh` - Comprehensive testing script
- `fix-grafana-login.sh` - Fixes Grafana login redirect issues
- `mongodb.yaml` - MongoDB deployment configuration
- `values.yaml` - MongoDB Exporter Helm values
- `README.md` - This file

## 🎯 What You Get

- **Prometheus**: Metrics collection and storage
- **Grafana**: Beautiful dashboards and visualization
- **MongoDB**: Sample database for monitoring
- **MongoDB Exporter**: Exports MongoDB metrics to Prometheus
- **Alertmanager**: Alert management (optional)

## 🔍 Verification

1. **Prometheus**: Go to http://localhost:9090 → Status → Targets
2. **Grafana**: Login at http://localhost:8080 (admin/prom-operator)
3. **MongoDB Metrics**: Query `mongodb_up` in Prometheus (should return 1)
4. **Test Script**: Run `./test-setup.sh` for comprehensive verification
