# Restauranty - Microservices Restaurant Platform

Production-ready microservices architecture with complete DevOps automation for restaurant management.

## Architecture

- **Auth Service** (Port 3001) - Authentication & JWT management
- **Discounts Service** (Port 3002) - Coupons & promotions  
- **Items Service** (Port 3003) - Menu items & orders
- **React Client** (Port 80) - Frontend web interface (3000 in dev mode)
- **MongoDB** (Port 27017) - Database

## Prerequisites

```bash
# Required tools
- Docker & Docker Compose
- Node.js 18+
- kubectl
- Terraform (for AWS deployment)
- HAProxy (for local development)
```

## Quick Start

### 1. Local Development

**Single Command Setup:**
```bash
# Start all services locally
docker-compose up --build
```

**Individual Services:**
```bash
# Backend services
cd backend/auth && npm install && npm start       # Port 3001
cd backend/discounts && npm install && npm start  # Port 3002  
cd backend/items && npm install && npm start      # Port 3003

# Frontend
cd client && npm install && npm start             # Port 3000

# HAProxy for routing                             # Port 80
haproxy -f haproxy.cfg
```

### 2. Production Deployment

**Infrastructure (AWS EKS):**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Connect to cluster:**
```bash
aws eks update-kubeconfig --region us-west-2 --name restauranty-cluster
```

**Deploy applications:**
```bash
# Create namespaces
kubectl apply -f k8s/monitoring/namespace.yaml
kubectl apply -f k8s/namespace.yaml

# Deploy MongoDB
kubectl apply -f k8s/mongo/

# Deploy backend services
kubectl apply -f k8s/auth/
kubectl apply -f k8s/discounts/
kubectl apply -f k8s/items/

# Deploy frontend
kubectl apply -f k8s/frontend/

# Setup ingress
kubectl apply -f k8s/ingress/
```

**Setup monitoring:**
```bash
# Install Prometheus stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Apply ServiceMonitors
kubectl apply -f k8s/monitoring/servicemonitors/

# Import Grafana dashboards
./scripts/import-dashboards.sh
```

**Setup SSL certificates:**
```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml

# Apply certificate issuers
kubectl apply -f k8s/cert-manager/

# Deploy certificates
./scripts/deploy-certs.sh
```

### 3. CI/CD Pipeline

Pipeline automatically triggers on push to `main` branch:

```bash
# GitHub Actions workflow (.github/workflows/cicd.yml)
1. Build & test all services
2. Build Docker images  
3. Push to container registry
4. Deploy to Kubernetes
5. Run integration tests
```

**Required GitHub Secrets:**
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY  
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
KUBECONFIG_DATA
```

## Environment Variables

Copy and configure:
```bash
cp .env.example .env
```

**Required variables:**
```
MONGO_URI=mongodb://localhost:27017/restauranty
JWT_SECRET=your-jwt-secret
PORT=3001  # (varies per service)
```

## API Endpoints

| Service | Base URL | Routes |
|---------|----------|--------|
| Auth | `/api/auth` | `/login`, `/register`, `/verify` |
| Items | `/api/items` | `/`, `/:id`, `/search` |
| Discounts | `/api/discounts` | `/`, `/:id`, `/apply` |

## Monitoring & Observability

**Access Grafana:**
```bash
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
# Open http://localhost:3000 (admin/prom-operator)
```

**Access Prometheus:**
```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
# Open http://localhost:9090
```

**View logs:**
```bash
# Service logs
kubectl logs -f deployment/auth -n restauranty
kubectl logs -f deployment/discounts -n restauranty  
kubectl logs -f deployment/items -n restauranty

# Aggregated logs (ELK stack)
kubectl port-forward svc/kibana -n logging 5601:5601
```

## Troubleshooting

**Check service status:**
```bash
kubectl get pods -n restauranty -o wide
kubectl get svc -n restauranty
kubectl get ingress -n restauranty
```

**Debug specific service:**
```bash
kubectl describe pod <pod-name> -n restauranty
kubectl logs <pod-name> -n restauranty
```

**Check monitoring targets:**
```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
curl http://localhost:9090/api/v1/targets
```

## Development Workflow

1. **Local Development**: Use `docker-compose up` or individual `npm start`
2. **Testing**: Run tests with `npm test` in each service directory
3. **Build**: `docker build` or automated via CI/CD
4. **Deploy**: Push to `main` branch triggers auto-deployment
5. **Monitor**: Check Grafana dashboards and Prometheus metrics

## File Structure

```
devops.restauranty/
├── backend/              # Node.js microservices
│   ├── auth/            # Authentication service
│   ├── discounts/       # Discounts service  
│   └── items/           # Items service
├── client/              # React frontend
├── docs/                # Documentation
│   ├── CERT_DEPLOYMENT.md
│   ├── DELIVERABLES_SUMMARY.md
│   ├── FINAL.md
│   └── MONITORING_AND_LOGGING.md
├── scripts/             # Deployment scripts
│   ├── deploy-certs.sh
│   └── import-dashboards.sh
├── k8s/                 # Kubernetes manifests
│   ├── auth/           # Auth deployment
│   ├── discounts/      # Discounts deployment
│   ├── items/          # Items deployment
│   ├── frontend/       # Frontend deployment
│   ├── ingress/        # Ingress controller
│   ├── monitoring/     # Prometheus/Grafana
│   └── cert-manager/   # SSL certificates
├── terraform/          # AWS EKS infrastructure
├── .github/workflows/  # CI/CD pipeline
├── docker-compose.yml  # Local development
├── haproxy.cfg        # Local load balancing
└── README.md          # This file
```

## Production URLs

- **Application**: https://sebsrestaurant.diogohack.shop/
- **Grafana**: https://grafana.sebsrestaurant.diogohack.shop/
- **Prometheus**: https://prometheus.sebsrestaurant.diogohack.shop/
