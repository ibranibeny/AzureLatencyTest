#!/usr/bin/env bash
# Create Storage Accounts in all 14 regions for Blob latency measurement (Mode B)

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "=== Creating Storage Accounts (14 regions) ==="

for region in "${REGIONS[@]}"; do
  sa=$(storage_name "$region")
  rg=$(rg_name "$region")

  echo "Creating storage account: $sa in $region..."
  az storage account create \
    --name "$sa" \
    --resource-group "$rg" \
    --location "$region" \
    --sku "$STORAGE_SKU" \
    --kind "$STORAGE_KIND" \
    --access-tier "$STORAGE_ACCESS_TIER" \
    --allow-blob-public-access true \
    --allow-shared-key-access true \
    --min-tls-version TLS1_2 \
    --output none 2>/dev/null || echo "  (already exists or error)"

  # Create container (using login auth; no public-access due to subscription policy)
  echo "  Creating container: $BLOB_CONTAINER..."
  az storage container create \
    --name "$BLOB_CONTAINER" \
    --account-name "$sa" \
    --auth-mode login \
    --output none 2>/dev/null || echo "  (container already exists)"

  echo "  Done: $sa"
done

echo ""
echo "=== All Storage Accounts created ==="
