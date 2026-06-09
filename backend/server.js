const express = require('express');
const { execFile } = require('child_process');
const path = require('path');

const app = express();
const PORT = 3000;

// Allowed target IPs (whitelist from regions-db.json to prevent abuse)
const ALLOWED_IPS = new Set([
  '20.227.139.227',   // australiacentral
  '20.28.218.20',     // australiaeast
  '23.101.225.112',   // australiasoutheast
  '172.196.48.116',   // newzealandnorth
  '104.208.81.168',   // eastasia
  '4.194.141.31',     // southeastasia
  '20.222.52.209',    // japaneast
  '20.78.154.16',     // japanwest
  '4.230.6.218',      // koreacentral
  '20.214.10.172',    // koreasouth
  '4.247.157.36',     // centralindia
  '52.140.56.237',    // southindia
  '48.193.42.197',    // indonesiacentral
  '172.197.170.58',   // malaysiawest
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
