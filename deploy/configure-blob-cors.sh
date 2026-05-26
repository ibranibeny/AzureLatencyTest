#!/usr/bin/env bash
# Configure CORS on all Storage Accounts to allow browser HTTP HEAD requests

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "=== Configuring CORS for all Storage Accounts ==="

for region in "${REGIONS[@]}"; do
  sa=$(storage_name "$region")

  echo "Configuring CORS: $sa..."
  az storage cors add \
    --account-name "$sa" \
    --services b \
    --methods HEAD GET OPTIONS \
    --origins "*" \
    --allowed-headers "*" \
    --exposed-headers "*" \
    --max-age 3600 \
    --output none 2>/dev/null || echo "  (CORS rule may already exist)"

  echo "  Done: $sa"
done

echo ""
echo "=== CORS configured for all Storage Accounts ==="
