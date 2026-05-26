import { Injectable, inject } from '@angular/core';
import { WebSocketLatencyService } from './websocket-latency.service';
import { BlobLatencyService } from './blob-latency.service';
import { LatencyResult, MeasurementMode } from '../models/latency.model';
import { Region } from '../models/region.model';

@Injectable({ providedIn: 'root' })
export class LatencyOrchestratorService {
  private wsService = inject(WebSocketLatencyService);
  private blobService = inject(BlobLatencyService);

  async measureRegion(region: Region, mode: MeasurementMode): Promise<LatencyResult> {
    const result: LatencyResult = {
      regionId: region.id,
      vmLatencyMs: null,
      blobLatencyMs: null,
      vmStatus: mode === 'blob' ? 'pending' : 'testing',
      blobStatus: mode === 'vm' ? 'pending' : 'testing',
      timestamp: new Date(),
    };

    const promises: Promise<void>[] = [];

    if (mode === 'vm' || mode === 'both') {
      promises.push(
        this.wsService.measureLatency(region.id, region.wsUrl).then((ws) => {
          result.vmLatencyMs = ws.latencyMs;
          result.vmStatus = ws.status;
        })
      );
    }

    if (mode === 'blob' || mode === 'both') {
      promises.push(
        this.blobService.measureLatency(region.id, region.storageAccountName, region.blobUrl).then((blob) => {
          result.blobLatencyMs = blob.latencyMs;
          result.blobStatus = blob.status;
        })
      );
    }

    await Promise.all(promises);
    result.timestamp = new Date();
    return result;
  }

  async measureMultiple(regions: Region[], mode: MeasurementMode): Promise<LatencyResult[]> {
    const promises = regions.map((r) => this.measureRegion(r, mode));
    return Promise.all(promises);
  }
}
