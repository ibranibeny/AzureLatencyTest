---
layout: default
title: 1. Prerequisites
nav_order: 2
---

# Prerequisites
{: .no_toc }

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Required Tools

| Tool | Version | Purpose |
|------|---------|--------|
| Azure CLI | 2.60+ | Deploy Azure resources |
| Node.js | 18+ | Run latency tests locally |
| Angular CLI | 17+ | Build the frontend (optional) |
| WSL or Bash | any | Execute deploy scripts |

## Azure Subscription

You need an active Azure subscription with permissions to:
- Create resource groups
- Create VMs (Standard_B2s)
- Create storage accounts
- Create NSG rules

## Setup Steps

### 1. Install Azure CLI

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### 2. Login to Azure

```bash
az login
az account set --subscription "<your-subscription>"
```

### 3. Install Node.js

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
nvm install 20
```

### 4. Clone this repository

```bash
git clone https://github.com/ibranibeny/AzureLatencyTest.git
cd AzureLatencyTest
```

## Verify Setup

```bash
az --version        # Should show 2.60+
node --version      # Should show v18+
az account show     # Should show your subscription
```

> {: .tip }
> If using WSL on Windows, ensure you run all commands from the WSL terminal, not PowerShell.

---

[Next: Architecture →](../02-architecture/){: .btn .btn-primary }
