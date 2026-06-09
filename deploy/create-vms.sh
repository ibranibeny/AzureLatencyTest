#!/usr/bin/env bash
# Deploys a B1s Ubuntu VM per region with cloud-init, public IP, and NSG
# Usage: ./create-vms.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

CLOUD_INIT_FILE="${SCRIPT_DIR}/cloud-init.yaml"

if [[ ! -f "$CLOUD_INIT_FILE" ]]; then
  echo "ERROR: cloud-init.yaml not found at $CLOUD_INIT_FILE"
  exit 1
fi

echo "Deploying VMs to ${#REGIONS[@]} regions (parallel)..."

deploy_vm() {
  local region="$1"
  local rg vm nsg pip
  rg=$(rg_name "$region")
  vm=$(vm_name "$region")
  nsg=$(nsg_name "$region")
  pip=$(pip_name "$region")

  # Check if VM already exists
  if az vm show --resource-group "$rg" --name "$vm" &>/dev/null; then
    echo "  [EXISTS] $vm in $rg"
    return 0
  fi

  echo "  [CREATE] $vm in $region..."

  # Create NSG with HTTP and SSH rules
  az network nsg create \
    --resource-group "$rg" \
    --name "$nsg" \
    --output none

  az network nsg rule create \
    --resource-group "$rg" \
    --nsg-name "$nsg" \
    --name "AllowHTTP" \
    --priority 100 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --destination-port-ranges 80 \
    --output none

  az network nsg rule create \
    --resource-group "$rg" \
    --nsg-name "$nsg" \
    --name "AllowSSH" \
    --priority 110 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --destination-port-ranges 22 \
    --output none

  az network nsg rule create \
    --resource-group "$rg" \
    --nsg-name "$nsg" \
    --name "AllowWebSocket" \
    --priority 120 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --destination-port-ranges 8080 \
    --output none

  # Create public IP
  az network public-ip create \
    --resource-group "$rg" \
    --name "$pip" \
    --sku Standard \
    --allocation-method Static \
    --output none

  # Create VM with cloud-init
  az vm create \
    --resource-group "$rg" \
    --name "$vm" \
    --image "$VM_IMAGE" \
    --size "$VM_SKU" \
    --admin-username "$ADMIN_USER" \
    --generate-ssh-keys \
    --public-ip-address "$pip" \
    --nsg "$nsg" \
    --custom-data "$CLOUD_INIT_FILE" \
    --output none \
    --no-wait

  echo "  [DONE] $vm queued"
}

export -f deploy_vm rg_name vm_name nsg_name pip_name
export VM_IMAGE VM_SKU ADMIN_USER CLOUD_INIT_FILE PREFIX

# Run up to 5 parallel deployments
for region in "${REGIONS[@]}"; do
  deploy_vm "$region" &
  # Limit to 5 concurrent jobs
  if (( $(jobs -r | wc -l) >= 5 )); then
    wait -n
  fi
done
wait

echo "Waiting for VMs to be provisioned..."
for region in "${REGIONS[@]}"; do
  local_rg=$(rg_name "$region")
  local_vm=$(vm_name "$region")
  az vm wait -g "$local_rg" -n "$local_vm" --created --timeout 600 2>/dev/null || true
done

echo "Adding subnet NSG rules for HTTP and WebSocket..."
for region in "${REGIONS[@]}"; do
  local_rg=$(rg_name "$region")
  # Azure truncates auto-created subnet NSG names to 80 chars; discover the actual name
  subnet_nsg=$(az network nsg list -g "$local_rg" --query "[?contains(name,'Subnet')].name" -o tsv 2>/dev/null)
  if [[ -n "$subnet_nsg" ]]; then
    az network nsg rule create -g "$local_rg" --nsg-name "$subnet_nsg" \
      --name AllowHTTP --priority 100 --direction Inbound --access Allow \
      --protocol Tcp --destination-port-ranges 80 --source-address-prefixes '*' \
      --output none 2>/dev/null || true
    az network nsg rule create -g "$local_rg" --nsg-name "$subnet_nsg" \
      --name AllowWebSocket --priority 110 --direction Inbound --access Allow \
      --protocol Tcp --destination-port-ranges 8080 --source-address-prefixes '*' \
      --output none 2>/dev/null || true
    echo "  [NSG] $region: rules added"
  fi
done

echo "Done. All VMs provisioned with NSG rules."
echo "Run ./check-vm-status.sh to verify when ready."
