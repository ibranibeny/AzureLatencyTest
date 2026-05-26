#!/usr/bin/env bash
# Shared configuration for Azure Latency Test deployment scripts

set -euo pipefail

# Resource naming prefix
PREFIX="latency"

# VM SKU
VM_SKU="Standard_B2s"
VM_IMAGE="Canonical:ubuntu-24_04-lts:server:latest"
ADMIN_USER="azureuser"

# All 14 regions (10 Asia + 4 AU/NZ) — westindia excluded (Standard_B1s unavailable)
REGIONS=(
  "australiacentral"
  "australiaeast"
  "australiasoutheast"
  "newzealandnorth"
  "eastasia"
  "southeastasia"
  "japaneast"
  "japanwest"
  "koreacentral"
  "koreasouth"
  "centralindia"
  "southindia"
  "indonesiacentral"
  "malaysiawest"
)

# Display names for regions
declare -A REGION_DISPLAY_NAMES=(
  ["australiacentral"]="Australia Central"
  ["australiaeast"]="Australia East"
  ["australiasoutheast"]="Australia Southeast"
  ["newzealandnorth"]="New Zealand North"
  ["eastasia"]="East Asia"
  ["southeastasia"]="Southeast Asia"
  ["japaneast"]="Japan East"
  ["japanwest"]="Japan West"
  ["koreacentral"]="Korea Central"
  ["koreasouth"]="Korea South"
  ["centralindia"]="Central India"
  ["southindia"]="South India"
  ["indonesiacentral"]="Indonesia Central"
  ["malaysiawest"]="Malaysia West"
)

# City names for regions
declare -A REGION_CITIES=(
  ["australiacentral"]="Canberra"
  ["australiaeast"]="Sydney"
  ["australiasoutheast"]="Melbourne"
  ["newzealandnorth"]="Auckland"
  ["eastasia"]="Hong Kong"
  ["southeastasia"]="Singapore"
  ["japaneast"]="Tokyo"
  ["japanwest"]="Osaka"
  ["koreacentral"]="Seoul"
  ["koreasouth"]="Busan"
  ["centralindia"]="Pune"
  ["southindia"]="Chennai"
  ["indonesiacentral"]="Jakarta"
  ["malaysiawest"]="Kuala Lumpur"
)

# Region groups
declare -A REGION_GROUPS=(
  ["australiacentral"]="australia"
  ["australiaeast"]="australia"
  ["australiasoutheast"]="australia"
  ["newzealandnorth"]="australia"
  ["eastasia"]="asia"
  ["southeastasia"]="asia"
  ["japaneast"]="asia"
  ["japanwest"]="asia"
  ["koreacentral"]="asia"
  ["koreasouth"]="asia"
  ["centralindia"]="asia"
  ["southindia"]="asia"
  ["indonesiacentral"]="asia"
  ["malaysiawest"]="asia"
)

# Helper: get resource group name for a region
rg_name() {
  echo "rg-${PREFIX}-${1}"
}

# Helper: get VM name for a region
vm_name() {
  echo "vm-${PREFIX}-${1}"
}

# Helper: get NSG name for a region
nsg_name() {
  echo "nsg-${PREFIX}-${1}"
}

# Helper: get storage account name for a region (max 24 chars for Azure)
storage_name() {
  local name="${PREFIX}${1}"
  echo "${name:0:24}"
}

# Storage Account configuration
STORAGE_SKU="Standard_LRS"
STORAGE_KIND="StorageV2"
STORAGE_ACCESS_TIER="Hot"
BLOB_CONTAINER="public"
BLOB_FILE="latency-test.json"

# Helper: get public IP name for a region
pip_name() {
  echo "pip-${PREFIX}-${1}"
}
