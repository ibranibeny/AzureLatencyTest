#!/usr/bin/env bash
# Deploys the frontend + backend to a VM in southeastasia
# Usage: ./create-frontend-vm.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

REGION="southeastasia"
RG="rg-latency-frontend-vm"
VM_NAME="vm-latency-frontend"
VM_SKU="Standard_B1s"
VM_IMAGE="Canonical:ubuntu-24_04-lts:server:latest"
ADMIN_USER="azureuser"
NSG_NAME="nsg-latency-frontend"

echo "=== Deploying Frontend VM in ${REGION} ==="

# 1. Create resource group
echo "[1/7] Resource group..."
az group create --name "$RG" --location "$REGION" --output none 2>/dev/null || true

# 2. Create NSG with HTTP rule
echo "[2/7] Network Security Group..."
az network nsg create --resource-group "$RG" --name "$NSG_NAME" --location "$REGION" --output none 2>/dev/null || true
az network nsg rule create \
  --resource-group "$RG" \
  --nsg-name "$NSG_NAME" \
  --name AllowHTTP \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 80 \
  --source-address-prefixes '*' \
  --output none 2>/dev/null || true

# 3. Create the VM with cloud-init
echo "[3/7] Creating VM..."
VM_EXISTS=$(az vm show --resource-group "$RG" --name "$VM_NAME" --query "name" --output tsv 2>/dev/null || true)
if [[ -n "$VM_EXISTS" ]]; then
  echo "  [EXISTS] ${VM_NAME} — skipping creation"
else
  az vm create \
    --resource-group "$RG" \
    --name "$VM_NAME" \
    --location "$REGION" \
    --size "$VM_SKU" \
    --image "$VM_IMAGE" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --nsg "$NSG_NAME" \
    --public-ip-sku Standard \
    --custom-data "${SCRIPT_DIR}/cloud-init-frontend.yaml" \
    --output none
fi

# 4. Get public IP
echo "[4/7] Getting public IP..."
PUBLIC_IP=$(az vm list-ip-addresses \
  --resource-group "$RG" \
  --name "$VM_NAME" \
  --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" \
  --output tsv)
echo "  Public IP: ${PUBLIC_IP}"

# 5. Build Angular app
echo "[5/7] Building Angular app..."
cd "${PROJECT_ROOT}/ui"
npm ci --silent
npm run build

# 6. Upload Angular build to VM
echo "[6/7] Uploading frontend files..."
DIST_DIR="${PROJECT_ROOT}/ui/dist/ui/browser"

# Wait for VM to be ready
echo "  Waiting for VM to be reachable..."
for i in $(seq 1 30); do
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${ADMIN_USER}@${PUBLIC_IP}" "echo ready" 2>/dev/null; then
    break
  fi
  sleep 10
done

# Upload dist files
ssh -o StrictHostKeyChecking=no "${ADMIN_USER}@${PUBLIC_IP}" "sudo mkdir -p /var/www/frontend"
tar -czf /tmp/frontend-dist.tar.gz -C "$DIST_DIR" .
scp -o StrictHostKeyChecking=no /tmp/frontend-dist.tar.gz "${ADMIN_USER}@${PUBLIC_IP}:/tmp/"
ssh -o StrictHostKeyChecking=no "${ADMIN_USER}@${PUBLIC_IP}" \
  "sudo tar -xzf /tmp/frontend-dist.tar.gz -C /var/www/frontend && sudo chown -R www-data:www-data /var/www/frontend"

# 7. Wait for cloud-init to complete and verify
echo "[7/7] Waiting for cloud-init..."
ssh -o StrictHostKeyChecking=no "${ADMIN_USER}@${PUBLIC_IP}" \
  "sudo cloud-init status --wait >/dev/null 2>&1; sudo systemctl restart nginx; sudo systemctl restart latency-backend"

echo ""
echo "=== Frontend VM deployed ==="
echo "  URL: http://${PUBLIC_IP}"
echo "  VM:  ${VM_NAME} (${REGION})"
echo "  RG:  ${RG}"
echo ""
echo "Test: curl http://${PUBLIC_IP}/api/health"
