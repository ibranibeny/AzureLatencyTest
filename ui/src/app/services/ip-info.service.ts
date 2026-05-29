import { Injectable, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';

export interface IpInfo {
  ip: string;
  isp: string;
  city: string;
  region: string;
  country: string;
}

@Injectable({ providedIn: 'root' })
export class IpInfoService {
  private readonly _ipInfo = signal<IpInfo | null>(null);
  readonly ipInfo = this._ipInfo.asReadonly();

  constructor(private http: HttpClient) {
    this.fetchIpInfo();
  }

  private fetchIpInfo(): void {
    this.http
      .get<{
        query: string;
        isp: string;
        city: string;
        regionName: string;
        country: string;
      }>('http://ip-api.com/json/?fields=query,isp,city,regionName,country')
      .subscribe({
        next: (data) => {
          this._ipInfo.set({
            ip: data.query,
            isp: data.isp,
            city: data.city,
            region: data.regionName,
            country: data.country,
          });
        },
        error: (err) => console.error('Failed to fetch IP info:', err),
      });
  }
}
