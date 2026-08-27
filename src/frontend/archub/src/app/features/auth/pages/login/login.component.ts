import { ChangeDetectionStrategy, Component, OnInit, inject, signal } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { AuthService } from '@core/services/auth.service';

@Component({
  selector: 'app-login',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [ReactiveFormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent implements OnInit {
  private readonly authService = inject(AuthService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);

  protected readonly isLoading = signal<boolean>(false);
  protected readonly errorMessage = signal<string | null>(null);

  protected readonly loginForm = new FormGroup({
    email: new FormControl<string>('alex.mercer@archub.internal', {
      nonNullable: true,
      validators: [Validators.required, Validators.email]
    }),
    password: new FormControl<string>('password123', {
      nonNullable: true,
      validators: [Validators.required, Validators.minLength(6)]
    }),
    remember: new FormControl<boolean>(true, { nonNullable: true })
  });

  private returnUrl = '/attendance';

  public ngOnInit(): void {
    const param = this.route.snapshot.queryParams['returnUrl'] as string | undefined;
    if (param) {
      this.returnUrl = param;
    }
  }

  public onSubmit(): void {
    if (this.loginForm.invalid) {
      this.loginForm.markAllAsTouched();
      return;
    }

    this.isLoading.set(true);
    this.errorMessage.set(null);

    const values = this.loginForm.getRawValue();

    this.authService.login(values).subscribe({
      next: () => {
        this.isLoading.set(false);
        void this.router.navigateByUrl(this.returnUrl);
      },
      error: () => {
        this.isLoading.set(false);
        this.errorMessage.set('Invalid credentials. Please check your email and password.');
      }
    });
  }
}
