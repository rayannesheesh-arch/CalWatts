import { useEffect, useState } from 'react';
import { api, errorMessage, money, mutate } from '../services/api.js';
import { useAuth } from '../context/AuthContext.jsx';
import { ErrorNotice, Field, Loading, PageTitle, Panel } from '../components/Ui.jsx';

export default function SettingsPage() {
  const { user, refresh } = useAuth();
  const [profile, setProfile] = useState({ fullName: user.fullName, email: user.email });
  const [password, setPassword] = useState({ currentPassword: '', newPassword: '' });
  const [rate, setRate] = useState(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  useEffect(() => {
    api.get('/dashboard').then(({ data }) => setRate(data.rate)).catch((requestError) => setError(errorMessage(requestError))).finally(() => setLoading(false));
  }, []);
  const updateProfile = async (event) => {
    event.preventDefault(); setBusy(true); setError(''); setSuccess('');
    try { await mutate('put', '/profile', profile); await refresh(); setSuccess('Profile updated.'); }
    catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  const updatePassword = async (event) => {
    event.preventDefault(); setBusy(true); setError(''); setSuccess('');
    try {
      await mutate('put', '/change-password', password);
      setPassword({ currentPassword: '', newPassword: '' }); setSuccess('Password changed.');
    } catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  if (loading) return <Loading />;
  return <div>
    <PageTitle title="Settings" description="Manage your profile and account security." />
    <ErrorNotice message={error} />
    {success && <div className="notice success">{success}</div>}
    <div className="settings-grid">
      <Panel title="Personal profile"><form className="form-stack" onSubmit={updateProfile}>
        <Field label="Full name" required maxLength={120} value={profile.fullName} onChange={(event) => setProfile({ ...profile, fullName: event.target.value })} />
        <Field label="Email address" type="email" required value={profile.email} onChange={(event) => setProfile({ ...profile, email: event.target.value })} />
        <button className="button primary" disabled={busy}>Save profile</button>
      </form></Panel>
      <Panel title="Change password"><form className="form-stack" onSubmit={updatePassword}>
        <Field label="Current password" type="password" minLength={10} autoComplete="current-password" required value={password.currentPassword} onChange={(event) => setPassword({ ...password, currentPassword: event.target.value })} />
        <Field label="New password" type="password" minLength={10} autoComplete="new-password" required value={password.newPassword} onChange={(event) => setPassword({ ...password, newPassword: event.target.value })} />
        <small className="field-hint">Passwords must be between 10 and 72 characters.</small>
        <button className="button primary" disabled={busy}>Update password</button>
      </form></Panel>
      <Panel title="Electricity rate"><div className="rate-setting"><div className="appliance-glyph">₱</div><div><strong>{rate ? `${money(rate.rate)} per kWh` : 'Rate unavailable'}</strong><p>Managed centrally by your CalWatt administrator. Historical records retain the rate used when saved.</p></div></div></Panel>
    </div>
  </div>;
}
