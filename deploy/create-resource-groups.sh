#!/usr/bin/env bash
# Creates one resource group per region with idempotency check
# Usage: ./create-resource-groups.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "Creating resource groups for ${#REGIONS[@]} regions..."

for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")
  
  # Check if RG already exists
  if az group show --name "$rg" &>/dev/null; then
    echo "  [EXISTS] $rg ($region)"
  else
    echo "  [CREATE] $rg ($region)"
    az group create --name "$rg" --location "$region" --output none
  fi
done

echo "Done. All resource groups created."
