import { Component, computed, input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LatencyResult, MeasurementMode } from '../../models/latency.model';
import { Region } from '../../models/region.model';

@Component({
  selector: 'app-latency-results',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './latency-results.component.html',
})
export class LatencyResultsComponent {
  results = input<LatencyResult[]>([]);
  regions = input<Region[]>([]);
  mode = input<MeasurementMode>('both');
  bestVmRegionId = input<string | null>(null);
  bestBlobRegionId = input<string | null>(null);

  enrichedResults = computed(() => {
    return this.results().map((result) => {
      const region = this.regions().find((r) => r.id === result.regionId);
      return {
        ...result,
        displayName: region?.displayName ?? result.regionId,
        city: region?.city ?? '',
        isBestVm: result.regionId === this.bestVmRegionId(),
        isBestBlob: result.regionId === this.bestBlobRegionId(),
      };
    });
  });

  sortedResults = computed(() => {
    return [...this.enrichedResults()].sort((a, b) => {
      const mode = this.mode();
      const aVal = mode === 'blob' ? a.blobLatencyMs : a.vmLatencyMs;
      const bVal = mode === 'blob' ? b.blobLatencyMs : b.vmLatencyMs;
      if (aVal === null && bVal === null) return 0;
      if (aVal === null) return 1;
      if (bVal === null) return -1;
      return aVal - bVal;
    });
  });

  showVm = computed(() => this.mode() === 'vm' || this.mode() === 'both');
  showBlob = computed(() => this.mode() === 'blob' || this.mode() === 'both');
  showDiff = computed(() => this.mode() === 'both');

  getStatusColor(status: string): string {
    switch (status) {
      case 'success':
        return 'text-green-600';
      case 'timeout':
        return 'text-orange-500';
      case 'error':
        return 'text-red-500';
      case 'testing':
        return 'text-blue-500';
      default:
        return 'text-gray-400';
    }
  }

  getDifference(result: LatencyResult): number | null {
    if (result.vmLatencyMs !== null && result.blobLatencyMs !== null) {
      return result.vmLatencyMs - result.blobLatencyMs;
    }
    return null;
  }
}
