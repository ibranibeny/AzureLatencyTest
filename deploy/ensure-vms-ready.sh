#!/usr/bin/env bash
# Ensures all 14 APAC VMs are running with ws-echo service and NSG rules.
# - If VM is deallocated/stopped → starts it
# - If VM doesn't exist → creates it with cloud-init (ws-echo + nginx)
# - Opens inbound NSG rules (port 80, 8080)
#
# Usage: ./ensure-vms-ready.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

CLOUD_INIT_FILE="${SCRIPT_DIR}/cloud-init.yaml"
VM_SIZE="Standard_B2s"

if [[ ! -f "$CLOUD_INIT_FILE" ]]; then
  echo "ERROR: cloud-init.yaml not found at $CLOUD_INIT_FILE"
  exit 1
fi

echo "=== Ensuring all ${#REGIONS[@]} VMs are running ==="
echo ""

for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")
  vm=$(vm_name "$region")
  nsg=$(nsg_name "$region")
  pip=$(pip_name "$region")

  echo "[$region]"

  # Check if resource group exists
  if ! az group show --name "$rg" &>/dev/null; then
    echo "  Creating resource group $rg..."
    az group create --name "$rg" --location "$region" --output none
  fi

  # Check if VM exists
  vm_status=$(az vm get-instance-view \
    --resource-group "$rg" \
    --name "$vm" \
    --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus | [0]" \
    -o tsv 2>/dev/null || echo "NOT_FOUND")

  case "$vm_status" in
    "VM running")
      echo "  ✓ Already running"
      ;;
    "VM deallocated"|"VM stopped")
      echo "  Starting VM (was $vm_status)..."
      az vm start --resource-group "$rg" --name "$vm" --no-wait --output none
      echo "  ✓ Start initiated"
      ;;
    *)
      echo "  Creating VM ($VM_SIZE)..."

      # Create NSG
      az network nsg create \
        --resource-group "$rg" \
        --name "$nsg" \
        --output none 2>/dev/null || true

      # Create public IP
      az network public-ip create \
        --resource-group "$rg" \
        --name "$pip" \
        --sku Standard \
        --allocation-method Static \
        --output none 2>/dev/null || true

      # Create VM with cloud-init
      az vm create \
        --resource-group "$rg" \
        --name "$vm" \
        --location "$region" \
        --image "$VM_IMAGE" \
        --size "$VM_SIZE" \
        --admin-username "$ADMIN_USER" \
        --generate-ssh-keys \
        --public-ip-address "$pip" \
        --nsg "$nsg" \
        --custom-data "$CLOUD_INIT_FILE" \
        --output none \
        --no-wait

      echo "  ✓ VM creation initiated"
      ;;
  esac

  # --- Ensure NSG rules ---
  echo "  Ensuring NSG inbound rules..."

  # Allow HTTP (port 80)
  az network nsg rule create \
    --resource-group "$rg" \
    --nsg-name "$nsg" \
    --name "AllowHTTP" \
    --priority 100 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --destination-port-ranges 80 \
    --source-address-prefixes "*" \
    --output none 2>/dev/null || true

  # Allow WebSocket (port 8080)
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
    --output none 2>/dev/null || true

  echo "  ✓ NSG rules OK (80, 8080)"
  echo ""
done

echo "=== Waiting for any starting/creating VMs... ==="
echo ""

# Wait for all VMs to be running
for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")
  vm=$(vm_name "$region")

  status=$(az vm get-instance-view \
    --resource-group "$rg" \
    --name "$vm" \
    --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus | [0]" \
    -o tsv 2>/dev/null || echo "PENDING")

  if [[ "$status" != "VM running" ]]; then
    echo "  Waiting for $vm..."
    az vm wait --resource-group "$rg" --name "$vm" --created --timeout 300 2>/dev/null || true
    az vm start --resource-group "$rg" --name "$vm" --output none 2>/dev/null || true
  fi
done

echo ""
echo "=== All VMs ready. Public IPs: ==="
echo ""
printf "%-20s %-16s\n" "REGION" "IP"
printf "%-20s %-16s\n" "------" "--"

for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")
  pip=$(pip_name "$region")

  ip=$(az network public-ip show \
    --resource-group "$rg" \
    --name "$pip" \
    --query "ipAddress" -o tsv 2>/dev/null || echo "N/A")

  printf "%-20s %-16s\n" "$region" "$ip"
done

echo ""
echo "Done. All VMs should be accessible on ports 80 (nginx) and 8080 (ws-echo)."
