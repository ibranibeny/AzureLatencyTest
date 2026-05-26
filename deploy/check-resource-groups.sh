#!/usr/bin/env bash
# Verifies all required resource groups exist and are provisioned
# Usage: ./check-resource-groups.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

CA_RG="rg-${PREFIX}-frontend"

echo "Checking resource groups for ${#REGIONS[@]} VM regions + 1 frontend..."

all_pass=true

# Check VM resource groups
for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")

  if az group show --name "$rg" &>/dev/null; then
    state=$(az group show --name "$rg" --query "properties.provisioningState" -o tsv 2>/dev/null)
    if [[ "$state" == "Succeeded" ]]; then
      echo "  [PASS] $rg ($region) — $state"
    else
      echo "  [WARN] $rg ($region) — $state"
      all_pass=false
    fi
  else
    echo "  [FAIL] $rg ($region) — NOT FOUND"
    all_pass=false
  fi
done

# Check frontend resource group
if az group show --name "$CA_RG" &>/dev/null; then
  state=$(az group show --name "$CA_RG" --query "properties.provisioningState" -o tsv 2>/dev/null)
  if [[ "$state" == "Succeeded" ]]; then
    echo "  [PASS] $CA_RG (frontend) — $state"
  else
    echo "  [WARN] $CA_RG (frontend) — $state"
    all_pass=false
  fi
else
  echo "  [FAIL] $CA_RG (frontend) — NOT FOUND"
  all_pass=false
fi

echo ""
if [[ "$all_pass" == "true" ]]; then
  echo "All resource groups available and provisioned."
else
  echo "Some resource groups are missing or not fully provisioned."
  exit 1
fi
