# Monitoring & Logging Setup

This document describes the comprehensive monitoring and logging setup for the Restauranty microservices application.

## 📊 Monitoring Stack

### Components
- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **Prometheus Operator**: Kubernetes-native monitoring setup
- **ServiceMonitors**: Automatic service discovery for metrics scraping

### Access
- **Grafana Dashboards**: http://grafana.sebsrestaurant.diogohack.shop
- **Prometheus**: http://prometheus.sebsrestaurant.diogohack.shop
- **Authentication**: Username `admin` / Password: (set during setup)

### Available Dashboards
1. **Auth Service Dashboard** - HTTP metrics, event loop lag, memory usage
2. **Items Service Dashboard** - Request rates, latencies, Node.js metrics
3. **Discounts Service Dashboard** - Performance metrics, resource usage
4. **Node Exporter Dashboard** - Infrastructure metrics (CPU, memory, disk)


### Metrics Available
- HTTP request rates and status codes
- Response latency percentiles
- Node.js event loop lag
- Memory usage (heap size, RSS)
- CPU utilization
- Active handles and requests
- Garbage collection metrics
- Infrastructure metrics (CPU, memory, disk, network)

## 📋 Logging Setup

### Architecture
- **Application Logs**: All services log to stdout/stderr
- **Kubernetes Integration**: Automatic log collection via kubectl
- **CloudWatch Integration**: EKS cluster logs stored in CloudWatch
- **Centralized Access**: Logs available via kubectl commands and AWS Console

### Viewing Application Logs

#### Via kubectl (Recommended)
```bash
# View logs for specific service (real-time)
kubectl logs -n restauranty deployment/auth -f
kubectl logs -n restauranty deployment/items -f
kubectl logs -n restauranty deployment/discounts -f
kubectl logs -n restauranty deployment/frontend -f

# View logs for specific pod
kubectl get pods -n restauranty
kubectl logs -n restauranty <pod-name> -f

# View logs with timestamps
kubectl logs -n restauranty deployment/auth --timestamps=true --tail=100

# View logs from all containers in a deployment
kubectl logs -n restauranty deployment/auth --all-containers=true
```

#### Via AWS CloudWatch
1. Go to AWS Console → CloudWatch → Log Groups
2. Available log groups:
   - `/aws/eks/restauranty-eks/cluster` (EKS control plane logs)
   - Individual container logs available through EKS integration

### Log Types
- **Application Logs**: Express.js access logs, application events
- **Metrics Logs**: Prometheus scraping logs
- **Infrastructure Logs**: Kubernetes cluster events
- **Error Logs**: Application errors and stack traces

## 🚀 Quick Start

### Access Monitoring
1. Open Grafana: http://grafana.sebsrestaurant.diogohack.shop
2. Login with admin credentials
3. Navigate to dashboards to view metrics

### View Logs
```bash
# Check all running pods
kubectl get pods -n restauranty

# View real-time logs
kubectl logs -n restauranty deployment/auth -f

# Check recent errors
kubectl logs -n restauranty deployment/auth --tail=50 | grep -i error
```

## 🔧 Configuration Files

### Monitoring
- `k8s/monitoring/values-kube-prometheus.yaml` - Prometheus stack configuration
- `k8s/monitoring/servicemonitors/` - Service discovery configuration
- `k8s/monitoring/dashboards/` - Grafana dashboard definitions
- `k8s/monitoring/monitoring-ingress.yaml` - Secured ingress with authentication

### Logging
- `k8s/logging/logging-setup.yaml` - Basic logging configuration
- `k8s/logging/log-instructions.md` - Detailed logging access guide

## 📈 Monitoring Best Practices

### Alerts (Future Enhancement)
The current setup includes Prometheus AlertManager. Consider adding:
- High error rate alerts
- Resource utilization alerts
- Service availability alerts

## 🔒 Security

### Monitoring Access
- Grafana protected with basic authentication
- Prometheus access restricted via ingress
- Rate limiting enabled to prevent abuse

### Log Security
- Logs contain no sensitive information (passwords, tokens)
- Access controlled via Kubernetes RBAC
- CloudWatch access via AWS IAM

## 🛠️ Troubleshooting

### Common Issues
1. **No metrics showing**: Check if ServiceMonitors are properly configured
2. **Cannot access Grafana**: Verify ingress and authentication setup
3. **Missing logs**: Ensure pods are running and logging to stdout