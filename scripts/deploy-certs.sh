#!/bin/bash

# Deployment script for cert-manager with email injection
# Usage: ./deploy-certs.sh your-email@domain.com

set -e

if [ -z "$1" ]; then
    echo "❌ Usage: $0 <email>"
    echo "📝 Example: $0 sebastian.fischer@exoscale.com"
    exit 1
fi

EMAIL="$1"
TEMP_FILE="/tmp/cluster-issuer-$(date +%s).yaml"

echo "🔧 Deploying cert-manager ClusterIssuer with email: $EMAIL"

# Validate email format
if [[ ! "$EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "❌ Invalid email format: $EMAIL"
    exit 1
fi

# Check if cluster-issuer.yaml exists
if [ ! -f "k8s/cert-manager/cluster-issuer.yaml" ]; then
    echo "❌ Error: k8s/cert-manager/cluster-issuer.yaml not found"
    echo "📁 Make sure you run this script from the project root directory"
    exit 1
fi

# Create temporary file with email replaced
sed "s/your-email@example.com/$EMAIL/g" k8s/cert-manager/cluster-issuer.yaml > "$TEMP_FILE"

echo "📝 Created temporary config file: $TEMP_FILE"
echo "🚀 Applying ClusterIssuer..."

# Apply the configuration
kubectl apply -f "$TEMP_FILE"

if [ $? -eq 0 ]; then
    echo "✅ ClusterIssuer deployed successfully with email: $EMAIL"
    echo "🧹 Cleaning up temporary file..."
    rm "$TEMP_FILE"
    
    echo ""
    echo "⏳ Waiting for ClusterIssuer to be ready..."
    kubectl wait --for=condition=Ready clusterissuer/letsencrypt-prod --timeout=60s || true
    
    echo ""
    echo "📋 Certificate status:"
    kubectl get certificates --all-namespaces
    
    echo ""
    echo "📋 Next steps:"
    echo "   - Check ClusterIssuer status: kubectl describe clusterissuer letsencrypt-prod"
    echo "   - Monitor certificate issuance: kubectl get certificates --all-namespaces -w"
    echo "   - If certificates show Ready: True, your HTTPS is working!"
    echo ""
    echo "✨ Done!"
else
    echo "❌ Deployment failed"
    echo "🔍 Temporary file saved for debugging: $TEMP_FILE"
    exit 1
fi
