---
layout: default
title: 4. Run Latency Tests
nav_order: 5
---

# Run Latency Tests
{: .no_toc }

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## CLI Test (Node.js)

The fastest way to measure WebSocket latency:

```bash
# From repo root
npm install ws
node ws-latency-test.js
```

This connects to all 14 VMs, sends 5 echo pings each, and reports avg/min/max RTT.

### Sample Output

```
=== WebSocket Latency Test Results ===

Region                         Avg   Min   Max
------------------------------  ---   ---   ---
Indonesia Central               20    17    23
Southeast Asia                  36    33    43
Malaysia West                   39    33    43
East Asia                       69    67    72
...
```

## Browser Test (Angular)

For interactive testing with the Angular dashboard:

```bash
cd ui
npm install
ng serve
```

Open http://localhost:4200 — the dashboard tests WebSocket, HTTP, and Blob latency simultaneously.

## Blob Latency Breakdown

To see where blob latency is spent (DNS vs TLS vs TTFB):

```bash
curl -o /dev/null -s -w "dns:%{time_namelookup}s tls:%{time_appconnect}s ttfb:%{time_starttransfer}s total:%{time_total}s\n" \
  "https://latencyindonesiacentral.z45.web.core.windows.net/latency-test.json"
```

## Test from Different Locations

Results vary based on your physical location. To test from the cloud:

```bash
# Run test from one of the VMs using az vm run-command
az vm run-command invoke \
  --resource-group rg-latency-southeastasia \
  --name vm-latency-southeastasia \
  --command-id RunShellScript \
  --scripts "curl -o /dev/null -s -w '%{time_total}' https://latencyindonesiacentral.z45.web.core.windows.net/latency-test.json"
```

---

[← Deploy Infrastructure](../03-deploy-infrastructure/){: .btn .mr-2 }
[Next: Analyze Results →](../05-analyze-results/){: .btn .btn-primary }
