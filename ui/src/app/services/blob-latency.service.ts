import { Injectable } from '@angular/core';
import { LatencyStatus } from '../models/latency.model';
import { environment } from '../../environments/environment';

export interface BlobLatencyResult {
  regionId: string;
  latencyMs: number | null;
  status: LatencyStatus;
}

@Injectable({ providedIn: 'root' })
export class BlobLatencyService {
  private readonly PING_COUNT = 5;

  async measureLatency(regionId: string, storageAccountName: string, blobUrl?: string): Promise<BlobLatencyResult> {
    const baseUrl = blobUrl || `https://${storageAccountName}.blob.core.windows.net/public/latency-test.json`;
    const rtts: number[] = [];

    try {
      for (let i = 0; i < this.PING_COUNT; i++) {
        const url = `${baseUrl}?_=${Date.now()}_${i}`;
        const start = performance.now();

        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), environment.pingTimeoutMs);

        const response = await fetch(url, {
          method: 'HEAD',
          cache: 'no-store',
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        // Any response (even 4xx) measures valid network RTT
        const rtt = performance.now() - start;
        rtts.push(rtt);
      }

      if (rtts.length === 0) {
        return { regionId, latencyMs: null, status: 'error' };
      }

      const median = this.calculateMedianWithIQR(rtts);
      return { regionId, latencyMs: Math.round(median), status: 'success' };
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') {
        return { regionId, latencyMs: null, status: 'timeout' };
      }
      return { regionId, latencyMs: null, status: 'error' };
    }
  }

  private calculateMedianWithIQR(values: number[]): number {
    const sorted = [...values].sort((a, b) => a - b);
    const len = sorted.length;

    if (len <= 2) {
      return sorted[Math.floor(len / 2)];
    }

    const q1 = sorted[Math.floor(len * 0.25)];
    const q3 = sorted[Math.floor(len * 0.75)];
    const iqr = q3 - q1;
    const lower = q1 - 1.5 * iqr;
    const upper = q3 + 1.5 * iqr;

    const filtered = sorted.filter((v) => v >= lower && v <= upper);
    if (filtered.length === 0) return sorted[Math.floor(len / 2)];

    return filtered[Math.floor(filtered.length / 2)];
  }
}
