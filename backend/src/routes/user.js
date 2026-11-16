import { Router } from 'express';
import bcrypt from 'bcrypt';
import { pool } from '../config/database.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { currentRate, rateForDate } from '../services/rate.js';
import {
  calculateAverageDailyKwh, calculateEntry, requirePassword, requireValidEmail, roundEntry,
} from '../services/energy.js';
import {
  asyncRoute, dateAtOffset, dateRange, HttpError, pagination, requireNumber, requireText,
  timezoneOffsetMinutes,
} from '../utils/http.js';

const router = Router();
router.use(requireAuth, requireRole('user'));

function validateAppliance(body) {
  const name = requireText(body.name, 'Appliance name', 120);
  const category = typeof body.category === 'string' && /^[a-zA-Z0-9 _-]{1,60}$/.test(body.category)
    ? body.category.trim() : 'other';
  const wattage = requireNumber(body.wattage, 'Wattage', { min: Number.EPSILON, max: 1000000 });
  const dailyOperatingHours = requireNumber(body.dailyOperatingHours, 'Operating hours', { min: 0, max: 24 });
  const quantity = requireNumber(body.quantity ?? 1, 'Quantity', { min: 1, max: 1000 });
  const operatingDays = body.operatingDays ?? [true, true, true, true, true, true, true];
  if (!Array.isArray(operatingDays) || operatingDays.length !== 7 || operatingDays.some((day) => typeof day !== 'boolean')) {
    throw new HttpError(400, 'Operating days must be seven boolean values.');
  }
  if (typeof body.isOn !== 'boolean' && body.isOn !== undefined) throw new HttpError(400, 'isOn must be a boolean.');
  return { name, category, wattage, dailyOperatingHours, quantity, operatingDays, isOn: body.isOn ?? true };
}

router.get('/profile', (req, res) => res.json({ user: req.user }));

router.get('/rate', asyncRoute(async (req, res) => {
  const { from: date } = dateRange({ from: req.query.date });
  if (!date) throw new HttpError(400, 'A valid date is required.');
  const offset = timezoneOffsetMinutes(req.query.timezoneOffsetMinutes);
  if (date > dateAtOffset(offset)) throw new HttpError(400, 'A rate cannot be requested for a future date.');
  res.json({ rate: await rateForDate(pool, date) });
}));

router.put('/profile', asyncRoute(async (req, res) => {
  const fullName = requireText(req.body.fullName, 'Full name', 120);
  const email = requireValidEmail(req.body.email);
  try {
    await pool.execute('UPDATE users SET full_name = ?, email = ? WHERE id = ?', [fullName, email, req.user.id]);
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') throw new HttpError(409, 'That email address is already in use.');
    throw error;
  }
  res.json({ user: { ...req.user, fullName, email } });
}));

router.put('/change-password', asyncRoute(async (req, res) => {
  const oldPassword = requirePassword(req.body.currentPassword);
  const newPassword = requirePassword(req.body.newPassword);
  const [rows] = await pool.execute('SELECT password_hash AS passwordHash FROM users WHERE id = ?', [req.user.id]);
  if (!await bcrypt.compare(oldPassword, rows[0].passwordHash)) throw new HttpError(400, 'Current password is incorrect.');
  await pool.execute('UPDATE users SET password_hash = ? WHERE id = ?', [await bcrypt.hash(newPassword, 12), req.user.id]);
  res.status(204).end();
}));

router.get('/dashboard', asyncRoute(async (req, res) => {
  const [appliances] = await pool.execute(
    `SELECT wattage, daily_operating_hours AS dailyOperatingHours, operating_days AS operatingDays,
            is_on AS isOn, quantity
     FROM appliances WHERE user_id = ?`,
    [req.user.id],
  );
  const [recorded] = await pool.execute(
    `SELECT COALESCE(SUM(consumption_kwh), 0) AS recordedKwh,
            COALESCE(SUM(estimated_cost), 0) AS recordedCost,
            COUNT(*) AS recordCount
     FROM consumption_records
     WHERE user_id = ? AND recorded_for >= DATE_SUB(UTC_DATE(), INTERVAL 29 DAY)`,
    [req.user.id],
  );
  const rate = await currentRate();
  const [daily] = await pool.execute(
    `SELECT recorded_for AS day, SUM(consumption_kwh) AS kwh, SUM(estimated_cost) AS cost
     FROM consumption_records WHERE user_id = ? AND recorded_for >= DATE_SUB(UTC_DATE(), INTERVAL 6 DAY)
     GROUP BY recorded_for ORDER BY recorded_for`,
    [req.user.id],
  );
  const dailyKwh = calculateAverageDailyKwh(appliances);
  res.json({
    rate,
    applianceCount: appliances.length,
    estimatedDailyKwh: dailyKwh,
    estimatedMonthlyKwh: dailyKwh * 30,
    estimatedDailyCost: dailyKwh * Number(rate.rate),
    estimatedMonthlyCost: dailyKwh * Number(rate.rate) * 30,
    recordedLast30Days: {
      kwh: Number(recorded[0].recordedKwh),
      cost: Number(recorded[0].recordedCost),
      records: Number(recorded[0].recordCount),
    },
    lastSevenDays: daily,
  });
}));

router.get('/appliances', asyncRoute(async (req, res) => {
  const [rows] = await pool.execute(
    `SELECT id, name, category, wattage, daily_operating_hours AS dailyOperatingHours,
            operating_days AS operatingDays, is_on AS isOn, quantity,
            created_at AS createdAt, updated_at AS updatedAt
     FROM appliances WHERE user_id = ? ORDER BY created_at DESC, id DESC`,
    [req.user.id],
  );
  res.json({ appliances: rows });
}));

router.post('/appliances', asyncRoute(async (req, res) => {
  const appliance = validateAppliance(req.body);
  const [result] = await pool.execute(
    `INSERT INTO appliances (user_id, name, category, wattage, daily_operating_hours, operating_days, is_on, quantity)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [req.user.id, appliance.name, appliance.category, appliance.wattage, appliance.dailyOperatingHours,
      JSON.stringify(appliance.operatingDays), appliance.isOn, appliance.quantity],
  );
  res.status(201).json({ appliance: { id: result.insertId, ...appliance } });
}));

router.put('/appliances/:id', asyncRoute(async (req, res) => {
  const id = requireNumber(req.params.id, 'Appliance id', { min: 1 });
  const appliance = validateAppliance(req.body);
  const [result] = await pool.execute(
    `UPDATE appliances SET name = ?, category = ?, wattage = ?, daily_operating_hours = ?,
      operating_days = ?, is_on = ?, quantity = ? WHERE id = ? AND user_id = ?`,
    [appliance.name, appliance.category, appliance.wattage, appliance.dailyOperatingHours,
      JSON.stringify(appliance.operatingDays), appliance.isOn, appliance.quantity, id, req.user.id],
  );
  if (!result.affectedRows) throw new HttpError(404, 'Appliance not found.');
  res.json({ appliance: { id, ...appliance } });
}));

router.delete('/appliances/:id', asyncRoute(async (req, res) => {
  const id = requireNumber(req.params.id, 'Appliance id', { min: 1 });
  const [result] = await pool.execute('DELETE FROM appliances WHERE id = ? AND user_id = ?', [id, req.user.id]);
  if (!result.affectedRows) throw new HttpError(404, 'Appliance not found.');
  res.status(204).end();
}));

router.get('/consumption', asyncRoute(async (req, res) => {
  const { from, to } = dateRange(req.query);
  const { page, limit, offset } = pagination(req.query);
  const conditions = ['user_id = ?'];
  const params = [req.user.id];
  if (from) { conditions.push('recorded_for >= ?'); params.push(from); }
  if (to) { conditions.push('recorded_for <= ?'); params.push(to); }
  const where = conditions.join(' AND ');
  const [[countRows], [records]] = await Promise.all([
    pool.execute(`SELECT COUNT(*) AS total FROM consumption_records WHERE ${where}`, params),
    pool.execute(
      `SELECT id, appliance_id AS applianceId, appliance_name AS applianceName, wattage,
              operating_hours AS operatingHours, quantity, consumption_kwh AS kwh,
              rate_per_kwh AS rate, estimated_cost AS cost, recorded_for AS recordedFor, created_at AS createdAt
       FROM consumption_records WHERE ${where} ORDER BY recorded_for DESC, id DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset],
    ),
  ]);
  res.json({ records, page, limit, total: Number(countRows[0].total) });
}));

router.post('/consumption', asyncRoute(async (req, res) => {
  const date = req.body.recordedFor ?? new Date().toISOString().slice(0, 10);
  if (typeof date !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(date)
      || Number.isNaN(Date.parse(`${date}T00:00:00Z`))
      || new Date(`${date}T00:00:00Z`).toISOString().slice(0, 10) !== date) {
    throw new HttpError(400, 'recordedFor must be a valid YYYY-MM-DD date.');
  }
  const offset = timezoneOffsetMinutes(req.body.timezoneOffsetMinutes);
  if (date > dateAtOffset(offset)) throw new HttpError(400, 'Consumption records cannot be dated in the future.');
  if (!Array.isArray(req.body.entries) || req.body.entries.length < 1 || req.body.entries.length > 100) {
    throw new HttpError(400, 'Provide between 1 and 100 appliance entries.');
  }
  const ids = req.body.entries.map((entry) => requireNumber(entry.applianceId, 'Appliance id', { min: 1 }));
  if (new Set(ids).size !== ids.length) throw new HttpError(400, 'Each appliance can only be included once per record date.');
  const [appliances] = await pool.query(
    `SELECT id, name, wattage FROM appliances WHERE user_id = ? AND id IN (${ids.map(() => '?').join(',')})`,
    [req.user.id, ...ids],
  );
  const byId = new Map(appliances.map((appliance) => [Number(appliance.id), appliance]));
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const rate = await rateForDate(conn, date);
    const saved = [];
    for (const entry of req.body.entries) {
      const applianceId = Number(entry.applianceId);
      const appliance = byId.get(applianceId);
      if (!appliance) throw new HttpError(404, 'One or more appliances were not found.');
      const calculation = roundEntry(calculateEntry({
        wattage: appliance.wattage, hours: entry.hours, quantity: entry.quantity ?? 1, rate: rate.rate,
      }));
      const quantity = requireNumber(entry.quantity ?? 1, 'Quantity', { min: 1, max: 1000 });
      const hours = requireNumber(entry.hours, 'Operating hours', { min: 0, max: 24 });
      const [result] = await conn.execute(
        `INSERT INTO consumption_records
         (user_id, appliance_id, appliance_name, wattage, operating_hours, quantity, consumption_kwh,
          rate_id, rate_per_kwh, estimated_cost, recorded_for)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [req.user.id, applianceId, appliance.name, appliance.wattage, hours, quantity,
          calculation.kwh, rate.id, rate.rate, calculation.cost, date],
      );
      saved.push({ id: result.insertId, applianceId, applianceName: appliance.name, ...calculation, recordedFor: date });
    }
    await conn.commit();
    res.status(201).json({ records: saved, rate });
  } catch (error) {
    await conn.rollback();
    throw error;
  } finally {
    conn.release();
  }
}));

router.get('/simulation', asyncRoute(async (req, res) => {
  const [rows] = await pool.execute(
    `SELECT d.id AS dayId, d.day_number AS day, u.appliance_id AS applianceId,
            u.operating_hours AS hours, u.quantity, a.name AS applianceName, a.wattage
     FROM simulation_days d
     LEFT JOIN simulation_usages u ON u.simulation_day_id = d.id
     LEFT JOIN appliances a ON a.id = u.appliance_id
     WHERE d.user_id = ? ORDER BY d.day_number, u.appliance_id`,
    [req.user.id],
  );
  const days = new Map();
  for (const row of rows) {
    if (!days.has(row.dayId)) days.set(row.dayId, { day: row.day, usages: [] });
    if (row.applianceId !== null) days.get(row.dayId).usages.push({
      applianceId: row.applianceId, applianceName: row.applianceName, wattage: row.wattage,
      hours: row.hours, quantity: row.quantity,
    });
  }
  res.json({ days: [...days.values()] });
}));

router.put('/simulation/:day', asyncRoute(async (req, res) => {
  const day = requireNumber(req.params.day, 'Day', { min: 1, max: 31 });
  const entries = req.body.usages;
  if (!Array.isArray(entries) || entries.length > 100) throw new HttpError(400, 'usages must be an array of up to 100 entries.');
  const ids = entries.map((entry) => requireNumber(entry.applianceId, 'Appliance id', { min: 1 }));
  const [owned] = ids.length
    ? await pool.query(`SELECT id FROM appliances WHERE user_id = ? AND id IN (${ids.map(() => '?').join(',')})`, [req.user.id, ...ids])
    : [[]];
  if (owned.length !== new Set(ids).size) throw new HttpError(404, 'One or more appliances were not found.');
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [existing] = await conn.execute('SELECT id FROM simulation_days WHERE user_id = ? AND day_number = ? FOR UPDATE', [req.user.id, day]);
    let dayId = existing[0]?.id;
    if (!dayId) {
      const [created] = await conn.execute('INSERT INTO simulation_days (user_id, day_number) VALUES (?, ?)', [req.user.id, day]);
      dayId = created.insertId;
    } else {
      await conn.execute('DELETE FROM simulation_usages WHERE simulation_day_id = ?', [dayId]);
    }
    for (const entry of entries) {
      const hours = requireNumber(entry.hours, 'Operating hours', { min: 0, max: 24 });
      const quantity = requireNumber(entry.quantity ?? 1, 'Quantity', { min: 1, max: 1000 });
      await conn.execute(
        'INSERT INTO simulation_usages (simulation_day_id, appliance_id, operating_hours, quantity) VALUES (?, ?, ?, ?)',
        [dayId, entry.applianceId, hours, quantity],
      );
    }
    await conn.commit();
    res.json({ day, usages: entries });
  } catch (error) {
    await conn.rollback();
    throw error;
  } finally {
    conn.release();
  }
}));

router.delete('/simulation/:day', asyncRoute(async (req, res) => {
  const day = requireNumber(req.params.day, 'Day', { min: 1, max: 31 });
  await pool.execute('DELETE FROM simulation_days WHERE user_id = ? AND day_number = ?', [req.user.id, day]);
  res.status(204).end();
}));

export default router;
