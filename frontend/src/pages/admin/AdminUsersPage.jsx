import { useEffect, useState } from 'react';
import { api, errorMessage, money, mutate, number } from '../../services/api.js';
import { Badge, ErrorNotice, Loading, PageTitle, Panel, Table } from '../../components/Ui.jsx';

export default function AdminUsersPage() {
  const [data, setData] = useState({ users: [], total: 0, page: 1 });
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [selected, setSelected] = useState(null);
  const [detail, setDetail] = useState(null);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(true);
  const [page, setPage] = useState(1);
  const load = async () => {
    setBusy(true);
    try {
      setData((await api.get('/admin/users', { params: { search, status, page, limit: 20 } })).data);
      setError('');
    } catch (requestError) { setError(errorMessage(requestError)); }
    finally { setBusy(false); }
  };
  useEffect(() => { load(); }, [search, status, page]);
  const view = async (user) => {
    setSelected(user); setDetail(null);
    try { setDetail((await api.get(`/admin/users/${user.id}`)).data); }
    catch (requestError) { setError(errorMessage(requestError)); }
  };
  const toggle = async (user) => {
    const verb = user.isActive ? 'deactivate' : 'activate';
    if (!window.confirm(`Are you sure you want to ${verb} ${user.fullName}'s account?`)) return;
    try { await mutate('put', `/admin/users/${user.id}/status`, { isActive: !user.isActive }); await load(); }
    catch (requestError) { setError(errorMessage(requestError)); }
  };
  const rows = data.users.map((user) => ({ ...user, actions: <div className="table-actions">
    <button className="text-button" onClick={() => view(user)}>View details</button>
    <button className="text-button" onClick={() => toggle(user)}>{user.isActive ? 'Deactivate' : 'Activate'}</button>
  </div> }));
  return <div>
    <PageTitle title="User management" description="Search personal accounts, review their records, and manage account access." />
    <ErrorNotice message={error} onRetry={load} />
    <Panel title="Registered users" action={<span className="range-label">{data.total} accounts</span>}>
      <div className="filter-bar inline">
        <label className="field"><span>Search users</span><input placeholder="Name or email" value={search} onChange={(event) => { setPage(1); setSearch(event.target.value); }} /></label>
        <label className="field"><span>Account status</span><select value={status} onChange={(event) => { setPage(1); setStatus(event.target.value); }}><option value="">All statuses</option><option value="active">Active</option><option value="inactive">Inactive</option></select></label>
      </div>
      {busy ? <Loading /> : <Table rows={rows} columns={[
        { key: 'fullName', label: 'User', render: (row) => <><strong>{row.fullName}</strong><small className="table-subtext">{row.email}</small></> },
        { key: 'applianceCount', label: 'Appliances' },
        { key: 'recordedKwh', label: 'Recorded energy', render: (row) => `${number(row.recordedKwh)} kWh` },
        { key: 'createdAt', label: 'Joined', render: (row) => new Date(row.createdAt).toLocaleDateString() },
        { key: 'isActive', label: 'Status', render: (row) => <Badge tone={row.isActive ? 'green' : 'gray'}>{row.isActive ? 'Active' : 'Inactive'}</Badge> },
        { key: 'actions', label: 'Actions' },
      ]} emptyText="No users match these filters." />}
      <div className="pagination"><span>Page {page} of {Math.max(1, Math.ceil(data.total / 20))}</span><div><button className="button secondary small" disabled={page <= 1} onClick={() => setPage((value) => value - 1)}>Previous</button><button className="button secondary small" disabled={page * 20 >= data.total} onClick={() => setPage((value) => value + 1)}>Next</button></div></div>
    </Panel>
    {selected && <div className="modal-backdrop" onMouseDown={(event) => event.target === event.currentTarget && setSelected(null)}><div className="modal wide">
      <div className="panel-heading"><div><h2>{selected.fullName}</h2><p className="panel-caption">{selected.email}</p></div><button className="icon-button" onClick={() => setSelected(null)}>×</button></div>
      {!detail ? <Loading /> : <>
        <div className="user-detail-meta"><Badge tone={detail.user.isActive ? 'green' : 'gray'}>{detail.user.isActive ? 'Active' : 'Inactive'}</Badge><span>Joined {new Date(detail.user.createdAt).toLocaleDateString()}</span></div>
        <h3 className="subheading">Appliances</h3>
        <Table rows={detail.appliances} columns={[
          { key: 'name', label: 'Appliance' }, { key: 'category', label: 'Category' },
          { key: 'wattage', label: 'Wattage', render: (row) => `${number(row.wattage, 0)} W` },
          { key: 'isOn', label: 'Status', render: (row) => row.isOn ? 'Included' : 'Off' },
        ]} emptyText="No appliances registered." />
        <h3 className="subheading">Recent saved estimates</h3>
        <Table rows={detail.recentRecords} columns={[
          { key: 'recordedFor', label: 'Date' }, { key: 'applianceName', label: 'Appliance' },
          { key: 'kwh', label: 'Use', render: (row) => `${number(row.kwh)} kWh` },
          { key: 'cost', label: 'Cost', render: (row) => money(row.cost) },
        ]} emptyText="No saved consumption records." />
      </>}
    </div></div>}
  </div>;
}
