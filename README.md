# Azure APAC Latency Test

Measure and compare WebSocket, HTTP ping, and Blob storage latency across **14 Azure regions** in Asia-Pacific.

## 🌏 Regions Covered

| Region | City |
|--------|------|
| Australia Central | Canberra |
| Australia East | Sydney |
| Australia Southeast | Melbourne |
| New Zealand North | Auckland |
| East Asia | Hong Kong |
| Southeast Asia | Singapore |
| Japan East | Tokyo |
| Japan West | Osaka |
| Korea Central | Seoul |
| Korea South | Busan |
| Central India | Pune |
| South India | Chennai |
| Indonesia Central | Jakarta |
| Malaysia West | Kuala Lumpur |

## Architecture

```
┌─────────────┐         ┌──────────────────┐
│   Browser   │ ──WS──▶ │  VM (ws-echo)    │  x14 regions
│  (Angular)  │ ──HTTP─▶ │  nginx /ping     │  Standard_B2s
│             │ ──GET──▶ │  Blob Storage    │  Static Website
└─────────────┘         └──────────────────┘
```

Each region has:
- **B2s VM** running a WebSocket echo server (port 8080) and nginx ping endpoint (port 80)
- **Storage Account** with static website hosting for blob latency tests
- **NSG** with inbound rules for ports 80 and 8080

## Features

- **Real-time latency measurement** — WebSocket, HTTP ping, and Blob download tests
- **IP/ISP/Location card** — Displays your public IP, ISP, and geolocation on the dashboard
- **14 APAC regions** — Comprehensive coverage from Auckland to Mumbai
- **Idempotent deployment** — `ensure-vms-ready.sh` safely handles create, start, and NSG in one pass
- **Live frontend** — Angular 19 dashboard at [http://4.194.41.14/](http://4.194.41.14/)

## Quick Start

### Prerequisites
- Azure CLI (`az`) authenticated
- Bash shell (WSL/Linux/macOS)
- Node.js 20+ (for local testing and Angular 19 build)

### Check & Start All VMs

```bash
cd deploy
bash ensure-vms-ready.sh
```

This single idempotent script:
- Creates/starts all 14 APAC VMs and the frontend VM
- Ensures NSG rules for ports 80 and 8080
- Enables public access on storage accounts
- Prints a summary of all public IPs

### Deploy All Infrastructure

```bash
cd deploy
bash ensure-vms-ready.sh    # Create/start VMs + open NSG rules
bash create-storage-accounts.sh
bash upload-blob-payload.sh
bash configure-blob-cors.sh
```

### Run Latency Test (CLI)

```bash
npm install ws
node ws-latency-test.js
```

### Run Frontend (Angular)

```bash
cd ui
npm install
ng serve
```

Open http://localhost:4200 to run interactive latency tests from your browser.

## Test Results (B2s from Singapore)

| Region | WebSocket RTT | Notes |
|--------|:------------:|-------|
| Indonesia Central | 20 ms | Closest |
| Southeast Asia | 36 ms | |
| Malaysia West | 39 ms | |
| East Asia | 69 ms | |
| South India | 70 ms | |
| Central India | 89 ms | |
| Korea South | 93 ms | |
| Japan West | 103 ms | |
| Korea Central | 104 ms | |
| Japan East | 111 ms | |
| Australia Southeast | 124 ms | |
| Australia East | 135 ms | |
| Australia Central | 137 ms | |
| New Zealand North | 158 ms | Farthest |

## Key Findings

- **B1s → B2s upgrade** reduced latency by 60-90% due to CPU throttling on burstable VMs
- **Blob latency** scales with distance but adds ~300-400ms overhead (DNS + TLS + storage front-end)
- **New regions** (Indonesia, Malaysia) have fastest network RTT but less mature storage infrastructure
- **Accelerated Networking** not available on B-series; requires D/F series for 1-3ms further improvement

## Project Structure

```
├── deploy/                  # Azure CLI deployment scripts
│   ├── config.sh           # Shared configuration (regions, naming)
│   ├── ensure-vms-ready.sh # Idempotent VM provisioning
│   ├── create-vms.sh       # Initial VM creation with cloud-init
│   ├── cloud-init.yaml     # VM setup (nginx + ws-echo service)
│   └── ...
├── ui/                     # Angular frontend app
│   └── src/
│       ├── app/services/   # Latency measurement services
│       └── assets/regions-db.json
├── backend/
│   └── ws-echo.js          # WebSocket echo server
├── ws-latency-test.js      # CLI latency test script
└── docs/                   # GitHub Pages workshop site
```

## Workshop

📖 **Full workshop guide**: [https://ibranibeny.github.io/AzureLatencyTest/](https://ibranibeny.github.io/AzureLatencyTest/)

## License

MIT
