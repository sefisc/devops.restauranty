#!/bin/bash

# Import Grafana Dashboards
# Usage: ./import-dashboards.sh [GRAFANA_PASSWORD] [GRAFANA_URL]

GRAFANA_PASSWORD="${1:-}"
GRAFANA_URL="${2:-http://localhost:3000}"

if [ -z "$GRAFANA_PASSWORD" ]; then
    echo "Usage: $0 <GRAFANA_PASSWORD> [GRAFANA_URL]"
    echo "Example: $0 mypassword http://grafana.example.com:3000"
    exit 1
fi

DASHBOARDS_DIR="./dashboards"

echo "Importing dashboards to $GRAFANA_URL..."

for dashboard in "$DASHBOARDS_DIR"/*.json; do
    if [ -f "$dashboard" ]; then
        dashboard_name=$(basename "$dashboard" .json)
        echo "Importing $dashboard_name..."
        
        curl -X POST \
          -H "Content-Type: application/json" \
          -u "admin:${GRAFANA_PASSWORD}" \
          -d "@$dashboard" \
          "$GRAFANA_URL/api/dashboards/db" \
          --silent --show-error
        
        echo "✅ $dashboard_name imported"
    fi
done

echo "🎉 Dashboard import complete!"
