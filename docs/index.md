---
layout: default
title: Home
nav_order: 1
---

# Azure APAC Latency Test — Workshop
{: .fs-9 }

Measure and compare WebSocket, HTTP, and Blob storage latency across 14 Azure regions in Asia-Pacific.
{: .fs-6 .fw-300 }

[Get Started](modules/01-prerequisites/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[View Architecture](modules/02-architecture/){: .btn .fs-5 .mb-4 .mb-md-0 }

---

## What You'll Build

A latency measurement platform that:

- **Deploys 14 VMs** across APAC Azure regions with WebSocket echo servers
- **Measures WebSocket RTT** via persistent connections (port 8080)
- **Measures HTTP ping** via nginx HEAD requests (port 80)
- **Measures Blob latency** via Azure Storage static websites
- **Visualizes results** in an Angular dashboard with real-time charts

## Architecture at a Glance

| Component | Technology | Hosting |
|-----------|-----------|--------|
| 🖥️ Frontend | Angular | VM (Southeast Asia) or local |
| 🔌 WebSocket Echo | Node.js + ws | B2s VM × 14 regions |
| 🌐 HTTP Ping | nginx | B2s VM × 14 regions |
| 📦 Blob Storage | Static Website | Storage Account × 14 regions |
| 🛡️ Networking | NSG + Public IP | Per-region |

## Workshop Modules

| # | Module | Duration | Description |
|---|--------|----------|-------------|
| 1 | [Prerequisites](modules/01-prerequisites/) | 10 min | Set up your environment |
| 2 | [Architecture](modules/02-architecture/) | 10 min | Understand the system design |
| 3 | [Deploy Infrastructure](modules/03-deploy-infrastructure/) | 25 min | Provision VMs and storage |
| 4 | [Run Latency Tests](modules/04-run-tests/) | 15 min | Execute tests and collect data |
| 5 | [Analyze Results](modules/05-analyze-results/) | 15 min | Interpret findings |
| 6 | [Frontend Dashboard](modules/06-frontend/) | 20 min | Deploy the Angular UI |
| 7 | [Cleanup](modules/07-cleanup/) | 5 min | Destroy resources |
| 8 | [Azure Visualizer Demo](modules/08-azure-visualizer-demo/) | 20 min | Generate architecture diagrams with Copilot |

**Total estimated time: ~1.5 hours** (+ 20 min optional visualizer demo)

## Key Design Decisions

- **Azure CLI over Bicep/Terraform** — lower barrier for workshop attendees
- **B2s over B1s** — avoids CPU throttling on burstable VMs that inflates latency
- **Idempotent scripts** — `ensure-vms-ready.sh` handles create, start, and NSG in one pass
- **Multiple measurement types** — WebSocket (persistent), HTTP (request/response), Blob (storage layer)
- **14 APAC regions** — comprehensive coverage including new regions (Indonesia, Malaysia)

> {: .note }
> This workshop targets APAC regions. GPU or premium SKUs are not required.

---

Azure Latency Test Workshop — Microsoft Indonesia


