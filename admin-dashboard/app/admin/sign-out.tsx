'use client';

import { createBrowserClient } from '@supabase/ssr';

export function SignOutButton() {
  async function signOut() {
    const supabase = createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    );
    await supabase.auth.signOut();
    window.location.assign('/login');
  }
  return <button className="button secondary" onClick={signOut}>Sign out</button>;
}
