import { Component, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RegionSelectorComponent } from '../../components/region-selector/region-selector.component';
import { LatencyResultsComponent } from '../../components/latency-results/latency-results.component';
import { ModeToggleComponent } from '../../components/mode-toggle/mode-toggle.component';
import { RegionService } from '../../services/region.service';
import { LatencyOrchestratorService } from '../../services/latency-orchestrator.service';
import { IpInfoService } from '../../services/ip-info.service';
import { LatencyResult, LatencyStatus, MeasurementMode } from '../../models/latency.model';

@Component({
  selector: 'app-latency-test',
  standalone: true,
  imports: [CommonModule, RegionSelectorComponent, LatencyResultsComponent, ModeToggleComponent],
  templateUrl: './latency-test.component.html',
})
export class LatencyTestComponent {
  private regionService = inject(RegionService);
  private orchestrator = inject(LatencyOrchestratorService);
  private ipInfoService = inject(IpInfoService);

  ipInfo = this.ipInfoService.ipInfo;
  regions = this.regionService.regions;
  selectedRegions = signal<string[]>([]);
  results = signal<LatencyResult[]>([]);
  isRunning = signal(false);
  mode = signal<MeasurementMode>('both');

  bestVmRegionId = computed(() => {
    const successResults = this.results().filter(
      (r) => r.vmStatus === 'success' && r.vmLatencyMs !== null
    );
    if (successResults.length === 0) return null;
    return successResults.reduce((best, current) =>
      (current.vmLatencyMs ?? Infinity) < (best.vmLatencyMs ?? Infinity)
        ? current
        : best
    ).regionId;
  });

  bestBlobRegionId = computed(() => {
    const successResults = this.results().filter(
      (r) => r.blobStatus === 'success' && r.blobLatencyMs !== null
    );
    if (successResults.length === 0) return null;
    return successResults.reduce((best, current) =>
      (current.blobLatencyMs ?? Infinity) < (best.blobLatencyMs ?? Infinity)
        ? current
        : best
    ).regionId;
  });

  canTest = computed(
    () => this.selectedRegions().length > 0 && !this.isRunning()
  );

  onSelectionChange(selected: string[]): void {
    this.selectedRegions.set(selected);
  }

  onModeChange(newMode: MeasurementMode): void {
    this.mode.set(newMode);
  }

  async runTest(): Promise<void> {
    if (!this.canTest()) return;

    this.isRunning.set(true);
    this.results.set([]);

    const pendingResults: LatencyResult[] = this.selectedRegions().map(
      (id) => ({
        regionId: id,
        vmLatencyMs: null,
        blobLatencyMs: null,
        vmStatus: this.mode() === 'blob' ? 'pending' as LatencyStatus : 'testing' as LatencyStatus,
        blobStatus: this.mode() === 'vm' ? 'pending' as LatencyStatus : 'testing' as LatencyStatus,
        timestamp: new Date(),
      })
    );
    this.results.set(pendingResults);

    const regionsToTest = this.selectedRegions()
      .map((id) => this.regionService.getRegionById(id))
      .filter((r) => r !== undefined);

    const testResults = await this.orchestrator.measureMultiple(regionsToTest, this.mode());
    this.results.set(testResults);
    this.isRunning.set(false);
  }

  clearAll(): void {
    this.selectedRegions.set([]);
    this.results.set([]);
    this.isRunning.set(false);
  }
}
