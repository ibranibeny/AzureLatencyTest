# E2E Test Report – Azure Latency Test

**Date:** 2026-05-26  
**Environment:** Azure Container Apps (australiaeast)  
**URL:** `http://ca-latency-frontend.politetree-44376ef6.australiaeast.azurecontainerapps.io`  
**Browser:** VS Code Integrated Simple Browser (Chromium-based)  
**Branch:** `001-azure-latency-test`

---

## Summary

| Metric | Result |
|--------|--------|
| Total Test Cases | 7 |
| Passed | 7 |
| Failed | 0 |
| Overall Status | **PASS** |

---

## Test Cases

### TC-01: Page Load & Title

| Field | Value |
|-------|-------|
| Status | PASS |
| Expected | Page loads with heading "Azure Latency Test" |
| Actual | Heading displays "Azure Latency Test" with subtitle "Test network latency to Azure regions in Asia & Australia" |

### TC-02: Region List Display

| Field | Value |
|-------|-------|
| Status | PASS |
| Expected | 14 regions displayed in 2 groups (Asia, Australia & New Zealand) |
| Actual | 10 Asia regions + 4 AU/NZ regions = 14 total |

**Regions displayed:**

| Group | Regions |
|-------|---------|
| Asia | East Asia (Hong Kong), Southeast Asia (Singapore), Japan East (Tokyo), Japan West (Osaka), Korea Central (Seoul), Korea South (Busan), Central India (Pune), South India (Chennai), Indonesia Central (Jakarta), Malaysia West (Kuala Lumpur) |
| Australia & New Zealand | Australia Central (Canberra), Australia East (Sydney), Australia Southeast (Melbourne), New Zealand North (Auckland) |

### TC-03: Select All / Deselect All

| Field | Value |
|-------|-------|
| Status | PASS |
| Expected | "Select All" selects all 14 regions; "Deselect All" deselects all |
| Actual | Select All enables Test Latency button; Deselect All disables it |

### TC-04: Latency Test Execution (All Regions)

| Field | Value |
|-------|-------|
| Status | PASS |
| Expected | All 14 regions return latency in ms with "success" status |
| Actual | All 14 regions returned SUCCESS with valid latency measurements |

**Latency Results (sorted by latency):**

| # | Region | City | Latency | Status |
|---|--------|------|---------|--------|
| 1 | East Asia | Hong Kong | 100 ms | SUCCESS |
| 2 | South India | Chennai | 116 ms | SUCCESS |
| 3 | Central India | Pune | 131 ms | SUCCESS |
| 4 | Japan West | Osaka | 138 ms | SUCCESS |
| 5 | New Zealand North | Auckland | 233 ms | SUCCESS |
| 6 | Japan East | Tokyo | 373 ms | SUCCESS |
| 7 | Korea South | Busan | 411 ms | SUCCESS |
| 8 | Korea Central | Seoul | 412 ms | SUCCESS |
| 9 | Southeast Asia | Singapore | 445 ms | SUCCESS |
| 10 | Australia East | Sydney | 447 ms | SUCCESS |
| 11 | Indonesia Central | Jakarta | 469 ms | SUCCESS |
| 12 | Australia Central | Canberra | 470 ms | SUCCESS |
| 13 | Australia Southeast | Melbourne | 475 ms | SUCCESS |
| 14 | Malaysia West | Kuala Lumpur | 498 ms | SUCCESS |

### TC-05: "Best" Badge Display

| Field | Value |
|-------|-------|
| Status | PASS |
| Expected | Lowest-latency region shows a "Best" badge |
| Actual | East Asia (Hong Kong, 100ms) displays green "Best" badge |

### TC-06: Clear All Button

| Field | Value |
|-------|-------|
| Status | PASS |
| Expected | Clears results table and deselects all regions |
| Actual | Results table removed, all regions deselected, Test Latency button disabled |

### TC-07: Individual Region Selection

| Field | Value |
|-------|-------|
| Status | PASS |
| Expected | Clicking a region card toggles its selected state |
| Actual | Region cards toggle between default and active (highlighted) states |

---

## Deployment Details

| Component | Configuration |
|-----------|--------------|
| Container Registry | latencyacr2025.azurecr.io (Basic SKU) |
| Container App | ca-latency-frontend |
| Container App Environment | cae-latency-test |
| Region | australiaeast |
| Image | latencyacr2025.azurecr.io/latency-frontend:latest |
| Ingress | External, port 80, HTTP + HTTPS (allow-insecure: true) |
| VM SKU | Standard_B1s (14 VMs across Asia/AU regions) |
| VM Endpoint | HTTP GET /ping → nginx returns "pong" |

---

## Known Deviations from Spec

| Item | Spec | Actual | Reason |
|------|------|--------|--------|
| Region Count | 15 regions | 14 regions | West India (Mumbai) VM unavailable — SKU quota not available in that region |
| Protocol | HTTPS-only frontend | HTTP access enabled | Mixed content: browser blocks HTTP VM pings from HTTPS page. HTTP access required for direct user-to-VM latency measurement |

---

## Architecture Validation

- **Frontend:** Angular 19 standalone components with signals, Tailwind CSS v4, built with multi-stage Docker (node:20-alpine → nginx:alpine)
- **Backend:** 14 Azure VMs running nginx `/ping` endpoint (HTTP only)
- **Latency Measurement:** 3 sequential fetch() probes per region, arithmetic mean of RTTs
- **Results Sorting:** Ascending by latency (lowest first)
- **Responsive Design:** Two-column region grid, full-width results table

---

## Conclusion

The Azure Latency Test application is fully functional. All 14 deployed regions respond successfully to HTTP ping probes. The UI correctly displays regions grouped by geography, performs latency measurements, identifies the best (lowest latency) region, and provides clear/deselect functionality. The application meets the requirements defined in spec.md and plan.md with the noted deviations.
