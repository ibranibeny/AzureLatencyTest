#!/usr/bin/env bash
# Check Blob HEAD reachability for all Storage Accounts

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

echo "=== Checking Blob HEAD Reachability ==="
echo ""

PASS=0
FAIL=0

for region in "${REGIONS[@]}"; do
  sa=$(storage_name "$region")
  url="https://${sa}.blob.core.windows.net/${BLOB_CONTAINER}/${BLOB_FILE}"

  http_code=$(curl -s -o /dev/null -w "%{http_code}" --head --max-time 5 "$url" 2>/dev/null || echo "000")

  if [[ "$http_code" == "200" ]]; then
    echo "  ✓ $region ($sa): HTTP $http_code"
    ((PASS++))
  else
    echo "  ✗ $region ($sa): HTTP $http_code"
    ((FAIL++))
  fi
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed (out of ${#REGIONS[@]} regions) ==="

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
