'use client';

import { useRef, useState } from 'react';

type Props = {
  userId: string;
  email: string;
  suspended: boolean;
  activeOverride: boolean;
  canDelete: boolean;
};

export function UserActions({ userId, email, suspended, activeOverride, canDelete }: Props) {
  const dialog = useRef<HTMLDialogElement>(null);
  const [mode, setMode] = useState<'plan' | 'suspend' | 'delete'>('plan');
  const [message, setMessage] = useState('');
  const [busy, setBusy] = useState(false);

  function open(nextMode: typeof mode) {
    setMode(nextMode);
    setMessage('');
    dialog.current?.showModal();
  }

  async function submit(formData: FormData) {
    setBusy(true);
    setMessage('');
    let body: Record<string, unknown>;
    if (mode === 'plan') {
      const revoke = formData.get('operation') === 'revoke';
      const rawExpiry = String(formData.get('expiresAt') ?? '');
      body = revoke
        ? { action: 'revoke_override', targetUserId: userId, reason: formData.get('reason'), confirmed: true }
        : {
            action: 'grant_override', targetUserId: userId, reason: formData.get('reason'),
            tier: formData.get('tier'),
            expiresAt: rawExpiry ? new Date(rawExpiry).toISOString() : null,
            confirmed: true,
          };
    } else if (mode === 'suspend') {
      body = { action: suspended ? 'restore_user' : 'suspend_user', targetUserId: userId, reason: formData.get('reason'), confirmed: true };
    } else {
      body = { action: 'delete_user', targetUserId: userId, reason: formData.get('reason'), confirmation: formData.get('confirmation') };
    }
    const response = await fetch('/api/admin/mutations', {
      method: 'POST', headers: { 'Content-Type': 'application/json', 'X-PawPal-Admin': '1' }, body: JSON.stringify(body),
    });
    const result = await response.json();
    if (!response.ok) {
      setMessage(result.error ?? 'The operation could not be completed.');
      setBusy(false);
      return;
    }
    window.location.assign(mode === 'delete' ? '/admin' : window.location.pathname);
  }

  return (
    <>
      <div className="actions">
        <button className="button" onClick={() => open('plan')}>Manage plan override</button>
        <button className="button secondary" onClick={() => open('suspend')}>{suspended ? 'Restore access' : 'Suspend access'}</button>
        {canDelete && <button className="button danger" onClick={() => open('delete')}>Permanently delete</button>}
      </div>
      <dialog ref={dialog} onCancel={() => dialog.current?.close()}>
        <form action={submit}>
          {mode === 'plan' && <>
            <h2>Manual plan override</h2>
            <p className="muted">Use only for complimentary or support access. Store billing state is preserved and restored when this override ends.</p>
            <div className="field"><label>Operation</label><select name="operation" defaultValue={activeOverride ? 'revoke' : 'grant'}><option value="grant">Grant or replace override</option>{activeOverride && <option value="revoke">Revoke active override</option>}</select></div>
            <div className="field"><label>Tier</label><select name="tier"><option value="plus">Plus</option><option value="free">Free</option></select></div>
            <div className="field"><label>Optional expiry</label><input name="expiresAt" type="datetime-local" /></div>
          </>}
          {mode === 'suspend' && <><h2>{suspended ? 'Restore account access?' : 'Suspend account access?'}</h2><p className="muted">{suspended ? 'This reverses the sign-in suspension.' : 'Suspension is the preferred reversible safety action. Existing user data remains intact.'}</p></>}
          {mode === 'delete' && <><h2>Permanently delete this user?</h2><p className="error">This deletes the authentication account and cascaded PawPal data. It cannot be undone.</p><div className="field"><label>Type {email} to confirm</label><input name="confirmation" autoComplete="off" required /></div></>}
          <div className="field"><label>Auditable reason</label><textarea name="reason" minLength={3} maxLength={500} required /></div>
          {message && <p className="error" role="alert">{message}</p>}
          <div className="actions"><button className={mode === 'delete' ? 'button danger' : 'button'} disabled={busy}>{busy ? 'Working…' : 'Confirm action'}</button><button type="button" className="button secondary" onClick={() => dialog.current?.close()}>Cancel</button></div>
        </form>
      </dialog>
    </>
  );
}
