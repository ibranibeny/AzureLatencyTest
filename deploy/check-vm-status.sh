#!/usr/bin/env bash
# Checks VM power state and HTTP health for each region
# Usage: ./check-vm-status.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "Checking VM status for ${#REGIONS[@]} regions..."

all_pass=true

for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")
  vm=$(vm_name "$region")

  # Check power state
  power_state=$(az vm get-instance-view \
    --resource-group "$rg" \
    --name "$vm" \
    --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" \
    --output tsv 2>/dev/null)

  if [[ "$power_state" != "VM running" ]]; then
    echo "  [FAIL] $vm — Power: ${power_state:-NOT FOUND}"
    all_pass=false
    continue
  fi

  # Get public IP
  ip=$(az vm list-ip-addresses \
    --resource-group "$rg" \
    --name "$vm" \
    --query "[0].virtualMachine.network.publicIpAddresses[0].ipAddress" \
    --output tsv 2>/dev/null)

  if [[ -z "$ip" || "$ip" == "None" ]]; then
    echo "  [FAIL] $vm — Running but no public IP"
    all_pass=false
    continue
  fi

  # HTTP probe to /ping
  http_status=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${ip}/ping" 2>/dev/null)

  if [[ "$http_status" == "200" ]]; then
    echo "  [PASS] $vm ($ip) — Running, /ping returns 200"
  else
    echo "  [FAIL] $vm ($ip) — Running, /ping returns ${http_status}"
    all_pass=false
  fi
done

if [[ "$all_pass" == "true" ]]; then
  echo "All VMs healthy."
else
  echo "Some VMs are unhealthy. Review output above."
  exit 1
fi
