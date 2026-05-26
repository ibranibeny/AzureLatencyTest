#!/usr/bin/env bash
# Queries VM public IPs and generates ui/src/assets/regions-db.json
# Usage: ./generate-regions-db.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

OUTPUT_FILE="${SCRIPT_DIR}/../ui/src/assets/regions-db.json"

echo "Querying public IPs for ${#REGIONS[@]} VMs..."

json="["
first=true

for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")
  vm=$(vm_name "$region")

  # Get public IP address
  ip=$(az vm list-ip-addresses \
    --resource-group "$rg" \
    --name "$vm" \
    --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" \
    --output tsv 2>/dev/null)

  if [[ -z "$ip" || "$ip" == "None" ]]; then
    echo "  [WARN] No IP found for $vm in $rg"
    ip="0.0.0.0"
  else
    echo "  [OK] $vm → $ip"
  fi

  display_name="${REGION_DISPLAY_NAMES[$region]}"
  city="${REGION_CITIES[$region]}"
  group="${REGION_GROUPS[$region]}"
  ping_url="http://${ip}/ping"
  ws_url="ws://${ip}:8080"
  sa_name=$(storage_name "$region")

  if [[ "$first" == "true" ]]; then
    first=false
  else
    json+=","
  fi

  json+="
  {
    \"id\": \"${region}\",
    \"displayName\": \"${display_name}\",
    \"city\": \"${city}\",
    \"group\": \"${group}\",
    \"ip\": \"${ip}\",
    \"pingUrl\": \"${ping_url}\",
    \"wsUrl\": \"${ws_url}\",
    \"storageAccountName\": \"${sa_name}\"
  }"
done

json+="
]"

echo "$json" > "$OUTPUT_FILE"
echo "Written to $OUTPUT_FILE"
