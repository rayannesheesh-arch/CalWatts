import { Router } from 'express';
import { pool } from '../config/database.js';
import { requireAuth, requireRole } from '../middleware/auth.js';
import { currentRate } from '../services/rate.js';
import { asyncRoute, dateRange, HttpError, pagination, requireNumber } from '../utils/http.js';

const router = Router();
router.use(requireAuth, requireRole('admin'));

router.get('/dashboard', asyncRoute(async (_req, res) => {
  const [counts] = await pool.query(
    `SELECT (SELECT COUNT(*) FROM users WHERE role = 'user') AS users,
            (SELECT COUNT(*) FROM appliances) AS appliances,
            (SELECT COALESCE(SUM(consumption_kwh), 0) FROM consumption_records) AS recordedKwh,
            (SELECT COALESCE(SUM(estimated_cost), 0) FROM consumption_records) AS estimatedCost`,
  );
  const [daily] = await pool.query(
    `SELECT recorded_for AS day, SUM(consumption_kwh) AS kwh, SUM(estimated_cost) AS cost
     FROM consumption_records WHERE recorded_for >= DATE_SUB(UTC_DATE(), INTERVAL 29 DAY)
     GROUP BY recorded_for ORDER BY recorded_for`,
  );
  const [recent] = await pool.query(
    `SELECT l.id, l.action, l.entity_type AS entityType, l.entity_id AS entityId,
            l.details, l.created_at AS createdAt, u.full_name AS adminName
     FROM audit_logs l LEFT JOIN users u ON u.id = l.admin_id
     ORDER BY l.created_at DESC LIMIT 10`,
  );
  res.json({ totals: counts[0], last30Days: daily, recentActivity: recent });
}));

router.get('/users', asyncRoute(async (req, res) => {
  const { page, limit, offset } = pagination(req.query);
  const search = typeof req.query.search === 'string' ? req.query.search.trim().slice(0, 120) : '';
  const status = req.query.status === 'active' ? 1 : req.query.status === 'inactive' ? 0 : null;
  const where = ["role = 'user'"];
  const params = [];
  if (search) { where.push('(full_name LIKE ? OR email LIKE ?)'); params.push(`%${search}%`, `%${search}%`); }
  if (status !== null) { where.push('is_active = ?'); params.push(status); }
  const condition = where.join(' AND ');
  const [[countRows], [users]] = await Promise.all([
    pool.execute(`SELECT COUNT(*) AS total FROM users WHERE ${condition}`, params),
    pool.execute(
      `SELECT u.id, u.full_name AS fullName, u.email, u.is_active AS isActive, u.created_at AS createdAt,
              (SELECT COUNT(*) FROM appliances a WHERE a.user_id = u.id) AS applianceCount,
              (SELECT COALESCE(SUM(c.consumption_kwh), 0) FROM consumption_records c WHERE c.user_id = u.id) AS recordedKwh
       FROM users u WHERE ${condition} ORDER BY u.created_at DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset],
    ),
  ]);
  res.json({ users, page, limit, total: Number(countRows[0].total) });
}));

router.get('/users/:id', asyncRoute(async (req, res) => {
  const id = requireNumber(req.params.id, 'User id', { min: 1 });
  const [users] = await pool.execute(
    `SELECT id, full_name AS fullName, email, is_active AS isActive, created_at AS createdAt
     FROM users WHERE id = ? AND role = 'user'`,
    [id],
  );
  if (!users[0]) throw new HttpError(404, 'User not found.');
  const [[appliances], [records]] = await Promise.all([
    pool.execute(
      'SELECT id, name, category, wattage, daily_operating_hours AS dailyOperatingHours, is_on AS isOn, quantity FROM appliances WHERE user_id = ? ORDER BY name',
      [id],
    ),
    pool.execute(
      `SELECT id, appliance_name AS applianceName, consumption_kwh AS kwh, rate_per_kwh AS rate,
              estimated_cost AS cost, recorded_for AS recordedFor
       FROM consumption_records WHERE user_id = ? ORDER BY recorded_for DESC, id DESC LIMIT 50`,
      [id],
    ),
  ]);
  res.json({ user: users[0], appliances, recentRecords: records });
}));

router.put('/users/:id/status', asyncRoute(async (req, res) => {
  const id = requireNumber(req.params.id, 'User id', { min: 1 });
  if (typeof req.body.isActive !== 'boolean') throw new HttpError(400, 'isActive must be a boolean.');
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [result] = await connection.execute('UPDATE users SET is_active = ? WHERE id = ? AND role = ?', [req.body.isActive, id, 'user']);
    if (!result.affectedRows) throw new HttpError(404, 'User not found.');
    await connection.execute(
      'INSERT INTO audit_logs (admin_id, action, entity_type, entity_id) VALUES (?, ?, ?, ?)',
      [req.user.id, req.body.isActive ? 'user.activated' : 'user.deactivated', 'user', String(id)],
    );
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
  res.json({ id, isActive: req.body.isActive });
}));

router.get('/consumption', asyncRoute(async (req, res) => {
  const { from, to } = dateRange(req.query);
  const { page, limit, offset } = pagination(req.query);
  const conditions = ['1 = 1'];
  const params = [];
  if (from) { conditions.push('c.recorded_for >= ?'); params.push(from); }
  if (to) { conditions.push('c.recorded_for <= ?'); params.push(to); }
  if (req.query.userId) { conditions.push('c.user_id = ?'); params.push(requireNumber(req.query.userId, 'User id', { min: 1 })); }
  const where = conditions.join(' AND ');
  const [[countRows], [records]] = await Promise.all([
    pool.execute(`SELECT COUNT(*) AS total FROM consumption_records c WHERE ${where}`, params),
    pool.execute(
      `SELECT c.id, c.user_id AS userId, u.full_name AS fullName, u.email,
              c.appliance_name AS applianceName, c.wattage, c.operating_hours AS operatingHours,
              c.quantity, c.consumption_kwh AS kwh, c.rate_per_kwh AS rate, c.estimated_cost AS cost,
              c.recorded_for AS recordedFor
       FROM consumption_records c JOIN users u ON u.id = c.user_id
       WHERE ${where} ORDER BY c.recorded_for DESC, c.id DESC LIMIT ? OFFSET ?`,
      [...params, limit, offset],
    ),
  ]);
  res.json({ records, page, limit, total: Number(countRows[0].total) });
}));

router.get('/reports', asyncRoute(async (req, res) => {
  const { from, to } = dateRange(req.query);
  const conditions = ['1 = 1'];
  const params = [];
  if (from) { conditions.push('c.recorded_for >= ?'); params.push(from); }
  if (to) { conditions.push('c.recorded_for <= ?'); params.push(to); }
  const where = conditions.join(' AND ');
  const [[summary], [daily], [byAppliance], [records]] = await Promise.all([
    pool.execute(
      `SELECT COUNT(*) AS recordCount, COUNT(DISTINCT user_id) AS userCount,
              COALESCE(SUM(consumption_kwh), 0) AS totalKwh,
              COALESCE(SUM(estimated_cost), 0) AS totalCost
       FROM consumption_records c WHERE ${where}`, params,
    ),
    pool.execute(
      `SELECT c.recorded_for AS day, SUM(c.consumption_kwh) AS kwh, SUM(c.estimated_cost) AS cost
       FROM consumption_records c WHERE ${where} GROUP BY c.recorded_for ORDER BY c.recorded_for`, params,
    ),
    pool.execute(
      `SELECT c.appliance_name AS applianceName, SUM(c.consumption_kwh) AS kwh,
              SUM(c.estimated_cost) AS cost, COUNT(*) AS records
       FROM consumption_records c WHERE ${where} GROUP BY c.appliance_name ORDER BY kwh DESC LIMIT 100`,
      params,
    ),
    pool.execute(
      `SELECT c.recorded_for AS recordedFor, u.email, c.appliance_name AS applianceName,
              c.consumption_kwh AS kwh, c.rate_per_kwh AS rate, c.estimated_cost AS cost
       FROM consumption_records c JOIN users u ON u.id = c.user_id
       WHERE ${where} ORDER BY c.recorded_for DESC, c.id DESC LIMIT 5000`, params,
    ),
  ]);
  res.json({ summary: summary[0], daily, byAppliance, records, from, to });
}));

router.get('/rates', asyncRoute(async (_req, res) => {
  const [rates] = await pool.query(
    `SELECT r.id, r.rate_per_kwh AS rate, r.effective_at AS effectiveAt,
            u.full_name AS createdBy
     FROM electricity_rates r LEFT JOIN users u ON u.id = r.created_by
     ORDER BY r.effective_at DESC, r.id DESC`,
  );
  res.json({ current: await currentRate(), rates });
}));

router.post('/rates', asyncRoute(async (req, res) => {
  const rate = requireNumber(req.body.rate, 'Rate', { min: Number.EPSILON, max: 1000000 });
  const effectiveAt = req.body.effectiveAt ? new Date(req.body.effectiveAt) : new Date();
  if (Number.isNaN(effectiveAt.getTime())) throw new HttpError(400, 'effectiveAt must be a valid date.');
  if (effectiveAt.getTime() < Date.now() - 60000) throw new HttpError(400, 'A new rate must take effect now or in the future.');
  const connection = await pool.getConnection();
  let id;
  try {
    await connection.beginTransaction();
    const [existing] = await connection.execute(
      'SELECT id FROM electricity_rates WHERE effective_at = ? FOR UPDATE',
      [effectiveAt],
    );
    if (existing[0]) throw new HttpError(409, 'A rate already exists with that effective time.');
    const [result] = await connection.execute(
      'INSERT INTO electricity_rates (rate_per_kwh, effective_at, created_by) VALUES (?, ?, ?)',
      [rate, effectiveAt, req.user.id],
    );
    id = result.insertId;
    await connection.execute(
      'INSERT INTO audit_logs (admin_id, action, entity_type, entity_id, details) VALUES (?, ?, ?, ?, ?)',
      [req.user.id, 'rate.created', 'electricity_rate', String(id), JSON.stringify({ rate, effectiveAt: effectiveAt.toISOString() })],
    );
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
  res.status(201).json({ id, rate, effectiveAt });
}));

router.get('/audit-logs', asyncRoute(async (req, res) => {
  const { page, limit, offset } = pagination(req.query);
  const [[countRows], [logs]] = await Promise.all([
    pool.query('SELECT COUNT(*) AS total FROM audit_logs'),
    pool.execute(
      `SELECT l.id, l.action, l.entity_type AS entityType, l.entity_id AS entityId,
              l.details, l.created_at AS createdAt, u.full_name AS adminName
       FROM audit_logs l LEFT JOIN users u ON u.id = l.admin_id
       ORDER BY l.created_at DESC LIMIT ? OFFSET ?`,
      [limit, offset],
    ),
  ]);
  res.json({ logs, page, limit, total: Number(countRows[0].total) });
}));

export default router;
