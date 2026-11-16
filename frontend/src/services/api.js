import axios from 'axios';

export const api = axios.create({
  baseURL: '/api',
  withCredentials: true,
  headers: { 'Content-Type': 'application/json' },
});

let csrfToken = null;

async function token() {
  if (!csrfToken) csrfToken = (await api.get('/auth/csrf')).data.csrfToken;
  return csrfToken;
}

export async function mutate(method, url, data, config = {}) {
  const csrfTokenValue = await token();
  try {
    const response = await api.request({
      method, url, data, ...config,
      headers: { ...config.headers, 'X-CSRF-Token': csrfTokenValue },
    });
    if (url.startsWith('/auth/')) csrfToken = null;
    return response;
  } catch (error) {
    if (url.startsWith('/auth/')) csrfToken = null;
    throw error;
  }
}

export function errorMessage(error) {
  return error?.response?.data?.error ?? error?.message ?? 'Something went wrong.';
}

export function money(value) {
  return new Intl.NumberFormat('en-PH', { style: 'currency', currency: 'PHP' }).format(Number(value ?? 0));
}

export function number(value, digits = 2) {
  return Number(value ?? 0).toLocaleString('en-PH', { maximumFractionDigits: digits });
}

export function localDateString(date = new Date()) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

export function localDateDaysAgo(days) {
  const date = new Date();
  date.setDate(date.getDate() - days);
  return localDateString(date);
}

export function exportCsv(filename, rows) {
  if (!rows.length) return;
  const columns = Object.keys(rows[0]);
  const escape = (value) => `"${String(value ?? '').replaceAll('"', '""')}"`;
  const content = [columns, ...rows.map((row) => columns.map((key) => row[key]))]
    .map((row) => row.map(escape).join(',')).join('\r\n');
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}
