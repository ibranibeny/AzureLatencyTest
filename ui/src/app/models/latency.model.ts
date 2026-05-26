export type LatencyStatus = 'pending' | 'testing' | 'success' | 'timeout' | 'error';

export type MeasurementMode = 'vm' | 'blob' | 'both';

export interface LatencyResult {
  regionId: string;
  vmLatencyMs: number | null;
  blobLatencyMs: number | null;
  vmStatus: LatencyStatus;
  blobStatus: LatencyStatus;
  timestamp: Date;
}

export interface TestSession {
  selectedRegions: string[];
  mode: MeasurementMode;
  results: LatencyResult[];
  bestVmRegionId: string | null;
  bestBlobRegionId: string | null;
  isRunning: boolean;
}
