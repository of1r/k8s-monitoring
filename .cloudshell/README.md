# 🚀 K8s Monitoring Setup

Welcome! This repository will automatically set up a complete Kubernetes monitoring stack with:

- **Prometheus** - Metrics collection and storage
- **Grafana** - Visualization and dashboards  
- **MongoDB** - Database with monitoring
- **MongoDB Exporter** - Metrics for MongoDB

## 🎯 What happens automatically:

1. ✅ Repository clones to Cloud Shell
2. ✅ Setup script runs automatically
3. ✅ All services are deployed and configured
4. ✅ Port forwarding is set up for access

## 📊 Access your dashboards:

After setup completes, you can access:
- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **MongoDB Exporter**: http://localhost:9216

## 🔧 Manual setup (if needed):

If the auto-setup doesn't work, you can run manually:
```bash
chmod +x setup.sh
./setup.sh
```

## 📝 Notes:

- This setup uses Minikube for local Kubernetes
- All services run in the Cloud Shell environment
- Port forwarding allows local access to dashboards 