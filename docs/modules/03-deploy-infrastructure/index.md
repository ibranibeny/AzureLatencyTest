---
layout: default
title: 3. Deploy Infrastructure
nav_order: 4
---

# Deploy Infrastructure
{: .no_toc }

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

This module deploys all Azure resources across 14 APAC regions:
- 14 Resource Groups
- 14 VMs (Standard_B2s) with ws-echo + nginx
- 14 Storage Accounts with static websites
- NSG rules for ports 80 and 8080

## Step 1: Create Resource Groups

```bash
cd deploy
bash create-resource-groups.sh
```

This creates `rg-latency-{region}` for each of the 14 regions.

## Step 2: Deploy VMs (Idempotent)

The recommended approach uses the idempotent script:

```bash
bash ensure-vms-ready.sh
```

This script:
1. Checks each VM's power state
2. If **running** → skips
3. If **stopped/deallocated** → starts it
4. If **not found** → creates it with cloud-init
5. Ensures NSG rules for ports 80 and 8080
6. Waits for all VMs to be running
7. Prints a summary of public IPs

> {: .note }
> VMs are created with `--no-wait` for parallel deployment. The script waits at the end.

## Step 3: Deploy Storage Accounts

```bash
bash create-storage-accounts.sh
bash upload-blob-payload.sh
bash configure-blob-cors.sh
```

## Step 4: Verify Deployment

```bash
bash check-vm-status.sh
bash check-blob-status.sh
```

All VMs should show `VM running` and all blob endpoints should return HTTP 200.

## Cloud-Init Configuration

Each VM is provisioned with:

```yaml
# Installs: nginx, nodejs, npm
# Deploys: ws-echo.js on port 8080
# Configures: nginx /ping endpoint on port 80
# Enables: systemd services for auto-restart
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| VM stuck in "Creating" | Wait 5 min, then `az vm start` |
| Port 8080 not reachable | Run `ensure-vms-ready.sh` to fix NSG |
| Storage 404 | Re-run `upload-blob-payload.sh` |

---

[← Architecture](../02-architecture/){: .btn .mr-2 }
[Next: Run Tests →](../04-run-tests/){: .btn .btn-primary }
