#!/usr/bin/env bash
# Creates Container Apps environment and deploys the frontend Angular app
# Usage: ./create-container-app.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Container App configuration
CA_RG="rg-${PREFIX}-frontend"
CA_LOCATION="australiaeast"
CA_ENV="cae-${PREFIX}"
CA_NAME="ca-${PREFIX}-frontend"
ACR_NAME="${PREFIX}acr2025"

echo "=== Deploying Frontend Container App ==="

# Create resource group for frontend
if az group show --name "$CA_RG" &>/dev/null; then
  echo "[EXISTS] Resource group: $CA_RG"
else
  echo "[CREATE] Resource group: $CA_RG"
  az group create --name "$CA_RG" --location "$CA_LOCATION" --output none
fi

# Create ACR
echo "[CREATE] Container Registry: $ACR_NAME"
az acr create \
  --resource-group "$CA_RG" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled true \
  --output none

# Build and push image
echo "[BUILD] Building container image..."
az acr build \
  --registry "$ACR_NAME" \
  --image "${CA_NAME}:latest" \
  --file "${SCRIPT_DIR}/../ui/Dockerfile" \
  "${SCRIPT_DIR}/../ui"

# Get ACR credentials
ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer --output tsv)
ACR_PASSWORD=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" --output tsv)

# Create Container Apps environment
if az containerapp env show --name "$CA_ENV" --resource-group "$CA_RG" &>/dev/null; then
  echo "[EXISTS] Container Apps environment: $CA_ENV"
else
  echo "[CREATE] Container Apps environment: $CA_ENV"
  az containerapp env create \
    --name "$CA_ENV" \
    --resource-group "$CA_RG" \
    --location "$CA_LOCATION" \
    --output none
fi

# Deploy Container App
echo "[DEPLOY] Container App: $CA_NAME"
az containerapp create \
  --name "$CA_NAME" \
  --resource-group "$CA_RG" \
  --environment "$CA_ENV" \
  --image "${ACR_SERVER}/${CA_NAME}:latest" \
  --registry-server "$ACR_SERVER" \
  --registry-username "$ACR_NAME" \
  --registry-password "$ACR_PASSWORD" \
  --target-port 80 \
  --ingress external \
  --transport http \
  --output none

# Allow HTTP access (required for mixed-content: browser pings VMs over HTTP)
echo "[INGRESS] Allowing HTTP access for latency probes..."
az containerapp ingress update \
  --name "$CA_NAME" \
  --resource-group "$CA_RG" \
  --allow-insecure true \
  --output none

# Get the FQDN
FQDN=$(az containerapp show \
  --name "$CA_NAME" \
  --resource-group "$CA_RG" \
  --query "properties.configuration.ingress.fqdn" \
  --output tsv)

echo ""
echo "=== Deployment Complete ==="
echo "Frontend URL: http://${FQDN}"
echo "Note: Use HTTP (not HTTPS) to allow browser latency probes to HTTP VM endpoints"
echo "ACR: ${ACR_SERVER}"
echo "Resource Group: ${CA_RG}"
