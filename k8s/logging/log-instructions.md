# Logging Access Instructions

## Application Logs

### Via kubectl (Kubernetes native)
```bash
# View logs for specific service
kubectl logs -n restauranty deployment/auth -f
kubectl logs -n restauranty deployment/items -f  
kubectl logs -n restauranty deployment/discounts -f
kubectl logs -n restauranty deployment/frontend -f

# View logs for specific pod
kubectl logs -n restauranty <pod-name> -f

# View logs with timestamps
kubectl logs -n restauranty deployment/auth --timestamps=true
```

### Via AWS CloudWatch
1. Go to AWS Console > CloudWatch > Log Groups
2. Look for log groups:
   - `/aws/eks/restauranty-eks/cluster` (cluster logs)
   - EKS automatically creates log streams for containers

## Cluster Logs
- Available in CloudWatch under log group: `/aws/eks/restauranty-eks/cluster`
- Includes API server, scheduler, controller manager logs

## Log Aggregation
- All container logs go to stdout/stderr
- Kubernetes automatically captures and makes them available via kubectl
- EKS integrates with CloudWatch for persistent log storage
