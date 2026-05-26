#!/usr/bin/env bash
# Add NSG rule to allow WebSocket port 8080 on all target VMs

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "=== Adding NSG rule for WebSocket port 8080 ==="

for region in "${REGIONS[@]}"; do
  nsg=$(nsg_name "$region")
  rg=$(rg_name "$region")

  echo "Adding rule to $nsg in $rg..."
  az network nsg rule create \
    --resource-group "$rg" \
    --nsg-name "$nsg" \
    --name "Allow-WebSocket-8080" \
    --priority 120 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --destination-port-ranges 8080 \
    --source-address-prefixes "*" \
    --output none 2>/dev/null || echo "  (rule may already exist)"

  echo "  Done: $nsg"
done

echo ""
echo "=== NSG rules added for WebSocket port 8080 ==="
