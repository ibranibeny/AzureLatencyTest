import { Component, input, output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MeasurementMode } from '../../models/latency.model';

@Component({
  selector: 'app-mode-toggle',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="flex items-center gap-1 bg-gray-100 rounded-lg p-1">
      @for (option of modes; track option.value) {
        <button
          (click)="modeChange.emit(option.value)"
          [class]="selectedMode() === option.value
            ? 'bg-white text-blue-700 shadow-sm font-semibold'
            : 'text-gray-600 hover:text-gray-900'"
          class="px-4 py-2 rounded-md text-sm transition-all duration-150">
          {{ option.label }}
        </button>
      }
    </div>
  `,
})
export class ModeToggleComponent {
  selectedMode = input<MeasurementMode>('both');
  modeChange = output<MeasurementMode>();

  modes: { value: MeasurementMode; label: string }[] = [
    { value: 'vm', label: 'VM (WebSocket)' },
    { value: 'blob', label: 'Blob (HTTP HEAD)' },
    { value: 'both', label: 'Both' },
  ];
}
