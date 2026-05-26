import { Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('./pages/latency-test/latency-test.component').then(
        (m) => m.LatencyTestComponent
      ),
  },
];
