#!/usr/bin/env bash
# Configure CORS on all Storage Accounts to allow browser HTTP HEAD requests
# Uses ARM REST API because `az storage cors add` does not support --auth-mode login

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

SUB=$(az account show --query id -o tsv)

echo "=== Configuring CORS for all Storage Accounts ==="

for region in "${REGIONS[@]}"; do
  sa=$(storage_name "$region")
  rg=$(rg_name "$region")

  echo "Configuring CORS: $sa..."
  az rest --method PUT \
    --url "https://management.azure.com/subscriptions/${SUB}/resourceGroups/${rg}/providers/Microsoft.Storage/storageAccounts/${sa}/blobServices/default?api-version=2023-05-01" \
    --body '{"properties":{"cors":{"corsRules":[{"allowedOrigins":["*"],"allowedMethods":["HEAD","GET","OPTIONS"],"allowedHeaders":["*"],"exposedHeaders":["*"],"maxAgeInSeconds":3600}]}}}' \
    --output none 2>/dev/null || echo "  (CORS rule may already exist)"

  echo "  Done: $sa"
done

echo ""
echo "=== CORS configured for all Storage Accounts ==="
