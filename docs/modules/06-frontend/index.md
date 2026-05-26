---
layout: default
title: 6. Frontend Dashboard
nav_order: 7
---

# Frontend Dashboard
{: .no_toc }

## Table of Contents
{: .no_toc .text-delta }

1. TOC
{:toc}

---

## Overview

The Angular frontend provides an interactive dashboard that:
- Tests all 14 regions simultaneously
- Shows real-time latency results
- Displays WebSocket, HTTP, and Blob measurements
- Color-codes results (green/yellow/red)

## Run Locally

```bash
cd ui
npm install
ng serve
```

Open http://localhost:4200

## Deploy to Azure VM

The frontend is hosted on the Southeast Asia VM:

```bash
cd deploy
bash deploy-frontend.sh
```

Access at: `http://<southeastasia-vm-ip>`

## Configuration

Region endpoints are configured in `ui/src/assets/regions-db.json`:

```json
{
  "id": "indonesiacentral",
  "displayName": "Indonesia Central",
  "city": "Jakarta",
  "wsUrl": "ws://48.193.41.29:8080",
  "blobUrl": "https://latencyindonesiacentral.z45.web.core.windows.net/latency-test.json"
}
```

## How It Works

1. **WebSocket**: Opens persistent connection, sends timestamp, measures echo RTT
2. **HTTP Ping**: Sends HEAD request to `/ping`, measures response time
3. **Blob**: Sends HEAD request to storage static website endpoint

---

[← Analyze Results](../05-analyze-results/){: .btn .mr-2 }
[Next: Cleanup →](../07-cleanup/){: .btn .btn-primary }
