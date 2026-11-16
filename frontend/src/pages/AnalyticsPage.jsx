import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { api, errorMessage, money, number } from '../services/api.js';
import { Empty, ErrorNotice, Loading, Metric, PageTitle, Panel } from '../components/Ui.jsx';

export default function AnalyticsPage() {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(true);
  const load = async () => {
    setBusy(true);
    try {
      setData((await api.get('/dashboard')).data);
      setError('');
    } catch (requestError) {
      setError(errorMessage(requestError));
    } finally {
      setBusy(false);
    }
  };
  useEffect(() => { load(); }, []);

  if (busy) return <Loading />;
  return <div>
    <PageTitle title="Energy analytics" description="Explore your projected household use and saved consumption records." action={<Link className="button secondary" to="/history">View history</Link>} />
    <ErrorNotice message={error} onRetry={load} />
    {data && <>
      <div className="metric-grid analytics-metrics">
        <Metric label="Estimated daily use" value={`${number(data.estimatedDailyKwh)} kWh`} icon="ϟ" />
        <Metric label="Estimated daily cost" value={money(data.estimatedDailyCost)} icon="₱" />
        <Metric label="Estimated monthly use" value={`${number(data.estimatedMonthlyKwh)} kWh`} icon="◷" />
        <Metric label="Estimated monthly cost" value={money(data.estimatedMonthlyCost)} icon="▦" />
      </div>
      <Panel title="Saved consumption" action={<span className="range-label">Last 7 days</span>}>
        <p className="panel-caption">User-entered records are separate from the appliance-based estimate above.</p>
        {data.lastSevenDays.length ? <div className="chart-box">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data.lastSevenDays} margin={{ top: 12, right: 12, left: -18, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e8eee8" />
              <XAxis dataKey="day" tickFormatter={(value) => new Date(value).toLocaleDateString('en', { month: 'short', day: 'numeric', timeZone: 'UTC' })} tickLine={false} axisLine={false} />
              <YAxis tickLine={false} axisLine={false} />
              <Tooltip formatter={(value) => [`${number(value)} kWh`, 'Recorded']} />
              <Line type="monotone" dataKey="kwh" stroke="#10B981" strokeWidth={3} dot={{ r: 3 }} />
            </LineChart>
          </ResponsiveContainer>
        </div> : <Empty title="No saved consumption yet" text="Save an estimate in the calculator to start tracking your usage." />}
      </Panel>
      <Panel title="Monthly projection">
        <div className="recorded-summary">
          <div><span>Projected use</span><strong>{number(data.estimatedMonthlyKwh)} kWh</strong></div>
          <div><span>Projected cost</span><strong>{money(data.estimatedMonthlyCost)}</strong></div>
          <div><span>Appliances included</span><strong>{data.applianceCount}</strong></div>
        </div>
        <div className="info-callout">Projections average appliance use across the configured weekly schedule and use the current electricity rate. Calculator entries are estimates for specific dates and entered hours.</div>
      </Panel>
    </>}
  </div>;
}
