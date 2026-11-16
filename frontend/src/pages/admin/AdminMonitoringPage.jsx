import { useEffect, useState } from 'react';
import { api, errorMessage, money, number } from '../../services/api.js';
import { ErrorNotice, Field, Loading, PageTitle, Panel, Table } from '../../components/Ui.jsx';

export default function AdminMonitoringPage() {
  const [filters, setFilters] = useState({ from: '', to: '', userId: '' });
  const [data, setData] = useState({ records: [], total: 0 });
  const [page, setPage] = useState(1);
  const [busy, setBusy] = useState(true);
  const [error, setError] = useState('');
  const load = async () => {
    setBusy(true);
    try { setData((await api.get('/admin/consumption', { params: { ...filters, page, limit: 30 } })).data); setError(''); }
    catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, [filters.from, filters.to, filters.userId, page]);
  const update = (key) => (event) => { setPage(1); setFilters((state) => ({ ...state, [key]: event.target.value })); };
  return <div>
    <PageTitle title="Energy monitoring" description="Browse saved estimated usage across user accounts. No live meter data is collected." />
    <ErrorNotice message={error} onRetry={load} />
    <Panel title="Consumption records" action={<span className="range-label">{data.total} records</span>}>
      <div className="filter-bar inline">
        <Field label="From" type="date" value={filters.from} onChange={update('from')} />
        <Field label="To" type="date" value={filters.to} onChange={update('to')} />
        <Field label="User ID" type="number" min="1" value={filters.userId} onChange={update('userId')} placeholder="All users" />
      </div>
      {busy ? <Loading /> : <Table rows={data.records} columns={[
        { key: 'recordedFor', label: 'Date' },
        { key: 'fullName', label: 'User', render: (row) => <><strong>{row.fullName}</strong><small className="table-subtext">{row.email}</small></> },
        { key: 'applianceName', label: 'Appliance' },
        { key: 'wattage', label: 'Watts', render: (row) => `${number(row.wattage, 0)} W` },
        { key: 'operatingHours', label: 'Hours', render: (row) => `${number(row.operatingHours)} h × ${row.quantity}` },
        { key: 'kwh', label: 'Estimated use', render: (row) => `${number(row.kwh)} kWh` },
        { key: 'rate', label: 'Rate', render: (row) => `${money(row.rate)} / kWh` },
        { key: 'cost', label: 'Estimated cost', render: (row) => money(row.cost) },
      ]} emptyText="No recorded estimates match these filters." />}
      <div className="pagination"><span>Page {page} of {Math.max(1, Math.ceil(data.total / 30))}</span><div><button className="button secondary small" disabled={page <= 1} onClick={() => setPage((value) => value - 1)}>Previous</button><button className="button secondary small" disabled={page * 30 >= data.total} onClick={() => setPage((value) => value + 1)}>Next</button></div></div>
    </Panel>
  </div>;
}
