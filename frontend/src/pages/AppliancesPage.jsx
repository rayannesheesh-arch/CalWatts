import { useEffect, useState } from 'react';
import { api, errorMessage, mutate, number } from '../services/api.js';
import { Empty, ErrorNotice, Field, Loading, PageTitle, SelectField } from '../components/Ui.jsx';

const categories = ['fan', 'airConditioner', 'refrigerator', 'television', 'washingMachine', 'microwave', 'riceCooker', 'light', 'desktopComputer', 'laptop', 'router', 'other'];
const labels = { fan: 'Fan', airConditioner: 'Air conditioner', refrigerator: 'Refrigerator', television: 'Television', washingMachine: 'Washing machine', microwave: 'Microwave', riceCooker: 'Rice cooker', light: 'Lighting', desktopComputer: 'Desktop computer', laptop: 'Laptop', router: 'Router', other: 'Other' };
const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const blank = { name: '', category: 'fan', wattage: '', dailyOperatingHours: '', quantity: '1', isOn: true, operatingDays: Array(7).fill(true) };

function parseOperatingDays(value) {
  const days = typeof value === 'string' ? JSON.parse(value) : value;
  if (!Array.isArray(days) || days.length !== 7 || days.some((day) => typeof day !== 'boolean')) {
    throw new Error('Appliance operating-day data is invalid.');
  }
  return days;
}

export default function AppliancesPage() {
  const [appliances, setAppliances] = useState([]);
  const [busy, setBusy] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [form, setForm] = useState(blank);
  const load = async () => {
    setBusy(true);
    try {
      const { appliances: rows } = (await api.get('/appliances')).data;
      setAppliances(rows.map((appliance) => ({ ...appliance, operatingDays: parseOperatingDays(appliance.operatingDays) })));
      setError('');
    }
    catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, []);
  const edit = (appliance) => {
    setEditing(appliance?.id ?? null);
    setForm(appliance ? {
      ...appliance,
      wattage: String(appliance.wattage),
      dailyOperatingHours: String(appliance.dailyOperatingHours),
      quantity: String(appliance.quantity),
      operatingDays: parseOperatingDays(appliance.operatingDays),
    } : { ...blank, operatingDays: [...blank.operatingDays] });
    setModalOpen(true);
    setError('');
  };
  const closeModal = () => { setModalOpen(false); setForm(blank); setEditing(null); };
  const change = (key) => (event) => setForm((current) => ({ ...current, [key]: event.target.type === 'checkbox' ? event.target.checked : event.target.value }));
  const save = async (event) => {
    event.preventDefault();
    setSaving(true); setError('');
    const body = {
      ...form, wattage: Number(form.wattage), dailyOperatingHours: Number(form.dailyOperatingHours),
      quantity: Number(form.quantity),
    };
    try {
      if (editing) await mutate('put', `/appliances/${editing}`, body);
      else await mutate('post', '/appliances', body);
      closeModal(); await load();
    } catch (requestError) { setError(errorMessage(requestError)); }
    finally { setSaving(false); }
  };
  const remove = async (appliance) => {
    if (!window.confirm(`Delete "${appliance.name}"? Its previous consumption records will remain.`)) return;
    try { await mutate('delete', `/appliances/${appliance.id}`); await load(); }
    catch (requestError) { setError(errorMessage(requestError)); }
  };

  if (busy) return <Loading />;
  return <div>
    <PageTitle title="Appliances" description="Manage the ratings and usage hours used for your estimates."
      action={<button className="button primary" onClick={() => edit(null)}>＋ Add appliance</button>} />
    <ErrorNotice message={error} onRetry={load} />
    {appliances.length === 0 ? <Empty title="No appliances yet" text="Add an appliance to start estimating household energy use." action={<button className="button primary" onClick={() => edit(null)}>Add appliance</button>} /> :
      <div className="appliance-grid">{appliances.map((appliance) => <article className="appliance-card" key={appliance.id}>
        <div className="appliance-card-head"><span className="appliance-glyph">ϟ</span><span className={`badge ${appliance.isOn ? 'green' : 'gray'}`}>{appliance.isOn ? 'Included' : 'Off'}</span></div>
        <h2>{appliance.name}</h2><p>{labels[appliance.category] ?? appliance.category}</p>
        <div className="appliance-facts"><span>{number(appliance.wattage, 0)} W</span><span>{number(appliance.dailyOperatingHours)} h/day</span><span>{appliance.quantity} unit{appliance.quantity === 1 ? '' : 's'}</span><span>{appliance.operatingDays.filter(Boolean).length} days/week</span></div>
        <div className="appliance-actions"><button className="button secondary small" onClick={() => edit(appliance)}>Edit</button><button className="button danger-quiet small" onClick={() => remove(appliance)}>Delete</button></div>
      </article>)}</div>}

    {modalOpen && <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && closeModal()}>
      <div className="modal"><div className="panel-heading"><h2>{editing ? 'Edit appliance' : 'Add appliance'}</h2><button className="icon-button" onClick={closeModal}>×</button></div>
        <form className="form-grid" onSubmit={save}>
          <Field label="Appliance name" required maxLength={120} value={form.name} onChange={change('name')} />
          <SelectField label="Category" value={form.category} onChange={change('category')}>{categories.map((category) => <option key={category} value={category}>{labels[category]}</option>)}</SelectField>
          <Field label="Wattage (W)" type="number" min="0.001" max="1000000" step="any" required value={form.wattage} onChange={change('wattage')} />
          <Field label="Daily operating hours" type="number" min="0" max="24" step="0.25" required value={form.dailyOperatingHours} onChange={change('dailyOperatingHours')} />
          <Field label="Quantity" type="number" min="1" max="1000" step="1" required value={form.quantity} onChange={change('quantity')} />
          <label className="check-field"><input type="checkbox" checked={form.isOn} onChange={change('isOn')} /> Include in current daily estimates</label>
          <fieldset className="schedule-field">
            <legend>Operating days</legend>
            <div className="schedule-days">{weekdays.map((day, index) =>
              <label className="check-field" key={day}>
                <input
                  type="checkbox"
                  checked={form.operatingDays[index]}
                  onChange={(event) => setForm((current) => ({
                    ...current,
                    operatingDays: current.operatingDays.map((enabled, dayIndex) =>
                      dayIndex === index ? event.target.checked : enabled),
                  }))}
                />
                {day}
              </label>
            )}</div>
          </fieldset>
          <div className="form-actions"><button type="button" className="button secondary" onClick={closeModal}>Cancel</button><button className="button primary" disabled={saving}>{saving ? 'Saving…' : 'Save appliance'}</button></div>
        </form>
      </div>
    </div>}
  </div>;
}
