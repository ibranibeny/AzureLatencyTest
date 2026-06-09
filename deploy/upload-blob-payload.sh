#!/usr/bin/env bash
# Upload latency-test.json to all Storage Accounts

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# Create the tiny test payload
TEMP_FILE=$(mktemp)
echo '{"ok":true}' > "$TEMP_FILE"

echo "=== Uploading $BLOB_FILE to all Storage Accounts ==="

for region in "${REGIONS[@]}"; do
  sa=$(storage_name "$region")

  echo "Uploading to: $sa/$BLOB_CONTAINER/$BLOB_FILE..."
  az storage blob upload \
    --account-name "$sa" \
    --container-name "$BLOB_CONTAINER" \
    --name "$BLOB_FILE" \
    --file "$TEMP_FILE" \
    --content-type "application/json" \
    --overwrite \
    --auth-mode login \
    --output none 2>/dev/null || echo "  (upload failed)"

  echo "  Done: $sa"
done

rm -f "$TEMP_FILE"

echo ""
echo "=== All blobs uploaded ==="
echo "Test URL format: https://<account>.blob.core.windows.net/$BLOB_CONTAINER/$BLOB_FILE"
