import { Component, computed, input, output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Region } from '../../models/region.model';

@Component({
  selector: 'app-region-selector',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './region-selector.component.html',
})
export class RegionSelectorComponent {
  regions = input.required<Region[]>();
  selectedRegions = input<string[]>([]);
  selectionChange = output<string[]>();

  asiaRegions = computed(() =>
    this.regions().filter((r) => r.group === 'asia')
  );

  australiaRegions = computed(() =>
    this.regions().filter((r) => r.group === 'australia')
  );

  isSelected(regionId: string): boolean {
    return this.selectedRegions().includes(regionId);
  }

  toggleRegion(regionId: string): void {
    const current = this.selectedRegions();
    const updated = this.isSelected(regionId)
      ? current.filter((id) => id !== regionId)
      : [...current, regionId];
    this.selectionChange.emit(updated);
  }

  selectAll(): void {
    this.selectionChange.emit(this.regions().map((r) => r.id));
  }

  deselectAll(): void {
    this.selectionChange.emit([]);
  }
}
