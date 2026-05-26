const express = require('express');
const { execFile } = require('child_process');
const path = require('path');

const app = express();
const PORT = 3000;

// Allowed target IPs (whitelist from regions-db.json to prevent abuse)
const ALLOWED_IPS = new Set([
  '20.70.1.15',       // australiacentral
  '20.191.224.28',    // australiaeast
  '20.11.184.225',    // australiasoutheast
  '172.196.49.10',    // newzealandnorth
  '23.98.42.161',     // eastasia
  '20.212.209.81',    // southeastasia
  '20.222.122.69',    // japaneast
  '4.190.218.51',     // japanwest
  '20.214.166.237',   // koreacentral
  '20.214.57.81',     // koreasouth
  '13.71.0.39',       // centralindia
  '52.172.93.203',    // southindia
  '48.193.41.29',     // indonesiacentral
  '85.211.182.154',   // malaysiawest
]);

// Validate IP format (IPv4 only)
function isValidIPv4(ip) {
  const parts = ip.split('.');
  if (parts.length !== 4) return false;
  return parts.every(p => {
    const n = parseInt(p, 10);
    return n >= 0 && n <= 255 && String(n) === p;
  });
}

// Parse ping output to extract avg RTT
function parsePingOutput(stdout) {
  // Linux ping output: rtt min/avg/max/mdev = 1.234/2.345/3.456/0.567 ms
  const match = stdout.match(/rtt min\/avg\/max\/mdev = [\d.]+\/([\d.]+)\//);
  if (match) return parseFloat(match[1]);
  return null;
}

// ICMP ping endpoint
app.get('/api/ping', (req, res) => {
  const target = req.query.target;

  if (!target || !isValidIPv4(target)) {
    return res.status(400).json({ error: 'Invalid target IP' });
  }

  if (!ALLOWED_IPS.has(target)) {
    return res.status(403).json({ error: 'Target IP not in allowed list' });
  }

  // Run ping with 3 probes, 2 second timeout
  execFile('ping', ['-c', '3', '-W', '2', target], { timeout: 10000 }, (error, stdout, stderr) => {
    if (error) {
      return res.json({
        target,
        latencyMs: null,
        status: 'error',
        message: 'Host unreachable or timeout',
      });
    }

    const avgMs = parsePingOutput(stdout);
    if (avgMs === null) {
      return res.json({
        target,
        latencyMs: null,
        status: 'error',
        message: 'Failed to parse ping output',
      });
    }

    res.json({
      target,
      latencyMs: Math.round(avgMs),
      status: 'success',
    });
  });
});

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Latency backend listening on 127.0.0.1:${PORT}`);
});
