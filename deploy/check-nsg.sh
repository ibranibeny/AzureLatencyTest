#!/usr/bin/env bash
# Validates NSG rules for each region (HTTP port 80 + SSH port 22)
# Usage: ./check-nsg.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "Checking NSG rules for ${#REGIONS[@]} regions..."

all_pass=true

for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")
  nsg=$(nsg_name "$region")

  # Check if NSG exists
  if ! az network nsg show --resource-group "$rg" --name "$nsg" &>/dev/null; then
    echo "  [FAIL] $nsg not found in $rg"
    all_pass=false
    continue
  fi

  # Check HTTP rule
  http_rule=$(az network nsg rule list \
    --resource-group "$rg" \
    --nsg-name "$nsg" \
    --query "[?destinationPortRange=='80' && access=='Allow' && direction=='Inbound'].name" \
    --output tsv 2>/dev/null)

  # Check SSH rule
  ssh_rule=$(az network nsg rule list \
    --resource-group "$rg" \
    --nsg-name "$nsg" \
    --query "[?destinationPortRange=='22' && access=='Allow' && direction=='Inbound'].name" \
    --output tsv 2>/dev/null)

  if [[ -n "$http_rule" && -n "$ssh_rule" ]]; then
    echo "  [PASS] $nsg — HTTP: $http_rule, SSH: $ssh_rule"
  else
    echo "  [FAIL] $nsg — HTTP: ${http_rule:-MISSING}, SSH: ${ssh_rule:-MISSING}"
    all_pass=false
  fi
done

if [[ "$all_pass" == "true" ]]; then
  echo "All NSG checks passed."
else
  echo "Some NSG checks failed. Review output above."
  exit 1
fi
