import { Component } from '@angular/core';
import { HeroComponent } from './features/home/components/hero/hero.component';

@Component({
  selector: 'cc-root',
  standalone: true,
  imports: [HeroComponent],
  template: `<cc-hero></cc-hero>`,
})
export class AppComponent {}
