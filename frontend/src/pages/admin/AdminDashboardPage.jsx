import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { Area, AreaChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { api, errorMessage, money, number } from '../../services/api.js';
import { Badge, ErrorNotice, Loading, Metric, PageTitle, Panel, Table } from '../../components/Ui.jsx';

export default function AdminDashboardPage() {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(true);
  const load = async () => {
    setBusy(true);
    try { setData((await api.get('/admin/dashboard')).data); setError(''); }
    catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, []);
  if (busy) return <Loading />;
  return <div>
    <PageTitle title="Administration overview" description="System-wide user, appliance, and recorded usage metrics."
      action={<Link className="button secondary" to="/admin/reports">View reports&nbsp; →</Link>} />
    <ErrorNotice message={error} onRetry={load} />
    {data && <>
      <section className="overview-banner admin-banner">
        <div><span className="overview-kicker">SYSTEM OVERVIEW</span><h2>Good to see you, Administrator.</h2><p>Manage accounts, review saved estimates, and keep an eye on CalWatt activity.</p></div>
        <Link className="banner-action" to="/admin/users">Manage users <span>→</span></Link>
        <span className="overview-spark" aria-hidden="true">ϟ</span>
      </section>
      <div className="metric-grid">
        <Metric label="Registered users" value={number(data.totals.users, 0)} icon="♙" />
        <Metric label="Registered appliances" value={number(data.totals.appliances, 0)} icon="▦" />
        <Metric label="Total recorded energy" value={`${number(data.totals.recordedKwh)} kWh`} icon="ϟ" />
        <Metric label="Estimated recorded costs" value={money(data.totals.estimatedCost)} icon="₱" />
      </div>
      <div className="dashboard-grid">
        <Panel title="Recorded consumption" action={<span className="range-label">Last 30 days</span>}>
          <p className="panel-caption">Only user-saved estimates are counted; this system has no physical meter feeds.</p>
          {data.last30Days.length ? <div className="chart-box">
            <ResponsiveContainer width="100%" height="100%"><AreaChart data={data.last30Days} margin={{ top: 10, right: 12, left: -18, bottom: 0 }}>
              <defs><linearGradient id="adminKwh" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#27865f" stopOpacity={0.24} /><stop offset="100%" stopColor="#27865f" stopOpacity={0} /></linearGradient></defs>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e8eee8" />
              <XAxis dataKey="day" tickFormatter={(value) => new Date(value).toLocaleDateString('en', { month: 'short', day: 'numeric', timeZone: 'UTC' })} tickLine={false} axisLine={false} />
              <YAxis tickLine={false} axisLine={false} /><Tooltip formatter={(value) => [`${number(value)} kWh`, 'Recorded']} />
              <Area type="monotone" dataKey="kwh" stroke="#1b6848" strokeWidth={2.5} fill="url(#adminKwh)" />
            </AreaChart></ResponsiveContainer>
          </div> : <div className="table-empty">No recorded usage has been submitted yet.</div>}
        </Panel>
        <Panel title="Recent administrator actions">
          <Table rows={data.recentActivity} columns={[
            { key: 'action', label: 'Action', render: (row) => <><strong>{row.action}</strong><small className="table-subtext">{row.adminName ?? 'Administrator'}</small></> },
            { key: 'entityType', label: 'Record', render: (row) => <span>{row.entityType} {row.entityId ?? ''}</span> },
            { key: 'createdAt', label: 'Time', render: (row) => new Date(row.createdAt).toLocaleString() },
          ]} emptyText="No admin actions have been logged." />
        </Panel>
      </div>
      <div className="notice info"><Badge tone="blue">ESTIMATES</Badge><span>Aggregate consumption and cost totals come from saved user records. Dashboard appliance usage is not treated as actual measured consumption.</span></div>
    </>}
  </div>;
}
