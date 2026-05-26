#!/usr/bin/env bash
# Validates deployment prerequisites before any Azure operations
# Usage: ./check-prerequisites.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Checking Deployment Prerequisites ==="
all_pass=true

# 1. Check we're running in bash (not PowerShell)
if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "  [FAIL] Not running in bash. Use WSL or a bash shell."
  all_pass=false
else
  echo "  [PASS] Bash ${BASH_VERSION}"
fi

# 2. Check az CLI is installed
if command -v az &>/dev/null; then
  az_version=$(az version --query '"azure-cli"' -o tsv 2>/dev/null)
  echo "  [PASS] Azure CLI v${az_version}"
else
  echo "  [FAIL] Azure CLI (az) not found. Install: https://aka.ms/install-azure-cli"
  all_pass=false
fi

# 3. Check az account is logged in
if az account show &>/dev/null; then
  sub_name=$(az account show --query "name" -o tsv 2>/dev/null)
  sub_id=$(az account show --query "id" -o tsv 2>/dev/null)
  echo "  [PASS] Logged in — Subscription: ${sub_name} (${sub_id})"
else
  echo "  [FAIL] Not logged in. Run: az login"
  all_pass=false
fi

# 4. Check jq is installed
if command -v jq &>/dev/null; then
  echo "  [PASS] jq $(jq --version 2>/dev/null)"
else
  echo "  [FAIL] jq not found. Install: sudo apt install jq"
  all_pass=false
fi

# 5. Check curl is installed
if command -v curl &>/dev/null; then
  echo "  [PASS] curl installed"
else
  echo "  [FAIL] curl not found. Install: sudo apt install curl"
  all_pass=false
fi

# 6. Check config.sh exists
if [[ -f "${SCRIPT_DIR}/config.sh" ]]; then
  echo "  [PASS] config.sh found"
else
  echo "  [FAIL] config.sh not found in ${SCRIPT_DIR}"
  all_pass=false
fi

echo ""
if [[ "$all_pass" == "true" ]]; then
  echo "✅ All prerequisites met. Ready to deploy."
  exit 0
else
  echo "❌ Some prerequisites are missing. Fix the issues above and retry."
  exit 1
fi
