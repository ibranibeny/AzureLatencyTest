---
layout: default
title: 8.1 Deploy the Latency Test
parent: 8. Azure Visualizer Demo
nav_order: 1
---

# Deploy the Azure Latency Test
{: .no_toc }

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Clone the Repository

```bash
git clone https://github.com/ibranibeny/AzureLatencyTest.git
cd AzureLatencyTest
```

## Login to Azure

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_NAME"
```

## Deploy All Infrastructure

The fastest path is the all-in-one script:

```bash
cd deploy
bash deploy-all.sh
```

This creates **15 resource groups** across 14 APAC regions:

| Resource Group | Region | Contents |
|---|---|---|
| `rg-latency-frontend-vm` | southeastasia | Frontend VM (nginx + Express + Angular) |
| `rg-latency-australiacentral` | australiacentral | Echo VM + Storage Account |
| `rg-latency-australiaeast` | australiaeast | Echo VM + Storage Account |
| `rg-latency-australiasoutheast` | australiasoutheast | Echo VM + Storage Account |
| `rg-latency-newzealandnorth` | newzealandnorth | Echo VM + Storage Account |
| `rg-latency-eastasia` | eastasia | Echo VM + Storage Account |
| `rg-latency-southeastasia` | southeastasia | Echo VM + Storage Account |
| `rg-latency-indonesiacentral` | indonesiacentral | Echo VM + Storage Account |
| `rg-latency-malaysiawest` | malaysiawest | Echo VM + Storage Account |
| `rg-latency-japaneast` | japaneast | Echo VM + Storage Account |
| `rg-latency-japanwest` | japanwest | Echo VM + Storage Account |
| `rg-latency-koreacentral` | koreacentral | Echo VM + Storage Account |
| `rg-latency-koreasouth` | koreasouth | Echo VM + Storage Account |
| `rg-latency-centralindia` | centralindia | Echo VM + Storage Account |
| `rg-latency-southindia` | southindia | Echo VM + Storage Account |

## Or Deploy Step-by-Step

```bash
# 1. Create all resource groups
bash create-resource-groups.sh

# 2. Deploy VMs (idempotent - safe to re-run)
bash ensure-vms-ready.sh

# 3. Deploy storage accounts with blob payloads
bash create-storage-accounts.sh
bash upload-blob-payload.sh
bash configure-blob-cors.sh
```

## Verify Deployment

```bash
bash check-vm-status.sh
bash check-blob-status.sh
```

Expected output — all 14 VMs running:

```
✅ australiacentral    : VM running (20.227.139.227)
✅ australiaeast       : VM running (20.28.218.20)
✅ australiasoutheast  : VM running (23.101.225.112)
✅ newzealandnorth     : VM running (172.196.48.116)
✅ eastasia            : VM running (104.208.81.168)
✅ southeastasia       : VM running (4.194.141.31)
✅ indonesiacentral    : VM running (48.193.42.197)
✅ malaysiawest        : VM running (172.197.170.58)
✅ japaneast           : VM running (20.222.52.209)
✅ japanwest           : VM running (20.78.154.16)
✅ koreacentral        : VM running (4.230.6.218)
✅ koreasouth          : VM running (20.214.10.172)
✅ centralindia        : VM running (4.247.157.36)
✅ southindia          : VM running (52.140.56.237)
```

## What Gets Deployed Per Resource Group

Each regional resource group (`rg-latency-{region}`) contains:

```
├── vm-latency-{region}              (Standard_B2s, Ubuntu 24.04)
├── vm-latency-{region}VMNic         (Network Interface)
├── vm-latency-{region}PublicIP      (Public IP Address)
├── vm-latency-{region}VNET          (Virtual Network)
├── vm-latency-{region}Subnet        (Subnet)
├── nsg-latency-{region}             (NSG - NIC level: 80, 22, 8080)
├── {vnet}-{subnet}-nsg-{region}     (NSG - Subnet level: 80, 8080)
└── latency{region}                  (Storage Account, Standard_LRS)
    └── Container: public
        └── Blob: latency-test.json
```

---

> **Next:** [8.2 Generate Visualizations →](../generate-visualizations/)
