const WebSocket = require('ws');

const regions = [
  { name: 'Australia Central', ip: '20.70.1.15' },
  { name: 'Australia East', ip: '20.191.224.28' },
  { name: 'Australia Southeast', ip: '20.11.184.225' },
  { name: 'New Zealand North', ip: '172.196.49.10' },
  { name: 'East Asia (HK)', ip: '23.98.42.161' },
  { name: 'Southeast Asia (SG)', ip: '20.212.209.81' },
  { name: 'Japan East', ip: '20.222.122.69' },
  { name: 'Japan West', ip: '4.190.218.51' },
  { name: 'Korea Central', ip: '20.214.166.237' },
  { name: 'Korea South', ip: '20.214.57.81' },
  { name: 'Central India', ip: '13.71.0.39' },
  { name: 'South India', ip: '52.172.93.203' },
  { name: 'Indonesia Central', ip: '48.193.41.29' },
  { name: 'Malaysia West', ip: '85.211.182.154' },
];

const PINGS_PER_REGION = 5;
const TIMEOUT = 10000;

function testRegion(region) {
  return new Promise((resolve) => {
    const url = `ws://${region.ip}:8080`;
    const latencies = [];
    let pingCount = 0;
    let startTime;

    const ws = new WebSocket(url);
    const timer = setTimeout(() => {
      ws.close();
      resolve({ ...region, avg: null, error: 'timeout' });
    }, TIMEOUT);

    ws.on('open', () => {
      startTime = Date.now();
      ws.send(JSON.stringify({ type: 'ping', ts: startTime }));
    });

    ws.on('message', (data) => {
      const rtt = Date.now() - startTime;
      latencies.push(rtt);
      pingCount++;

      if (pingCount < PINGS_PER_REGION) {
        startTime = Date.now();
        ws.send(JSON.stringify({ type: 'ping', ts: startTime }));
      } else {
        clearTimeout(timer);
        ws.close();
        const avg = Math.round(latencies.reduce((a, b) => a + b, 0) / latencies.length);
        const min = Math.min(...latencies);
        const max = Math.max(...latencies);
        resolve({ ...region, avg, min, max, latencies });
      }
    });

    ws.on('error', (err) => {
      clearTimeout(timer);
      resolve({ ...region, avg: null, error: err.message });
    });
  });
}

async function main() {
  console.log(`\nWebSocket Latency Test (B2s) - ${new Date().toISOString()}`);
  console.log(`Pings per region: ${PINGS_PER_REGION}`);
  console.log(`Source: WSL (local machine)\n`);
  console.log('Region'.padEnd(25) + 'Avg(ms)'.padStart(8) + 'Min'.padStart(6) + 'Max'.padStart(6));
  console.log('-'.repeat(45));

  const results = [];
  for (const region of regions) {
    const result = await testRegion(region);
    if (result.error) {
      console.log(`${result.name.padEnd(25)}${'FAIL'.padStart(8)}  (${result.error})`);
    } else {
      console.log(`${result.name.padEnd(25)}${String(result.avg).padStart(8)}${String(result.min).padStart(6)}${String(result.max).padStart(6)}`);
    }
    results.push(result);
  }

  console.log('\n--- JSON Results ---');
  console.log(JSON.stringify(results.map(r => ({
    region: r.name,
    ip: r.ip,
    avgMs: r.avg,
    minMs: r.min,
    maxMs: r.max,
    error: r.error || null
  })), null, 2));
}

main();
