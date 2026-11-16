import { useEffect, useState } from 'react';
import { CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis, Bar, BarChart } from 'recharts';
import { api, errorMessage, exportCsv, money, number } from '../../services/api.js';
import { ErrorNotice, Field, Loading, Metric, PageTitle, Panel, Table } from '../../components/Ui.jsx';

const initialFrom = new Date(Date.now() - 29 * 86400000).toISOString().slice(0, 10);
const today = new Date().toISOString().slice(0, 10);

export default function AdminReportsPage() {
  const [from, setFrom] = useState(initialFrom);
  const [to, setTo] = useState(today);
  const [data, setData] = useState(null);
  const [busy, setBusy] = useState(true);
  const [error, setError] = useState('');
  const load = async () => {
    setBusy(true);
    try { setData((await api.get('/admin/reports', { params: { from, to } })).data); setError(''); }
    catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, [from, to]);
  return <div>
    <PageTitle title="Reports & analytics" description="System-wide summaries from persisted user estimate records." action={data && <button className="button secondary" onClick={() => exportCsv('calwatt-consumption-report.csv', data.records)}>Export CSV</button>} />
    <div className="filter-bar"><Field label="From" type="date" value={from} onChange={(event) => setFrom(event.target.value)} /><Field label="To" type="date" value={to} onChange={(event) => setTo(event.target.value)} /></div>
    <ErrorNotice message={error} onRetry={load} />
    {busy ? <Loading /> : data && <>
      <div className="metric-grid compact">
        <Metric label="Estimated energy" value={`${number(data.summary.totalKwh)} kWh`} icon="ϟ" />
        <Metric label="Estimated costs" value={money(data.summary.totalCost)} icon="₱" />
        <Metric label="Records" value={number(data.summary.recordCount, 0)} icon="▤" />
        <Metric label="Users with records" value={number(data.summary.userCount, 0)} icon="♙" />
      </div>
      <Panel title="Daily recorded use">
        {data.daily.length ? <div className="chart-box"><ResponsiveContainer width="100%" height="100%"><BarChart data={data.daily} margin={{ top: 10, right: 12, left: -18, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e8eee8" />
          <XAxis dataKey="day" tickFormatter={(value) => new Date(value).toLocaleDateString('en', { month: 'short', day: 'numeric', timeZone: 'UTC' })} tickLine={false} axisLine={false} />
          <YAxis tickLine={false} axisLine={false} /><Tooltip formatter={(value) => [`${number(value)} kWh`, 'Recorded']} />
          <Bar dataKey="kwh" fill="#27865f" radius={[5, 5, 0, 0]} />
        </BarChart></ResponsiveContainer></div> : <div className="table-empty">No saved estimates in this date range.</div>}
      </Panel>
      <Panel title="Appliance breakdown"><Table rows={data.byAppliance} columns={[
        { key: 'applianceName', label: 'Appliance' }, { key: 'records', label: 'Records' },
        { key: 'kwh', label: 'Estimated energy', render: (row) => `${number(row.kwh)} kWh` },
        { key: 'cost', label: 'Estimated cost', render: (row) => money(row.cost) },
      ]} /></Panel>
      <p className="panel-caption">CSV export includes the filtered records, capped at 5,000 rows. Use a narrower date range for larger datasets.</p>
    </>}
  </div>;
}
