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

echo "Deploying VMs to ${#REGIONS[@]} regions..."

for region in "${REGIONS[@]}"; do
  rg=$(rg_name "$region")
  vm=$(vm_name "$region")
  nsg=$(nsg_name "$region")
  pip=$(pip_name "$region")

  # Check if VM already exists
  if az vm show --resource-group "$rg" --name "$vm" &>/dev/null; then
    echo "  [EXISTS] $vm in $rg"
    continue
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
done

echo "Done. VMs are being provisioned (--no-wait)."
echo "Run ./check-vm-status.sh to verify when ready."
