#!/usr/bin/env bash
# Deploy frontend to the frontend VM via scp
# Usage: ./deploy-frontend.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

FRONTEND_RG="rg-${PREFIX}-frontend"
FRONTEND_VM="vm-${PREFIX}-frontend"
UI_DIR="${SCRIPT_DIR}/../ui"

echo "=== Deploy Frontend ==="

# Get frontend VM IP
echo "Getting frontend VM IP..."
FRONTEND_IP=$(az vm show \
  --resource-group "$FRONTEND_RG" \
  --name "$FRONTEND_VM" \
  --show-details \
  --query publicIps \
  --output tsv)

if [[ -z "$FRONTEND_IP" ]]; then
  echo "ERROR: Could not determine frontend VM IP"
  exit 1
fi
echo "Frontend IP: $FRONTEND_IP"

# Build Angular app
echo "Building Angular app..."
cd "$UI_DIR"
npm ci
npx ng build --configuration=production

# Upload dist to frontend VM
echo "Uploading to frontend VM..."
DIST_DIR="${UI_DIR}/dist/ui/browser"
if [[ ! -d "$DIST_DIR" ]]; then
  # Try alternate Angular output path
  DIST_DIR="${UI_DIR}/dist/ui"
fi

scp -o StrictHostKeyChecking=no -r "$DIST_DIR"/* "${ADMIN_USER}@${FRONTEND_IP}:/var/www/frontend/"

echo ""
echo "=== Frontend deployed ==="
echo "URL: http://${FRONTEND_IP}"
