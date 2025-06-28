# k8s-monitoring-lab

A complete Kubernetes monitoring stack with Prometheus, Grafana, MongoDB, and MongoDB Exporter, optimized for cloud VM deployment with secure SSH tunneling access.

## 🚀 Quick Start

### Prerequisites
- Linux VM (Ubuntu/Debian recommended)
- SSH access to the VM
- Internet connection

### Setup Instructions

```bash
# Clone the repository
git clone https://github.com/of1r/k8s-monitoring-lab.git
cd k8s-monitoring-lab

# Make executable and run
chmod +x setup.sh
./setup.sh
```

### What happens automatically:
1. ✅ Installs Docker, kubectl, Minikube, and Helm
2. ✅ Starts Minikube with Docker driver
3. ✅ Deploys Prometheus stack (Prometheus + Grafana + Alertmanager)
4. ✅ Deploys MongoDB with monitoring
5. ✅ Deploys MongoDB Exporter
6. ✅ Starts port forwarding for secure access
7. ✅ Fixes Minikube-specific Prometheus targets
8. ✅ Provides SSH tunneling instructions

## 🔐 Secure Access via SSH Tunneling

The setup uses SSH tunneling for secure access. From your local machine:

```bash
# Replace with your VM's IP address
ssh -L 3000:localhost:3000 -L 9090:localhost:9090 -L 9093:localhost:9093 -L 9216:localhost:9216 user@YOUR_VM_IP
```

Then access your dashboards locally:
- **Grafana**: http://localhost:3000 (admin/prom-operator)
- **Prometheus**: http://localhost:9090  
- **Alertmanager**: http://localhost:9093
- **MongoDB Exporter**: http://localhost:9216

## 🧪 Testing Your Setup

After running the setup, verify everything is working:

```bash
# Check if all pods are running
kubectl get pods

# Check if all services are available
kubectl get services

# Check Prometheus targets
# Visit http://localhost:9090 → Status → Targets
# Should see UP targets: kube-proxy, node-exporter, mongodb-exporter

# Check MongoDB metrics
curl -s http://localhost:9216/metrics | grep mongodb_up
# Should return: mongodb_up 1
```

## 🔧 Troubleshooting

### Common Issues

1. **"No data" in Grafana**:
   - Wait 2-3 minutes for Prometheus to collect initial data
   - Check Prometheus targets at http://localhost:9090/targets
   - Verify targets are UP (not DOWN)

2. **SSH tunneling issues**:
   - Ensure you're running the SSH command from your local machine
   - Check that port forwarding is active on the VM
   - Verify your VM's IP address is correct

3. **Port forwarding stopped**:
   ```bash
   # Restart port forwarding on the VM
   pkill -f 'kubectl port-forward'
   kubectl port-forward svc/prometheus-grafana 3000:80 &
   kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 &
   kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 &
   kubectl port-forward svc/mongodb-exporter-prometheus-mongodb-exporter 9216:9216 &
   ```

4. **Pods not ready**:
   ```bash
   kubectl get pods
   kubectl describe pod <pod-name>
   kubectl logs <pod-name>
   ```

### Manual Commands
```bash
# Check status
kubectl get pods
kubectl get services

# Check logs
kubectl logs -l app.kubernetes.io/name=grafana
kubectl logs -l app.kubernetes.io/name=prometheus
kubectl logs -l app.kubernetes.io/name=prometheus-mongodb-exporter

# Check Prometheus targets
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 &
# Then visit http://localhost:9090/targets
```

## 📁 Project Files

- `setup.sh` - Main setup script
- `mongodb.yaml` - MongoDB deployment and service configuration
- `values.yaml` - MongoDB Exporter Helm values configuration
- `README.md` - This file

## 🎯 What You Get

- **Prometheus**: Metrics collection and storage
- **Grafana**: Beautiful dashboards and visualization
- **MongoDB**: Sample database for monitoring
- **MongoDB Exporter**: Exports MongoDB metrics to Prometheus
- **Alertmanager**: Alert management (included with Prometheus stack)
- **Secure Access**: SSH tunneling for secure dashboard access

## 🔍 Verification Steps

1. **Prometheus**: Go to http://localhost:9090 → Status → Targets
   - Look for UP targets: `kube-proxy`, `node-exporter`, `mongodb-exporter`
   - Some targets (kube-controller-manager, scheduler, etcd) are disabled in Minikube

2. **Grafana**: Login at http://localhost:3000 (admin/prom-operator)
   - Browse default dashboards: "Kubernetes Cluster Monitoring", "Node Exporter"
   - Should show node metrics, pod metrics, and MongoDB metrics

3. **MongoDB Metrics**: 
   - Visit http://localhost:9216 for raw metrics
   - Query `mongodb_up` in Prometheus (should return 1)

4. **Check all pods are running**: `kubectl get pods`

## 📋 Important Notes

- **Security**: Uses SSH tunneling instead of exposing ports to the internet
- **No firewall configuration needed**: Everything works through SSH tunnel
- **Minikube optimized**: Automatically fixes problematic Prometheus targets
- **Cloud VM ready**: Designed for deployment on cloud VMs (AWS, GCP, Azure, Hetzner, etc.)
- **Automatic setup**: Single script handles all installation and configuration
- **Default credentials**: Grafana admin/prom-operator (change after first login)

## 🚀 Cloud VM Deployment

This setup is optimized for cloud VM deployment:

1. **Deploy on any cloud provider** (AWS EC2, Google Compute Engine, Azure VM, Hetzner Cloud, etc.)
2. **No external port exposure** - secure SSH tunneling only
3. **Automatic dependency installation** - script handles everything
4. **Minikube optimized** - fixes common Minikube issues automatically

Perfect for learning Kubernetes monitoring, development environments, or small production deployments!
