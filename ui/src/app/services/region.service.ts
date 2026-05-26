import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Region } from '../models/region.model';

@Injectable({ providedIn: 'root' })
export class RegionService {
  private readonly _regions = signal<Region[]>([]);
  readonly regions = this._regions.asReadonly();

  constructor(private http: HttpClient) {
    this.loadRegions();
  }

  private loadRegions(): void {
    this.http.get<Region[]>('assets/regions-db.json').subscribe({
      next: (regions) => this._regions.set(regions),
      error: (err) => console.error('Failed to load regions:', err),
    });
  }

  getRegionsByGroup(group: 'asia' | 'australia'): Region[] {
    return this.regions().filter((r) => r.group === group);
  }

  getRegionById(id: string): Region | undefined {
    return this.regions().find((r) => r.id === id);
  }
}
