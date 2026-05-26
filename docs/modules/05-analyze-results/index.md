---
layout: default
title: 5. Analyze Results
nav_order: 6
---

# Analyze Results
{: .no_toc }

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## B2s Test Results (from Singapore)

| Region | WebSocket RTT | Distance Factor |
|--------|:------------:|:---------------:|
| Indonesia Central | 20 ms | Nearest |
| Southeast Asia | 36 ms | Local |
| Malaysia West | 39 ms | Adjacent |
| East Asia (HK) | 69 ms | ~2,500 km |
| South India | 70 ms | ~3,000 km |
| Central India | 89 ms | ~4,000 km |
| Korea South | 93 ms | ~4,500 km |
| Japan West | 103 ms | ~5,000 km |
| Korea Central | 104 ms | ~4,600 km |
| Japan East | 111 ms | ~5,300 km |
| Australia Southeast | 124 ms | ~6,000 km |
| Australia East | 135 ms | ~6,300 km |
| Australia Central | 137 ms | ~6,200 km |
| New Zealand North | 158 ms | ~8,400 km |

## Key Findings

### 1. VM SKU Matters (B1s vs B2s)

B1s VMs showed **artificially inflated latency** (300-400ms) due to CPU credit exhaustion:

| Region | B1s | B2s | Improvement |
|--------|-----|-----|:-----------:|
| Indonesia Central | 377 ms | 20 ms | 95% |
| Southeast Asia | 358 ms | 36 ms | 90% |
| Japan East | 295 ms | 111 ms | 62% |

> {: .important }
> Burstable VMs (B-series) throttle CPU when credits are exhausted, adding 200-300ms to every response.

### 2. Latency Correlates with Distance

WebSocket RTT follows physical distance almost linearly. The speed of light in fiber (~200,000 km/s) means:
- 1,000 km ≈ 10 ms round-trip (theoretical minimum)
- Actual overhead: 2-3x theoretical due to routing

### 3. Blob vs WebSocket Discrepancy

Blob storage adds significant overhead:

| Component | Time |
|-----------|------|
| DNS resolution | ~100 ms |
| TLS handshake | 2× RTT |
| Storage front-end | 20-40 ms |
| **Total overhead** | **~300-400 ms** |

New regions (Indonesia, Malaysia) have the same network RTT advantage for blobs, but less mature storage infrastructure can add variance.

### 4. Accelerated Networking

- **Not available** on B-series VMs
- Available on D/F series (2+ vCPU)
- Expected improvement: 1-3 ms reduction
- Not worth the cost for this workload

---

[← Run Tests](../04-run-tests/){: .btn .mr-2 }
[Next: Frontend Dashboard →](../06-frontend/){: .btn .btn-primary }
