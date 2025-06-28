# K8s Monitoring Lab

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.33+-blue.svg)](https://kubernetes.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-2.0+-orange.svg)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-12.0+-red.svg)](https://grafana.com/)

A comprehensive monitoring stack for learning Kubernetes observability, featuring Prometheus, Grafana, and MongoDB with secure SSH tunneling access. Ideal for educational purposes, development environments, and proof-of-concept deployments.

## ✨ Features

- **Prometheus** - Metrics collection and storage
- **Grafana** - Beautiful dashboards and visualization  
- **MongoDB** - Sample database with monitoring
- **MongoDB Exporter** - Real-time MongoDB metrics
- **Alertmanager** - Alert management
- **Secure Access** - SSH tunneling (no external ports)
- **Cloud Ready** - Works on any cloud provider
- **One-Click Setup** - Single script installation

## 🚀 Quick Start

### Prerequisites
- Linux VM (Ubuntu/Debian)
- SSH access

### Installation
```bash
git clone https://github.com/of1r/k8s-monitoring-lab.git
cd k8s-monitoring-lab
chmod +x setup.sh
./setup.sh
```

### Access Dashboards
```bash
# From your local machine
ssh -L 3000:localhost:3000 -L 9090:localhost:9090 -L 9093:localhost:9093 -L 9216:localhost:9216 user@YOUR_VM_IP
```

Then visit:
- **Grafana**: http://localhost:3000 (`admin` / `prom-operator`)
- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093
- **MongoDB Exporter**: http://localhost:9216

## 🔧 Verification

```bash
# Check all pods are running
kubectl get pods

# Verify Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health == "up") | .labels.job'

# Test MongoDB exporter
curl -s http://localhost:9216/metrics | grep mongodb_up
```

## 🛠️ Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **"No data" in Grafana** | Wait 2-3 minutes for initial data collection |
| **SSH tunneling fails** | Verify VM IP and port forwarding is active |
| **Port forwarding stopped** | Restart with `kubectl port-forward` commands |
| **Pods not ready** | Check with `kubectl get pods` and `kubectl logs` |

## 🔒 Security

- ✅ **No external port exposure**
- ✅ **SSH tunneling only**
- ✅ **No firewall configuration needed**
- ✅ **Secure by default**

## 📁 Project Structure

```
k8s-monitoring-lab/
├── setup.sh          # Main installation script
├── mongodb.yaml      # MongoDB deployment
├── values.yaml       # MongoDB Exporter config
└── README.md         # This file
```
