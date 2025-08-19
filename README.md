# RestauranTy - Microservices Restaurant Platform

Production-ready microservices architecture with complete DevOps automation for restaurant management.

## 1. Architecture

- **Auth Service** (Port 3001) - Authentication & JWT management
- **Discounts Service** (Port 3002) - Coupons & promotions  
- **Items Service** (Port 3003) - Menu items & orders
- **React Client** (Port 80) - Frontend web interface (3000 in dev mode)
- **MongoDB** (Port 27017) - Database

## 2. Prerequisites

```bash
# Required tools
- Docker & Docker Compose
- Node.js 18+
- kubectl
- Terraform (for AWS deployment)
- HAProxy (for local development)
```

## 3. Local Development

### Single Command Setup:
```bash
# Start all services locally with Docker Compose
docker-compose up --build
```
**Access:** http://localhost:80 (HAProxy)

### Individual Services:
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

## 4. Containerization

Each service has its own Dockerfile:
- `backend/auth/Dockerfile` - Auth service container
- `backend/discounts/Dockerfile` - Discounts service container
- `backend/items/Dockerfile` - Items service container
- `client/Dockerfile` - React frontend container
- `docker-compose.yml` - Multi-container local development

## 5. Production Deployment (Kubernetes)

### Infrastructure (AWS EKS):
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Connect to cluster:
```bash
aws eks update-kubeconfig --region us-west-2 --name restauranty-cluster
```

### Deploy applications:
```bash
# Create namespaces
kubectl apply -f k8s/monitoring/namespace.yaml

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

### Setup monitoring:
```bash
# Install Prometheus stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring

# Apply ServiceMonitors
kubectl apply -f k8s/monitoring/servicemonitors/

# Import Grafana dashboards
./k8s/monitoring/import-dashboards.sh
```

### Setup SSL certificates:
```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml

# Deploy certificates (automated via CI/CD)
# Manual deployment: LETSENCRYPT_EMAIL="your@email.com" envsubst < k8s/cert-manager/letsencrypt-prod.yaml | kubectl apply -f -
```

## 6. CI/CD Pipeline

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
LETSENCRYPT_EMAIL
```

## 7. Security

### Environment Variables:
```bash
cp .env.example .env
```

**Required variables:**
```
MONGO_URI=mongodb://localhost:27017/restauranty
JWT_SECRET=your-jwt-secret
PORT=3001  # (varies per service)
```

### Security Features:
- **JWT Token Authentication** - Secure user sessions
- **Access Control** - Login protection for Grafana and Prometheus
- **Environment Variable Management** - No hardcoded secrets
- **SSL/TLS Certificates** - Automated Let's Encrypt certificates
- **Kubernetes Secrets** - Secure secret storage in cluster

## 8. API Endpoints

**Note:** API endpoints are designed for programmatic access (called by the React frontend), not direct browser access.

| Service | Base URL | Example Routes |
|---------|----------|----------------|
| Auth | `/api/auth` | `/login` (POST), `/register` (POST), `/verify` (GET) |
| Items | `/api/items` | `/` (GET), `/:id` (GET), `/search` (POST) |
| Discounts | `/api/discounts` | `/` (GET), `/:id` (GET), `/apply` (POST) |

### How They Actually Work:

1. **User visits** `https://sebsrestaurant.diogohack.shop/`
2. **React app loads** (requires JavaScript enabled)
3. **React app makes API calls** internally:
   - Login form → `POST /api/auth/login`
   - Menu loading → `GET /api/items`
   - Coupon application → `POST /api/discounts/apply`


## 9. Monitoring & Observability

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
# Application logs
kubectl logs -f deployment/auth -n restauranty
kubectl logs -f deployment/discounts -n restauranty  
kubectl logs -f deployment/items -n restauranty

# Infrastructure logs (AWS CloudWatch)
# Go to AWS Console > CloudWatch > Log Groups > /aws/eks/restauranty-cluster/
```
```

## 10. Troubleshooting

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

## 11. Development Workflow

1. **Local Development**: Use `docker-compose up` or individual `npm start`
2. **Testing**: Run tests with `npm test` in each service directory
3. **Build**: `docker build` or automated via CI/CD
4. **Deploy**: Push to `main` branch triggers auto-deployment
5. **Monitor**: Check Grafana dashboards and Prometheus metrics

## 12. File Structure

```
devops.restauranty/
├── backend/              # Node.js microservices
│   ├── auth/            # Authentication service
│   ├── discounts/       # Discounts service  
│   └── items/           # Items service
├── client/              # React frontend
├── k8s/                 # Kubernetes manifests
│   ├── auth/           # Auth deployment
│   ├── discounts/      # Discounts deployment
│   ├── items/          # Items deployment
│   ├── frontend/       # Frontend deployment
│   ├── ingress/        # Ingress controller
│   ├── monitoring/     # Prometheus/Grafana setup
│   ├── cert-manager/   # SSL certificates
│   └── logging/        # ELK stack
├── terraform/          # AWS EKS infrastructure
├── ansible/            # Ansible playbooks
├── .github/workflows/  # CI/CD pipeline
├── docker-compose.yml  # Local development
├── haproxy.cfg        # Local load balancing
└── README.md          # This file
```

## 13. Production URLs

- **Application**: https://sebsrestaurant.diogohack.shop/
- **Grafana**: https://grafana.sebsrestaurant.diogohack.shop/
- **Prometheus**: https://prometheus.sebsrestaurant.diogohack.shop/
