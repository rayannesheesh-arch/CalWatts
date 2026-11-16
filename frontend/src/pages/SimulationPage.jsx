import { useEffect, useMemo, useState } from 'react';
import { api, errorMessage, money, mutate, number } from '../services/api.js';
import { Empty, ErrorNotice, Field, Loading, PageTitle, Panel } from '../components/Ui.jsx';

export default function SimulationPage() {
  const [appliances, setAppliances] = useState([]);
  const [days, setDays] = useState([]);
  const [rate, setRate] = useState(0);
  const [selectedDay, setSelectedDay] = useState(null);
  const [draft, setDraft] = useState({});
  const [busy, setBusy] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const load = async () => {
    setBusy(true);
    try {
      const [a, s, dashboard] = await Promise.all([api.get('/appliances'), api.get('/simulation'), api.get('/dashboard')]);
      setAppliances(a.data.appliances);
      setDays(s.data.days);
      setRate(Number(dashboard.data.rate.rate));
      setError('');
    } catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, []);
  const byDay = useMemo(() => new Map(days.map((day) => [day.day, day])), [days]);
  const openDay = (day) => {
    const current = new Map((byDay.get(day)?.usages ?? []).map((usage) => [usage.applianceId, usage]));
    setDraft(Object.fromEntries(appliances.map((item) => [item.id, {
      selected: current.has(item.id),
      hours: current.get(item.id)?.hours ?? item.dailyOperatingHours,
      quantity: current.get(item.id)?.quantity ?? item.quantity,
    }])));
    setSelectedDay(day);
  };
  const update = (id, key, value) => setDraft((current) => ({ ...current, [id]: { ...current[id], [key]: value } }));
  const totals = (day) => (day?.usages ?? []).reduce((sum, usage) => {
    const appliance = appliances.find((item) => Number(item.id) === Number(usage.applianceId));
    return sum + (appliance ? appliance.wattage * usage.hours * usage.quantity / 1000 : 0);
  }, 0);
  const totalKwh = days.reduce((sum, day) => sum + totals(day), 0);
  const save = async (event) => {
    event.preventDefault();
    setSaving(true); setError('');
    try {
      await mutate('put', `/simulation/${selectedDay}`, {
        usages: appliances.filter((item) => draft[item.id]?.selected).map((item) => ({
          applianceId: item.id, hours: Number(draft[item.id].hours), quantity: Number(draft[item.id].quantity),
        })),
      });
      setSelectedDay(null);
      await load();
    } catch (requestError) { setError(errorMessage(requestError)); }
    finally { setSaving(false); }
  };
  const removeDay = async (day) => {
    try { await mutate('delete', `/simulation/${day}`); await load(); }
    catch (requestError) { setError(errorMessage(requestError)); }
  };
  if (busy) return <Loading />;
  return <div>
    <PageTitle title="Monthly simulation" description="Explore a hypothetical month by configuring appliance use for individual days. Simulations stay separate from saved consumption records." />
    <ErrorNotice message={error} onRetry={load} />
    {!appliances.length ? <Empty title="Add appliances first" text="Simulation days are calculated from your registered appliance wattage." /> :
      <Panel title="Day configuration" action={<span className="range-label">Up to 31 days</span>}>
        <div className="simulation-summary"><div><span>Configured days</span><strong>{days.length}</strong></div><div><span>Scenario energy</span><strong>{number(totalKwh)} kWh</strong></div><div><span>Estimated cost</span><strong>{money(totalKwh * rate)}</strong></div></div>
        <div className="day-grid">{Array.from({ length: 31 }, (_, index) => {
          const day = index + 1; const config = byDay.get(day); const kwh = totals(config);
          return <button key={day} className={`day-cell ${config ? 'configured' : ''}`} onClick={() => openDay(day)}>
            <span>Day {day}</span><strong>{config ? `${number(kwh)} kWh` : 'Configure +'}</strong>
            {config && <span className="day-delete" onClick={(event) => { event.stopPropagation(); removeDay(day); }} aria-label={`Remove day ${day}`}>×</span>}
          </button>;
        })}</div>
        <div className="simulation-note">These are scenario estimates. They do not create or alter consumption history.</div>
      </Panel>}
    {selectedDay !== null && <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && setSelectedDay(null)}>
      <div className="modal wide"><div className="panel-heading"><div><h2>Configure day {selectedDay}</h2><p className="panel-caption">Select appliances and set expected daily hours.</p></div><button className="icon-button" onClick={() => setSelectedDay(null)}>×</button></div>
        <form onSubmit={save}><div className="simulation-list">{appliances.map((item) => <div className="simulation-row" key={item.id}>
          <label className="simulation-name"><input type="checkbox" checked={Boolean(draft[item.id]?.selected)} onChange={(event) => update(item.id, 'selected', event.target.checked)} /><span><strong>{item.name}</strong><small>{number(item.wattage, 0)} W</small></span></label>
          <Field label="Hours" type="number" min="0" max="24" step="0.25" value={draft[item.id]?.hours ?? ''} onChange={(event) => update(item.id, 'hours', event.target.value)} />
          <Field label="Quantity" type="number" min="1" max="1000" step="1" value={draft[item.id]?.quantity ?? 1} onChange={(event) => update(item.id, 'quantity', event.target.value)} />
        </div>)}</div>
        <div className="form-actions"><button type="button" className="button secondary" onClick={() => setSelectedDay(null)}>Cancel</button><button className="button primary" disabled={saving}>{saving ? 'Saving…' : 'Save simulation day'}</button></div>
        </form>
      </div>
    </div>}
  </div>;
}
