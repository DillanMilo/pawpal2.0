'use client';

import { useState } from 'react';
import { createBrowserClient } from '@supabase/ssr';

export function LoginForm() {
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(formData: FormData) {
    setBusy(true);
    setError('');
    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    );
    const { error: signInError } = await supabase.auth.signInWithPassword({
      email: String(formData.get('email') ?? ''),
      password: String(formData.get('password') ?? ''),
    });
    if (signInError) {
      setError('Sign-in failed. Check your PawPal admin account and try again.');
      setBusy(false);
      return;
    }
    window.location.assign('/admin');
  }

  return (
    <form action={submit}>
      <div className="field">
        <label htmlFor="email">Admin email</label>
        <input id="email" name="email" type="email" autoComplete="username" required />
      </div>
      <div className="field">
        <label htmlFor="password">Password</label>
        <input id="password" name="password" type="password" autoComplete="current-password" required />
      </div>
      {error && <p className="error" role="alert">{error}</p>}
      <button className="button" type="submit" disabled={busy} style={{ width: '100%' }}>
        {busy ? 'Signing in…' : 'Sign in securely'}
      </button>
    </form>
  );
}
