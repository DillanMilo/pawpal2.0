import Link from 'next/link';
import { notFound } from 'next/navigation';
import { requireAdmin } from '@/lib/admin-auth';
import { getUserDetail } from '@/lib/admin-data';
import { UserActions } from './user-actions';

export const dynamic = 'force-dynamic';

function when(value: string | null) {
  return value ? new Date(value).toLocaleString() : 'Never';
}

export default async function UserPage({ params }: { params: Promise<{ id: string }> }) {
  const identity = await requireAdmin();
  const { id } = await params;
  let detail;
  try { detail = await getUserDetail(id); } catch { notFound(); }
  const totalPoints = detail.activities.reduce((sum, item) => sum + (item.points ?? 0), 0);
  return (
    <main className="shell">
      <p><Link href="/admin" className="muted">← Back to dashboard</Link></p>
      <p className="eyebrow">Account administration</p>
      <h1>{detail.user.name || detail.user.email}</h1>
      <p className="muted">{detail.user.email} · Joined {when(detail.user.createdAt)} · Last sign-in {when(detail.user.lastSignInAt)}</p>
      <div className="notice">Prefer reversible suspension. Plan changes and destructive actions require a reason and are written to the audit log.</div>
      <UserActions userId={detail.user.id} email={detail.user.email} suspended={Boolean(detail.user.suspendedUntil)} activeOverride={detail.override?.active === true} canDelete={identity.role === 'owner' && identity.userId !== detail.user.id} />

      <section className="grid detail-grid" style={{ marginTop: 20 }}>
        <article className="card"><div className="section-head"><h2>Pets and care</h2><span className="muted">{detail.activities.length} recent logs · {totalPoints} points</span></div><ul className="list">{detail.pets.map((pet) => <li key={pet.id}><strong>{pet.name}</strong><br/><span className="muted">{pet.species}{pet.breed ? ` · ${pet.breed}` : ''}</span></li>)}{detail.pets.length === 0 && <li className="muted">No pets yet.</li>}</ul></article>
        <article className="card"><h2>Effective plan</h2><p><span className="badge">{detail.entitlement?.tier ?? 'free'} · {detail.entitlement?.status ?? 'none'}</span></p><p className="muted">Source: {detail.entitlement?.source ?? 'none'}</p>{detail.override?.active && <div className="notice">Manual {detail.override.tier} override<br/>Reason: {detail.override.reason}<br/>Expires: {when(detail.override.expires_at)}</div>}</article>
      </section>

      <section className="grid detail-grid" style={{ marginTop: 16 }}>
        <article className="card"><h2>Recent care logs</h2><ul className="list">{detail.activities.slice(0, 15).map((activity) => <li key={activity.id}><strong>{activity.type}</strong> · +{activity.points ?? 0} PawPoints<br/><span className="muted">{when(activity.start_time)}</span></li>)}</ul></article>
        <article className="card"><h2>Admin audit</h2><ul className="list">{detail.audit.map((entry) => <li key={entry.id}><strong>{entry.action}</strong><br/><span className="muted">{entry.reason} · {when(entry.created_at)}</span></li>)}</ul></article>
      </section>
    </main>
  );
}
