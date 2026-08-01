import { createServerClient, type SetAllCookies } from '@supabase/ssr';
import { NextResponse, type NextRequest } from 'next/server';

export async function proxy(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  const isAdminSurface =
    pathname.startsWith('/admin') ||
    pathname.startsWith('/api/admin') ||
    pathname.startsWith('/login') ||
    pathname.startsWith('/_next');
  const isStaticAsset = /\.[a-zA-Z0-9]+$/.test(pathname);
  if (!isAdminSurface && !isStaticAsset) {
    return NextResponse.rewrite(new URL('/index.html', request.url));
  }
  if (isStaticAsset || pathname.startsWith('/_next')) return NextResponse.next();

  let response = NextResponse.next({ request });
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => request.cookies.getAll(),
        setAll: (cookies: Parameters<SetAllCookies>[0]) => {
          for (const cookie of cookies) request.cookies.set(cookie.name, cookie.value);
          response = NextResponse.next({ request });
          for (const cookie of cookies) response.cookies.set(cookie);
        },
      },
    },
  );

  const { data } = await supabase.auth.getUser();
  const protectedPath =
    pathname.startsWith('/admin') || pathname.startsWith('/api/admin');
  if (protectedPath && !data.user) {
    const loginUrl = request.nextUrl.clone();
    loginUrl.pathname = '/login';
    loginUrl.search = '';
    return NextResponse.redirect(loginUrl);
  }
  return response;
}

export const proxyConfig = {
  matcher: ['/((?!favicon.ico).*)'],
};
