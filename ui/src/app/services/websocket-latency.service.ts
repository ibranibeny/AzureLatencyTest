import { Injectable } from '@angular/core';
import { LatencyStatus } from '../models/latency.model';
import { environment } from '../../environments/environment';

export interface WsLatencyResult {
  regionId: string;
  latencyMs: number | null;
  status: LatencyStatus;
}

@Injectable({ providedIn: 'root' })
export class WebSocketLatencyService {
  private readonly ECHO_COUNT = 3;

  async measureLatency(regionId: string, wsUrl: string): Promise<WsLatencyResult> {
    return new Promise((resolve) => {
      const timeoutId = setTimeout(() => {
        resolve({ regionId, latencyMs: null, status: 'timeout' });
      }, environment.pingTimeoutMs);

      try {
        const ws = new WebSocket(wsUrl);
        const rtts: number[] = [];
        let echoCount = 0;

        ws.onopen = () => {
          this.sendEcho(ws);
        };

        ws.onmessage = (event) => {
          const data = JSON.parse(event.data);
          const rtt = Date.now() - data.t;
          rtts.push(rtt);
          echoCount++;

          if (echoCount < this.ECHO_COUNT) {
            this.sendEcho(ws);
          } else {
            clearTimeout(timeoutId);
            ws.close();
            const avgLatency = Math.round(rtts.reduce((a, b) => a + b, 0) / rtts.length);
            resolve({ regionId, latencyMs: avgLatency, status: 'success' });
          }
        };

        ws.onerror = () => {
          clearTimeout(timeoutId);
          ws.close();
          resolve({ regionId, latencyMs: null, status: 'error' });
        };

        ws.onclose = (event) => {
          if (echoCount < this.ECHO_COUNT && rtts.length === 0) {
            clearTimeout(timeoutId);
            resolve({ regionId, latencyMs: null, status: 'error' });
          }
        };
      } catch {
        clearTimeout(timeoutId);
        resolve({ regionId, latencyMs: null, status: 'error' });
      }
    });
  }

  private sendEcho(ws: WebSocket): void {
    ws.send(JSON.stringify({ t: Date.now() }));
  }
}
