import { useEffect, useState } from 'react';
import { api, errorMessage, money, mutate } from '../../services/api.js';
import { ErrorNotice, Field, Loading, PageTitle, Panel, Table } from '../../components/Ui.jsx';

export default function AdminRatesPage() {
  const [data, setData] = useState(null);
  const [rate, setRate] = useState('');
  const [effectiveAt, setEffectiveAt] = useState(new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().slice(0, 16));
  const [busy, setBusy] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const load = async () => {
    setBusy(true);
    try { setData((await api.get('/admin/rates')).data); setError(''); }
    catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, []);
  const save = async (event) => {
    event.preventDefault(); setSaving(true); setError(''); setSuccess('');
    try {
      await mutate('post', '/admin/rates', { rate: Number(rate), effectiveAt: new Date(effectiveAt).toISOString() });
      setRate(''); setSuccess('New electricity rate saved. Existing records retain their original rate.'); await load();
    } catch (requestError) { setError(errorMessage(requestError)); }
    finally { setSaving(false); }
  };
  if (busy) return <Loading />;
  return <div>
    <PageTitle title="Electricity rates" description="Rates are effective-dated so past estimate records remain reproducible." />
    <ErrorNotice message={error} onRetry={load} />
    {success && <div className="notice success">{success}</div>}
    <div className="dashboard-grid">
      <Panel title="Current effective rate">
        <div className="current-rate"><span>₱</span><div><strong>{money(data.current.rate)}</strong><small>per kWh · effective {new Date(data.current.effectiveAt).toLocaleString()}</small></div></div>
      </Panel>
      <Panel title="Add a rate"><form className="form-stack" onSubmit={save}>
        <Field label="Rate (PHP per kWh)" type="number" min="0.0001" step="0.0001" required value={rate} onChange={(event) => setRate(event.target.value)} />
        <Field label="Effective from" type="datetime-local" required value={effectiveAt} onChange={(event) => setEffectiveAt(event.target.value)} />
        <p className="field-hint">The effective time must be now or later. A future rate becomes active automatically at that time.</p>
        <button className="button primary" disabled={saving}>{saving ? 'Saving…' : 'Save new rate'}</button>
      </form></Panel>
    </div>
    <Panel title="Rate history"><Table rows={data.rates} columns={[
      { key: 'rate', label: 'Rate', render: (row) => `${money(row.rate)} / kWh` },
      { key: 'effectiveAt', label: 'Effective from', render: (row) => new Date(row.effectiveAt).toLocaleString() },
      { key: 'createdBy', label: 'Set by', render: (row) => row.createdBy ?? 'System default' },
    ]} emptyText="No rate history exists." /></Panel>
  </div>;
}
