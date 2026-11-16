import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { api, errorMessage, money, number } from '../services/api.js';
import { Empty, ErrorNotice, Loading, Metric, PageTitle, Panel } from '../components/Ui.jsx';

export default function DashboardPage() {
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(true);
  const load = async () => {
    setBusy(true);
    try { setData((await api.get('/dashboard')).data); setError(''); }
    catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, []);
  if (busy) return <Loading />;
  return <div>
    <PageTitle title="Household overview" description="A schedule-aware daily average and 30-day projection based on your appliances."
      action={<Link className="button primary" to="/appliances">＋ Manage appliances</Link>} />
    <ErrorNotice message={error} onRetry={load} />
    {data && <>
      <section className="overview-banner">
        <div><span className="overview-kicker">YOUR ENERGY SNAPSHOT</span><h2>Small changes add up.</h2><p>Your projections average each appliance’s weekly schedule over seven days.</p></div>
        <div className="overview-rate"><span>Current electricity rate</span><strong>{money(data.rate.rate)}<small> / kWh</small></strong></div>
        <span className="overview-spark" aria-hidden="true">ϟ</span>
      </section>
      <div className="metric-grid">
        <Metric label="Estimated daily use" value={`${number(data.estimatedDailyKwh)} kWh`} icon="ϟ" />
        <Metric label="Estimated daily cost" value={money(data.estimatedDailyCost)} note={`${money(data.rate.rate)} per kWh`} icon="₱" />
        <Metric label="Estimated monthly use" value={`${number(data.estimatedMonthlyKwh)} kWh`} note="30-day projection" icon="◷" />
        <Metric label="Estimated monthly cost" value={money(data.estimatedMonthlyCost)} note={`${data.applianceCount} registered appliances`} icon="▦" />
      </div>
      <div className="dashboard-grid">
        <Panel title="Recorded consumption" action={<span className="range-label">Last 7 days</span>}>
          <p className="panel-caption">User-entered records only. These are separate from the estimate above.</p>
          {data.lastSevenDays.length ? <div className="chart-box">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={data.lastSevenDays} margin={{ top: 12, right: 12, left: -18, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e8eee8" />
                <XAxis dataKey="day" tickFormatter={(value) => new Date(value).toLocaleDateString('en', { month: 'short', day: 'numeric', timeZone: 'UTC' })} tickLine={false} axisLine={false} />
                <YAxis tickLine={false} axisLine={false} />
                <Tooltip formatter={(value) => [`${number(value)} kWh`, 'Recorded']} />
                <Line type="monotone" dataKey="kwh" stroke="#1b6848" strokeWidth={3} dot={{ r: 3 }} />
              </LineChart>
            </ResponsiveContainer>
          </div> : <Empty title="No consumption records" text="Use the calculator to save a usage estimate and see it appear here." />}
        </Panel>
        <Panel title="Last 30 days recorded">
          <div className="recorded-summary">
            <div><span>Total recorded</span><strong>{number(data.recordedLast30Days.kwh)} kWh</strong></div>
            <div><span>Estimated cost</span><strong>{money(data.recordedLast30Days.cost)}</strong></div>
            <div><span>Saved entries</span><strong>{data.recordedLast30Days.records}</strong></div>
          </div>
          <div className="info-callout">Recorded estimates use the rate that was effective on the date you save them.</div>
        </Panel>
      </div>
    </>}
  </div>;
}
