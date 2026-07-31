import 'server-only';
import { cookies } from 'next/headers';
import { createServerClient, type SetAllCookies } from '@supabase/ssr';
import { createClient } from '@supabase/supabase-js';
import { serverEnv } from './env';

export async function userSupabase() {
  const env = serverEnv();
  const cookieStore = await cookies();
  return createServerClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    {
      cookies: {
        getAll: () => cookieStore.getAll(),
        setAll: (values: Parameters<SetAllCookies>[0]) => {
          try {
            for (const value of values) cookieStore.set(value);
          } catch {
            // Server components cannot write cookies; middleware refreshes them.
          }
        },
      },
    },
  );
}

export function adminSupabase() {
  const env = serverEnv();
  return createClient(
    env.NEXT_PUBLIC_SUPABASE_URL,
    env.SUPABASE_SERVICE_ROLE_KEY,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );
}
