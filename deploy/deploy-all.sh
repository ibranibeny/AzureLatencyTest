#!/usr/bin/env bash
# Deploy All: Full infrastructure + frontend deployment in one command
# Usage: ./deploy-all.sh
#
# This script orchestrates the complete deployment pipeline:
# 1. Validates prerequisites (WSL, az CLI, login)
# 2. Creates resource groups
# 3. Deploys VMs with cloud-init
# 4. Waits for all VMs to be running
# 5. Generates regions-db.json with live IPs
# 6. Builds and deploys frontend to Container Apps
# 7. Runs health checks
# 8. Outputs frontend URL

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "╔══════════════════════════════════════════════════╗"
echo "║   Azure Latency Test — Full Deployment          ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ─── Stage 1: Prerequisites ────────────────────────────────────────
echo "━━━ Stage 1/9: Checking prerequisites..."
bash "${SCRIPT_DIR}/check-prerequisites.sh"
echo ""

# ─── Stage 2: Resource Groups ──────────────────────────────────────
echo "━━━ Stage 2/9: Creating resource groups..."
bash "${SCRIPT_DIR}/create-resource-groups.sh"
echo ""

# ─── Stage 3: Deploy VMs ──────────────────────────────────────────
echo "━━━ Stage 3/9: Deploying VMs (${#REGIONS[@]} regions)..."
bash "${SCRIPT_DIR}/create-vms.sh"
echo ""

# ─── Stage 4: Storage Accounts ────────────────────────────────────
echo "━━━ Stage 4/9: Creating Storage Accounts..."
bash "${SCRIPT_DIR}/create-storage-accounts.sh"
echo ""

# ─── Stage 5: Configure Blob CORS & Upload ────────────────────────
echo "━━━ Stage 5/9: Configuring CORS and uploading blob payload..."
bash "${SCRIPT_DIR}/configure-blob-cors.sh"
bash "${SCRIPT_DIR}/upload-blob-payload.sh"
echo ""

# ─── Stage 6: NSG Rules ───────────────────────────────────────────
echo "━━━ Stage 6/9: Adding WebSocket NSG rules..."
bash "${SCRIPT_DIR}/add-ws-nsg-rule.sh"
echo ""

# ─── Stage 7: Wait for VMs ────────────────────────────────────────
echo "━━━ Stage 7/9: Waiting for VMs to be ready..."
MAX_WAIT=600  # 10 minutes max
INTERVAL=30
elapsed=0
all_running=false

while [[ $elapsed -lt $MAX_WAIT ]]; do
  running_count=0
  for region in "${REGIONS[@]}"; do
    rg=$(rg_name "$region")
    vm=$(vm_name "$region")
    state=$(az vm get-instance-view \
      --resource-group "$rg" \
      --name "$vm" \
      --query "instanceView.statuses[?starts_with(code,'PowerState/')].displayStatus" \
      --output tsv 2>/dev/null || echo "Unknown")
    if [[ "$state" == "VM running" ]]; then
      running_count=$((running_count + 1))
    fi
  done

  echo "  ${running_count}/${#REGIONS[@]} VMs running (${elapsed}s elapsed)"

  if [[ $running_count -eq ${#REGIONS[@]} ]]; then
    all_running=true
    break
  fi

  sleep $INTERVAL
  ((elapsed += INTERVAL))
done

if [[ "$all_running" != "true" ]]; then
  echo "  [WARN] Not all VMs are running after ${MAX_WAIT}s. Continuing anyway..."
fi
echo ""

# ─── Stage 8: Generate regions-db.json ────────────────────────────
echo "━━━ Stage 8/9: Generating regions-db.json..."
bash "${SCRIPT_DIR}/generate-regions-db.sh"
echo ""

# ─── Stage 9: Deploy Frontend VM ──────────────────────────────────
echo "━━━ Stage 9/9: Building and deploying frontend VM..."
bash "${SCRIPT_DIR}/create-frontend-vm.sh"
echo ""

# ─── Health Checks ────────────────────────────────────────────────
echo "━━━ Running health checks..."
echo ""
echo "--- NSG Validation ---"
bash "${SCRIPT_DIR}/check-nsg.sh" || true
echo ""
echo "--- VM Status ---"
bash "${SCRIPT_DIR}/check-vm-status.sh" || true
echo ""
echo "--- Blob Status ---"
bash "${SCRIPT_DIR}/check-blob-status.sh" || true
echo ""
echo "--- Resource Groups ---"
bash "${SCRIPT_DIR}/check-resource-groups.sh" || true
echo ""

# ─── Done ──────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════╗"
echo "║   ✅ Deployment Complete                        ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Open the frontend URL printed above"
echo "  2. Select regions and test latency"
echo "  3. To destroy: ./teardown.sh"
