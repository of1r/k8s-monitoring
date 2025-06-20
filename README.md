# k8s-monitoring

A complete Kubernetes monitoring stack with Prometheus, Grafana, MongoDB, and MongoDB Exporter.

## 🚀 Quick Launch in Google Cloud Shell

Click the button below to open this repo in Google Cloud Shell and automatically start the setup script:

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://ssh.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/of1r/k8s-monitoring&cloudshell_working_dir=.&cloudshell_startup=./setup.sh)

### What happens automatically:
1. ✅ Repository clones to Cloud Shell
2. ✅ Setup script runs automatically  
3. ✅ Minikube starts with Docker driver
4. ✅ Prometheus stack deploys (Prometheus + Grafana)
5. ✅ MongoDB deploys with monitoring
6. ✅ MongoDB Exporter deploys
7. ✅ Port forwarding starts for dashboard access

### Access your dashboards:
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090  
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

## 📋 Prerequisites

- Docker
- Minikube (installed automatically by script)
- kubectl (installed automatically by script)
- Helm (installed automatically by script)
