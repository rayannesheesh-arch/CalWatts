import { useEffect, useState } from 'react';
import { api, errorMessage, localDateDaysAgo, localDateString, money, number } from '../services/api.js';
import { ErrorNotice, Field, Loading, PageTitle, Table } from '../components/Ui.jsx';

const today = localDateString();
const monthAgo = localDateDaysAgo(29);

export default function HistoryPage() {
  const [from, setFrom] = useState(monthAgo);
  const [to, setTo] = useState(today);
  const [page, setPage] = useState(1);
  const [data, setData] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(true);
  const load = async () => {
    setBusy(true);
    try { setData((await api.get('/consumption', { params: { from, to, page, limit: 100 } })).data); setError(''); }
    catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, [from, to, page]);
  const rows = data?.records ?? [];
  const firstRecord = data?.total ? (data.page - 1) * data.limit + 1 : 0;
  const lastRecord = data ? Math.min(data.page * data.limit, data.total) : 0;
  return <div>
    <PageTitle title="Consumption history" description="Saved estimates with the electricity rate that applied on their record date." />
    <div className="filter-bar"><Field label="From" type="date" max={today} value={from} onChange={(event) => { setFrom(event.target.value); setPage(1); }} /><Field label="To" type="date" max={today} value={to} onChange={(event) => { setTo(event.target.value); setPage(1); }} /></div>
    <ErrorNotice message={error} onRetry={load} />
    {busy ? <Loading /> : <section className="panel"><div className="panel-heading"><h2>Saved records</h2><span className="range-label">Showing {firstRecord}–{lastRecord} of {data.total} entries</span></div>
      <Table rows={rows} columns={[
        { key: 'recordedFor', label: 'Date', render: (row) => String(row.recordedFor).slice(0, 10) },
        { key: 'applianceName', label: 'Appliance' },
        { key: 'operatingHours', label: 'Hours', render: (row) => `${number(row.operatingHours)} h` },
        { key: 'quantity', label: 'Units' },
        { key: 'kwh', label: 'Estimated use', render: (row) => `${number(row.kwh, 5)} kWh` },
        { key: 'rate', label: 'Rate', render: (row) => `${money(row.rate)} / kWh` },
        { key: 'cost', label: 'Estimated cost', render: (row) => money(row.cost) },
      ]} emptyText="No saved estimates in this date range." />
      {data.total > data.limit && <div className="pagination">
        <button className="button secondary small" disabled={page <= 1} onClick={() => setPage((current) => current - 1)}>Previous</button>
        <span>Page {data.page} of {Math.ceil(data.total / data.limit)}</span>
        <button className="button secondary small" disabled={page >= Math.ceil(data.total / data.limit)} onClick={() => setPage((current) => current + 1)}>Next</button>
      </div>}
    </section>}
  </div>;
}
