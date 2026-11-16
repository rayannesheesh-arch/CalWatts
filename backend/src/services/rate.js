import { pool } from '../config/database.js';
import { HttpError } from '../utils/http.js';

export async function rateForDate(connection, date) {
  const [rows] = await connection.execute(
    `SELECT id, rate_per_kwh AS rate
     FROM electricity_rates
     WHERE effective_at < DATE_ADD(?, INTERVAL 1 DAY)
     ORDER BY effective_at DESC, id DESC LIMIT 1`,
    [date],
  );
  if (!rows[0]) throw new HttpError(503, 'No electricity rate is configured for this date.');
  return rows[0];
}

export async function currentRate() {
  const [rows] = await pool.execute(
    'SELECT id, rate_per_kwh AS rate, effective_at AS effectiveAt FROM electricity_rates WHERE effective_at <= UTC_TIMESTAMP(3) ORDER BY effective_at DESC, id DESC LIMIT 1',
  );
  if (!rows[0]) throw new HttpError(503, 'No electricity rate is configured.');
  return rows[0];
}
