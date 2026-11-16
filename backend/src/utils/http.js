export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function asyncRoute(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch(next);
}

export function requireText(value, label, maxLength = 200) {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > maxLength) {
    throw new HttpError(400, `${label} is required and must be at most ${maxLength} characters.`);
  }
  return value.trim();
}

export function requireNumber(value, label, { min = 0, max = Number.MAX_SAFE_INTEGER } = {}) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed < min || parsed > max) {
    throw new HttpError(400, `${label} must be a number between ${min} and ${max}.`);
  }
  return parsed;
}

export function pagination(query) {
  const page = Math.max(1, Math.min(100000, Number.parseInt(query.page, 10) || 1));
  const limit = Math.max(1, Math.min(100, Number.parseInt(query.limit, 10) || 20));
  return { page, limit, offset: (page - 1) * limit };
}

function validDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const parsed = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value;
}

export function dateRange(query) {
  const from = query.from && validDate(query.from) ? query.from : null;
  const to = query.to && validDate(query.to) ? query.to : null;
  if (query.from && !from) throw new HttpError(400, 'from must be a valid YYYY-MM-DD date.');
  if (query.to && !to) throw new HttpError(400, 'to must be a valid YYYY-MM-DD date.');
  if (from && to && from > to) throw new HttpError(400, 'from must be on or before to.');
  return { from, to };
}

export function timezoneOffsetMinutes(value) {
  const offset = requireNumber(value ?? 0, 'Timezone offset', { min: -840, max: 840 });
  if (!Number.isInteger(offset)) throw new HttpError(400, 'Timezone offset must be a whole number of minutes.');
  return offset;
}

export function dateAtOffset(offsetMinutes, instant = new Date()) {
  return new Date(instant.getTime() - offsetMinutes * 60_000).toISOString().slice(0, 10);
}
