import { useEffect, useMemo, useState } from 'react';
import { api, errorMessage, localDateString, money, mutate, number } from '../services/api.js';
import { Empty, ErrorNotice, Field, Loading, PageTitle, Panel } from '../components/Ui.jsx';

export default function CalculatorPage() {
  const [appliances, setAppliances] = useState([]);
  const [projection, setProjection] = useState(null);
  const [projectionError, setProjectionError] = useState('');
  const [rate, setRate] = useState(null);
  const [entries, setEntries] = useState({});
  const [recordedFor, setRecordedFor] = useState(localDateString());
  const [rateLoading, setRateLoading] = useState(true);
  const [rateError, setRateError] = useState('');
  const [rateReload, setRateReload] = useState(0);
  const [busy, setBusy] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const load = async () => {
    setBusy(true);
    try {
      const applianceResponse = await api.get('/appliances');
      setAppliances(applianceResponse.data.appliances);
      setEntries((current) => Object.fromEntries(applianceResponse.data.appliances.map((item) => [
        item.id,
        current[item.id] ?? {
          selected: Boolean(item.isOn),
          hours: item.dailyOperatingHours,
          quantity: item.quantity,
        },
      ])));
      setError('');
    } catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, []);
  useEffect(() => {
    let active = true;
    api.get('/dashboard')
      .then(({ data }) => {
        if (active) {
          setProjection(data);
          setProjectionError('');
        }
      })
      .catch((requestError) => {
        if (active) setProjectionError(errorMessage(requestError));
      });
    return () => { active = false; };
  }, []);
  useEffect(() => {
    let active = true;
    setRate(null);
    setRateLoading(true);
    setRateError('');
    api.get('/rate', { params: { date: recordedFor, timezoneOffsetMinutes: new Date().getTimezoneOffset() } })
      .then(({ data }) => { if (active) setRate(Number(data.rate.rate)); })
      .catch((requestError) => { if (active) setRateError(errorMessage(requestError)); })
      .finally(() => { if (active) setRateLoading(false); });
    return () => { active = false; };
  }, [recordedFor, rateReload]);
  const update = (id, key) => (event) => setEntries((current) => ({ ...current, [id]: { ...current[id], [key]: event.target.value } }));
  const selected = useMemo(() => appliances.filter((item) => entries[item.id]?.selected), [appliances, entries]);
  const invalidSelected = selected.filter((item) => {
    const hours = Number(entries[item.id]?.hours);
    const quantity = Number(entries[item.id]?.quantity);
    return !Number.isFinite(hours) || hours < 0 || hours > 24
      || !Number.isInteger(quantity) || quantity < 1 || quantity > 1000;
  });
  const totals = selected.reduce((sum, appliance) => {
    const hours = Number(entries[appliance.id]?.hours ?? 0);
    const quantity = Number(entries[appliance.id]?.quantity ?? appliance.quantity);
    if (!Number.isFinite(hours) || hours < 0 || hours > 24
        || !Number.isInteger(quantity) || quantity < 1 || quantity > 1000) return sum;
    const kwh = appliance.wattage / 1000 * hours * quantity;
    const cost = kwh * (rate ?? 0);
    return {
      kwh: sum.kwh + Number(kwh.toFixed(5)),
      cost: sum.cost + Number(cost.toFixed(4)),
    };
  }, { kwh: 0, cost: 0 });

  const save = async () => {
    setSaving(true); setError(''); setSuccess('');
    try {
      const response = await mutate('post', '/consumption', {
        recordedFor,
        timezoneOffsetMinutes: new Date().getTimezoneOffset(),
        entries: selected.map((appliance) => ({
          applianceId: appliance.id,
          hours: Number(entries[appliance.id].hours),
          quantity: Number(entries[appliance.id].quantity ?? appliance.quantity),
        })),
      });
      const savedKwh = response.data.records.reduce((sum, record) => sum + Number(record.kwh), 0);
      const savedCost = response.data.records.reduce((sum, record) => sum + Number(record.cost), 0);
      setSuccess(`${response.data.records.length} record${response.data.records.length === 1 ? '' : 's'} saved for ${recordedFor}: ${number(savedKwh, 5)} kWh, ${money(savedCost)} at ${money(response.data.rate.rate)}/kWh.`);
    } catch (requestError) { setError(errorMessage(requestError)); }
    finally { setSaving(false); }
  };

  if (busy) return <Loading />;
  return <div>
    <PageTitle title="Electricity calculator" description="Calculate and save an estimated usage record for the appliances you select." />
    <ErrorNotice message={error} onRetry={load} />
    {success && <div className="notice success">{success}</div>}
    <ErrorNotice message={rateError} onRetry={() => setRateReload((reload) => reload + 1)} />
    <ErrorNotice
      message={projectionError}
      onRetry={() => {
        setProjectionError('');
        api.get('/dashboard')
          .then(({ data }) => setProjection(data))
          .catch((requestError) => setProjectionError(errorMessage(requestError)));
      }}
    />
    {!appliances.length ? <Empty title="Add appliances first" text="Your calculator uses appliance wattage from your appliance list." /> : <>
      <Panel title="Usage details" action={<span className="rate-pill">{rateLoading ? 'Loading rate…' : rate === null ? 'Rate unavailable' : `${money(rate)} / kWh`}</span>}>
        <p className="panel-caption">Select appliances used on the chosen date and enter their actual operating hours. This date-specific estimate can differ from the schedule-averaged projection on Overview and Analytics. Appliances marked off in your daily estimates can still be included here.</p>
        <div className="table-wrap calculator-table"><table><thead><tr><th>Include</th><th>Appliance</th><th>Rating</th><th>Hours used</th><th>Quantity</th><th>Estimated kWh</th></tr></thead>
          <tbody>{appliances.map((item) => {
            const state = entries[item.id] ?? {};
            const kwh = item.wattage / 1000 * Number(state.hours ?? 0) * Number(state.quantity ?? item.quantity);
            return <tr key={item.id}><td><input aria-label={`Include ${item.name}`} type="checkbox" checked={Boolean(state.selected)} onChange={(event) => setEntries((current) => ({ ...current, [item.id]: { ...current[item.id], selected: event.target.checked } }))} /></td>
            <td><strong>{item.name}</strong><small className="table-subtext">{item.category}</small></td><td>{number(item.wattage, 3)} W</td>
              <td><input className="table-input" aria-label={`${item.name} hours`} type="number" min="0" max="24" step="0.25" value={state.hours ?? item.dailyOperatingHours} onChange={update(item.id, 'hours')} /></td>
            <td><input className="table-input short" aria-label={`${item.name} quantity`} type="number" min="1" max="1000" step="1" value={state.quantity ?? item.quantity} onChange={update(item.id, 'quantity')} /></td><td>{number(kwh, 5)} kWh</td></tr>;
          })}</tbody></table></div>
      </Panel>
      {invalidSelected.length > 0 && <div className="notice error">Enter hours from 0 to 24 and a whole-number quantity from 1 to 1000 for every selected appliance.</div>}
      <div className="calculator-footer"><Field label="Record date" type="date" max={localDateString()} value={recordedFor} onChange={(event) => setRecordedFor(event.target.value)} />
        <div className="calc-total"><span>Selected-date estimate</span><strong>{number(totals.kwh, 5)} kWh</strong><strong>{money(totals.cost)}</strong></div>
        <button className="button primary" disabled={!selected.length || invalidSelected.length > 0 || saving || rateLoading || rate === null || !recordedFor} onClick={save}>{saving ? 'Saving…' : 'Save consumption record'}</button>
      </div>
      {projection && <Panel title="Overview & analytics projection">
        <p className="panel-caption">These are the same schedule-aware household projections shown on Overview and Analytics, calculated from your saved appliance settings and the current electricity rate.</p>
        <div className="recorded-summary">
          <div><span>Average daily use</span><strong>{number(projection.estimatedDailyKwh)} kWh</strong></div>
          <div><span>Average daily cost</span><strong>{money(projection.estimatedDailyCost)}</strong></div>
          <div><span>30-day use</span><strong>{number(projection.estimatedMonthlyKwh)} kWh</strong></div>
          <div><span>30-day cost</span><strong>{money(projection.estimatedMonthlyCost)}</strong></div>
        </div>
      </Panel>}
    </>}
  </div>;
}
