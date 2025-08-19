# TLS Certificate Deployment

This project uses cert-manager with Let's Encrypt for TLS certificates. To avoid committing personal email addresses to the repository, use the deployment script.

## Quick Start

```bash
# Deploy cert-manager ClusterIssuer with your email
./deploy-certs.sh your-email@domain.com

# Example:
./deploy-certs.sh sebastian.fischer@exoscale.com
```

## What it does

1. **Validates email format** - ensures proper email format
2. **Creates temporary config** - replaces placeholder email in cluster-issuer.yaml
3. **Applies ClusterIssuer** - deploys to Kubernetes cluster
4. **Cleans up** - removes temporary file
5. **Shows status** - displays certificate status

## Manual Process (Alternative)

If you prefer manual deployment:

1. Copy the template:
   ```bash
   cp k8s/cert-manager/cluster-issuer.yaml /tmp/cluster-issuer-manual.yaml
   ```

2. Edit the email in `/tmp/cluster-issuer-manual.yaml`:
   ```yaml
   email: your-actual-email@domain.com  # Replace this
   ```

3. Apply manually:
   ```bash
   kubectl apply -f /tmp/cluster-issuer-manual.yaml
   rm /tmp/cluster-issuer-manual.yaml
   ```

## Troubleshooting

- **Email validation fails**: Check email format (must be valid format)
- **File not found**: Run script from project root directory
- **ClusterIssuer not ready**: Check with `kubectl describe clusterissuer letsencrypt-prod`
- **Certificates not issued**: Monitor with `kubectl get certificates --all-namespaces -w`

## Security Note

The `k8s/cert-manager/cluster-issuer.yaml` file contains a placeholder email (`your-email@example.com`) to avoid committing personal information to version control.
