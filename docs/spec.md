---
layout: default
title: Specification
nav_order: 8
---

# Technical Specification
{: .no_toc }

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Project Overview

| Attribute | Value |
|-----------|-------|
| **Name** | Azure APAC Latency Test |
| **Purpose** | Measure and compare network latency across Azure APAC regions |
| **Protocols** | WebSocket, HTTP, Azure Blob Storage |
| **Regions** | 14 Azure APAC regions |
| **Client** | Angular 17 SPA (browser-based measurement) |
| **Infrastructure** | Azure CLI deployment (no IaC frameworks) |

---

## Infrastructure Specification

### Compute

| Property | Value |
|----------|-------|
| VM SKU | `Standard_B2s` (2 vCPU, 4 GB RAM) |
| OS Image | `Canonical:ubuntu-24_04-lts:server:latest` |
| Provisioning | cloud-init (automatic on first boot) |
| Admin User | `azureuser` (SSH key auth only) |
| Services | nginx (port 80), ws-echo (port 8080) |
| Count | 14 (one per region) |

### Networking

| Property | Value |
|----------|-------|
| Public IP | Static SKU Standard, one per VM |
| NSG Rules | Inbound TCP 80 (HTTP), TCP 8080 (WebSocket) |
| DNS | None (direct IP access) |
| Load Balancer | None (single VM per region) |

### Storage

| Property | Value |
|----------|-------|
| Account Type | StorageV2, Standard_LRS |
| Feature | Static Website hosting enabled |
| Payload | `latency-test.txt` (1 KB) |
| CORS | All origins allowed (for browser access) |
| Container | `$web` (static website root) |
| Count | 14 (one per region) |

---

## Region Coverage

| # | Region ID | Display Name | City |
|---|-----------|-------------|------|
| 1 | `australiacentral` | Australia Central | Canberra |
| 2 | `australiaeast` | Australia East | Sydney |
| 3 | `australiasoutheast` | Australia Southeast | Melbourne |
| 4 | `newzealandnorth` | New Zealand North | Auckland |
| 5 | `eastasia` | East Asia | Hong Kong |
| 6 | `southeastasia` | Southeast Asia | Singapore |
| 7 | `japaneast` | Japan East | Tokyo |
| 8 | `japanwest` | Japan West | Osaka |
| 9 | `koreacentral` | Korea Central | Seoul |
| 10 | `koreasouth` | Korea South | Busan |
| 11 | `centralindia` | Central India | Pune |
| 12 | `southindia` | South India | Chennai |
| 13 | `indonesiacentral` | Indonesia Central | Jakarta |
| 14 | `malaysiawest` | Malaysia West | Kuala Lumpur |

---

## Protocol Specifications

### WebSocket Echo

| Property | Value |
|----------|-------|
| Port | 8080 |
| Path | `/` |
| Protocol | RFC 6455 (WebSocket) |
| Server | Node.js + `ws` library |
| Behavior | Echo exact message back |

**Message Format (Client → Server → Client):**

```json
{ "t": 1716710400000 }
```

**Measurement Protocol:**

1. Client opens WebSocket connection to `ws://<ip>:8080/`
2. On `open`, client sends 3 sequential probe messages
3. Each probe: `RTT = Date.now() - JSON.parse(response).t`
4. Wait for echo before sending next probe
5. Reported latency = average of 3 RTTs
6. Client closes connection

**Error Handling:**

| Scenario | Behavior |
|----------|----------|
| Connection timeout (>5s) | Status: `timeout`, latency: null |
| Connection refused | Status: `error`, latency: null |
| Echo timeout (>3s) | Status: `timeout` for that probe |
| WebSocket error event | Status: `error`, latency: null |

---

### HTTP Ping

| Property | Value |
|----------|-------|
| Port | 80 |
| Method | HEAD |
| Path | `/` |
| Server | nginx |
| Response | 200 OK (no body) |

**Measurement Protocol:**

1. Send `HEAD http://<ip>/` request
2. `RTT = responseTime - requestTime`
3. Repeat 3 times, report average
4. Each request includes TCP connection setup

**Notes:**
- No TLS (plain HTTP) to isolate network latency
- HEAD method minimizes response payload
- Includes TCP handshake overhead on each request

---

### Blob Storage

| Property | Value |
|----------|-------|
| Endpoint | `https://<account>.z23.web.core.windows.net/latency-test.txt` |
| Method | HEAD |
| Size | 1 KB payload |
| Auth | Anonymous (public static website) |

**Measurement Protocol:**

1. Send `HEAD` request to static website endpoint
2. `RTT = responseTime - requestTime`
3. Repeat 3 times, report average

**Notes:**
- Includes DNS resolution + TLS handshake + storage front-end processing
- Higher baseline latency than WebSocket/HTTP (~300-400ms overhead)
- Useful for measuring Azure Storage infrastructure performance

---

## Naming Conventions

| Resource | Pattern | Example |
|----------|---------|---------|
| Resource Group | `rg-latency-{region}` | `rg-latency-southeastasia` |
| VM | `vm-latency-{region}` | `vm-latency-japaneast` |
| Public IP | `pip-latency-{region}` | `pip-latency-koreacentral` |
| NSG | `nsg-latency-{region}` | `nsg-latency-australiaeast` |
| NIC | `nic-latency-{region}` | `nic-latency-centralindia` |
| Storage Account | `latency{region}` | `latencysoutheastasia` |

---

## Deployment Scripts

| Script | Purpose | Idempotent |
|--------|---------|:----------:|
| `deploy/ensure-vms-ready.sh` | Create/start VMs + apply NSG rules | ✅ |
| `deploy/create-storage-accounts.sh` | Provision storage with static website | ✅ |
| `deploy/upload-blob-payload.sh` | Upload 1KB test file to all accounts | ✅ |
| `deploy/configure-blob-cors.sh` | Enable CORS for browser access | ✅ |
| `deploy/create-resource-groups.sh` | Create RGs in all 14 regions | ✅ |
| `deploy/teardown.sh` | Delete all resource groups | ❌ |

---

## Frontend Specification

| Property | Value |
|----------|-------|
| Framework | Angular 17 |
| Charts | Chart.js |
| Styling | Tailwind CSS |
| Build | `ng build --configuration production` |
| Hosting | VM (Singapore) or `ng serve` locally |

**Features:**
- Real-time latency measurement from browser
- Visual comparison across all 14 regions
- Protocol selection (WebSocket / HTTP / Blob)
- Auto-refresh with configurable interval
- Results export

---

## Performance Baseline

Reference measurements from Singapore (Southeast Asia):

| Region | WebSocket RTT | Distance Factor |
|--------|:------------:|:---------------:|
| Indonesia Central | 20 ms | Closest |
| Southeast Asia | 36 ms | Local |
| Malaysia West | 39 ms | Adjacent |
| East Asia | 69 ms | Regional |
| South India | 70 ms | Regional |
| Central India | 89 ms | Medium |
| Korea South | 93 ms | Medium |
| Japan West | 103 ms | Far |
| Korea Central | 104 ms | Far |
| Japan East | 111 ms | Far |
| Australia Southeast | 124 ms | Far |
| Australia East | 135 ms | Distant |
| Australia Central | 137 ms | Distant |
| New Zealand North | 158 ms | Farthest |

---

## Key Findings

- **B1s → B2s upgrade** reduced latency 60-90% (CPU throttling inflates RTT on B1s)
- **Blob latency** adds ~300-400ms overhead vs WebSocket (DNS + TLS + storage front-end)
- **New regions** (Indonesia, Malaysia) show fastest network RTT but less mature storage
- **Accelerated Networking** unavailable on B-series; requires D/F-series for 1-3ms improvement
- **Physical distance** is the dominant latency factor (speed of light in fiber ≈ 5μs/km)

---

## Constraints & Limitations

| Constraint | Reason |
|-----------|--------|
| No TLS on WebSocket/HTTP | Isolates network latency from TLS overhead |
| No load balancer | Single VM per region keeps cost low |
| B2s only | Avoids CPU throttling; D-series costs 4x more |
| No VNet peering | Tests public internet path (user perspective) |
| Browser-only measurement | No server-to-server or Azure backbone testing |
| 14 regions | APAC focus; excludes Americas/EMEA |

---

[← Home](../){: .btn .mr-2 }
[Architecture →](modules/02-architecture/){: .btn .btn-primary }
