#!/usr/bin/env bash
# Tears down all resource groups with confirmation prompt
# Usage: ./teardown.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

CA_RG="rg-${PREFIX}-frontend"

echo "⚠️  WARNING: This will delete ALL resources for the Azure Latency Test project."
echo ""
echo "Resource groups to delete:"
for region in "${REGIONS[@]}"; do
  echo "  - $(rg_name "$region")"
done
echo "  - $CA_RG (frontend)"
echo ""
read -r -p "Are you sure? Type 'yes' to confirm: " confirm

if [[ "$confirm" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "Deleting resource groups..."

# Delete VM resource groups
for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")
  if az group show --name "$rg" &>/dev/null; then
    echo "  [DELETE] $rg"
    az group delete --name "$rg" --yes --no-wait
  else
    echo "  [SKIP] $rg (not found)"
  fi
done

# Delete frontend resource group
if az group show --name "$CA_RG" &>/dev/null; then
  echo "  [DELETE] $CA_RG"
  az group delete --name "$CA_RG" --yes --no-wait
else
  echo "  [SKIP] $CA_RG (not found)"
fi

echo ""
echo "Deletion initiated (--no-wait). Resources will be removed in the background."
