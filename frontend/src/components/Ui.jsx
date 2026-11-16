import { Link } from 'react-router-dom';

export function PageTitle({ title, description, action }) {
  return <div className="page-title"><div><h1>{title}</h1>{description && <p>{description}</p>}</div>{action}</div>;
}

export function Metric({ label, value, note, icon = '⚡' }) {
  return <article className="metric-card"><div className="metric-icon">{icon}</div><p>{label}</p><strong>{value}</strong>{note && <small>{note}</small>}</article>;
}

export function Panel({ title, action, children, className = '' }) {
  return <section className={`panel ${className}`}><div className="panel-heading"><h2>{title}</h2>{action}</div>{children}</section>;
}

export function Loading({ label = 'Loading data…' }) {
  return <div className="loading"><span className="spinner" />{label}</div>;
}

export function ErrorNotice({ message, onRetry }) {
  if (!message) return null;
  return <div className="notice error" role="alert"><span>{message}</span>{onRetry && <button className="text-button" onClick={onRetry}>Retry</button>}</div>;
}

export function Empty({ title, text, action }) {
  return <div className="empty"><div className="empty-icon">⌁</div><h3>{title}</h3><p>{text}</p>{action}</div>;
}

export function Field({ label, ...props }) {
  return <label className="field"><span>{label}</span><input {...props} /></label>;
}

export function SelectField({ label, children, ...props }) {
  return <label className="field"><span>{label}</span><select {...props}>{children}</select></label>;
}

export function Badge({ children, tone = 'green' }) {
  return <span className={`badge ${tone}`}>{children}</span>;
}

export function BackLink({ to = '/' }) {
  return <Link className="back-link" to={to}>← Back</Link>;
}

export function Table({ columns, rows, emptyText = 'No records yet.' }) {
  if (!rows.length) return <div className="table-empty">{emptyText}</div>;
  return <div className="table-wrap"><table><thead><tr>{columns.map((column) => <th key={column.key}>{column.label}</th>)}</tr></thead>
    <tbody>{rows.map((row, index) => <tr key={row.id ?? index}>{columns.map((column) => <td key={column.key} data-label={column.label}>{column.render ? column.render(row) : row[column.key]}</td>)}</tr>)}</tbody>
  </table></div>;
}
