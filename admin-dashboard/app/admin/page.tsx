import Link from 'next/link';
import { requireAdmin } from '@/lib/admin-auth';
import { getDashboardData } from '@/lib/admin-data';
import { SignOutButton } from './sign-out';

export const dynamic = 'force-dynamic';

function shortDate(value: string | null) {
  return value ? new Intl.DateTimeFormat('en', { month: 'short', day: 'numeric', year: 'numeric' }).format(new Date(value)) : 'Never';
}

export default async function AdminDashboard() {
  const [identity, data] = await Promise.all([requireAdmin(), getDashboardData()]);
  const maxLogs = Math.max(1, ...data.trend.map((item) => item.careLogs));
  const metrics = [
    ['Total users', data.metrics.totalUsers],
    ['Active · 30d', data.metrics.activeUsers30d],
    ['Pets', data.metrics.pets],
    ['Care logs · 14d', data.metrics.careLogs14d],
    ['PawPoints · 14d', data.metrics.pawPoints14d],
    ['Engaged · 7d', `${data.metrics.retained7dPercent}%`],
  ];

  return (
    <main className="shell">
      <header className="topbar">
        <div>
          <div className="brand"><span className="brand-mark">🐾</span> PawPal Admin</div>
          <p className="muted" style={{ marginBottom: 0 }}>{identity.email} · {identity.role}</p>
        </div>
        <SignOutButton />
      </header>
      <p className="eyebrow">Owner overview</p>
      <h1>Healthy habits, clearly visible.</h1>
      <p className="muted">Operational analytics and deliberate account controls. Active means a sign-in or care log in the last 30 days.</p>

      <section className="grid metrics" aria-label="Product metrics">
        {metrics.map(([label, value]) => <article className="card metric" key={label}><span>{label}</span><strong>{value}</strong></article>)}
      </section>

      <section className="grid dashboard-grid">
        <article className="card">
          <div className="section-head"><div><h2>Care activity</h2><span className="muted">Daily logs · last 14 days</span></div></div>
          <div className="trend" aria-label="Fourteen day care activity trend">
            {data.trend.map((item) => (
              <div key={item.date} className="bar" style={{ height: `${Math.max(4, item.careLogs / maxLogs * 100)}%` }} data-label={`${item.date}: ${item.careLogs} logs · ${item.pawPoints} points`} />
            ))}
          </div>
        </article>
        <article className="card">
          <div className="section-head"><h2>Plans</h2><span className="muted">Effective state</span></div>
          {Object.entries(data.planDistribution).map(([label, count]) => <div className="plan-row" key={label}><span>{label}</span><strong>{count}</strong></div>)}
        </article>
      </section>

      <section className="card" style={{ marginTop: 16 }}>
        <div className="section-head"><div><h2>Users</h2><span className="muted">Necessary account and engagement fields only</span></div></div>
        <div className="table-wrap">
          <table>
            <thead><tr><th>User</th><th>Last sign-in</th><th>Pets</th><th>Care · 30d</th><th>PawPoints</th><th>Plan</th></tr></thead>
            <tbody>{data.users.map((user) => (
              <tr key={user.id}>
                <td><Link href={`/admin/users/${user.id}`}><strong>{user.name || user.email}</strong><br/><span className="muted">{user.name ? user.email : ''}</span></Link></td>
                <td>{shortDate(user.lastSignInAt)}{user.suspendedUntil && <><br/><span className="error">Suspended</span></>}</td>
                <td>{user.pets}</td><td>{user.careLogs30d}</td><td>{user.pawPoints30d}</td>
                <td><span className="badge">{user.plan} · {user.planStatus}</span></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      </section>

      <section className="card" style={{ marginTop: 16 }}>
        <div className="section-head"><h2>Recent admin audit</h2><span className="muted">Immutable operational trail</span></div>
        <ul className="list">{data.recentAudit.map((entry) => <li key={entry.id}><strong>{entry.action}</strong> <span className="muted">· {shortDate(entry.created_at)} · {entry.reason}</span></li>)}</ul>
      </section>
    </main>
  );
}
