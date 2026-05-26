import { Injectable } from '@angular/core';
import { LatencyResult } from '../models/latency.model';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class LatencyService {
  async measureLatency(regionId: string, pingUrl: string): Promise<LatencyResult> {
    try {
      // Extract target IP from pingUrl (e.g. "http://20.191.224.28/ping" → "20.191.224.28")
      const url = new URL(pingUrl);
      const targetIp = url.hostname;

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), environment.pingTimeoutMs);

      const response = await fetch(`/api/ping?target=${targetIp}`, {
        method: 'GET',
        cache: 'no-store',
        signal: controller.signal,
      });
      clearTimeout(timeoutId);

      const data = await response.json();

      if (data.status === 'success' && data.latencyMs !== null) {
        return {
          regionId,
          latencyMs: data.latencyMs,
          status: 'success',
          timestamp: new Date(),
        };
      }

      return {
        regionId,
        latencyMs: null,
        status: 'error',
        timestamp: new Date(),
      };
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') {
        return {
          regionId,
          latencyMs: null,
          status: 'timeout',
          timestamp: new Date(),
        };
      }

      return {
        regionId,
        latencyMs: null,
        status: 'error',
        timestamp: new Date(),
      };
    }
  }

  async measureMultiple(
    regions: { id: string; pingUrl: string }[]
  ): Promise<LatencyResult[]> {
    const promises = regions.map((r) => this.measureLatency(r.id, r.pingUrl));
    return Promise.all(promises);
  }
}
