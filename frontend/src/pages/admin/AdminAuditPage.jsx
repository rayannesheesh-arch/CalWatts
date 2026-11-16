import { useEffect, useState } from 'react';
import { api, errorMessage } from '../../services/api.js';
import { ErrorNotice, Loading, PageTitle, Panel, Table } from '../../components/Ui.jsx';

export default function AdminAuditPage() {
  const [data, setData] = useState({ logs: [], total: 0 });
  const [page, setPage] = useState(1);
  const [busy, setBusy] = useState(true);
  const [error, setError] = useState('');
  const load = async () => {
    setBusy(true);
    try { setData((await api.get('/admin/audit-logs', { params: { page, limit: 30 } })).data); setError(''); }
    catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, [page]);
  return <div>
    <PageTitle title="Audit logs" description="Review administrative changes to accounts and electricity rates." />
    <ErrorNotice message={error} onRetry={load} />
    <Panel title="Administrator activity" action={<span className="range-label">{data.total} entries</span>}>
      {busy ? <Loading /> : <Table rows={data.logs} columns={[
        { key: 'createdAt', label: 'Timestamp', render: (row) => new Date(row.createdAt).toLocaleString() },
        { key: 'adminName', label: 'Administrator', render: (row) => row.adminName ?? 'Deleted account' },
        { key: 'action', label: 'Action' },
        { key: 'entityType', label: 'Record', render: (row) => `${row.entityType} ${row.entityId ?? ''}` },
        { key: 'details', label: 'Details', render: (row) => row.details ? <code className="audit-details">{typeof row.details === 'string' ? row.details : JSON.stringify(row.details)}</code> : '—' },
      ]} emptyText="No administrator actions have been recorded." />}
      <div className="pagination"><span>Page {page} of {Math.max(1, Math.ceil(data.total / 30))}</span><div><button className="button secondary small" disabled={page <= 1} onClick={() => setPage((value) => value - 1)}>Previous</button><button className="button secondary small" disabled={page * 30 >= data.total} onClick={() => setPage((value) => value + 1)}>Next</button></div></div>
    </Panel>
  </div>;
}
