import { LoginForm } from './login-form';

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const query = await searchParams;
  return (
    <main className="login">
      <section className="card login-card">
        <div className="brand"><span className="brand-mark">🐾</span> PawPal Admin</div>
        <p className="eyebrow" style={{ marginTop: 28 }}>Private owner access</p>
        <h1 style={{ fontSize: 34 }}>Care, growth, and account operations.</h1>
        <p className="muted">Sign in with your existing PawPal identity. Access is limited to enabled accounts in the admin allowlist.</p>
        {query.error === 'not-authorized' && (
          <p className="error">This authenticated account is not authorized for PawPal administration.</p>
        )}
        <LoginForm />
      </section>
    </main>
  );
}
