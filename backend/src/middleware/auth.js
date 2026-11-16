import { pool } from '../config/database.js';
import { asyncRoute, HttpError } from '../utils/http.js';

export const requireAuth = asyncRoute(async (req, _res, next) => {
  if (!req.session.userId) throw new HttpError(401, 'Please sign in.');
  const [rows] = await pool.execute(
    'SELECT id, full_name AS fullName, email, role, is_active AS isActive FROM users WHERE id = ?',
    [req.session.userId],
  );
  const user = rows[0];
  if (!user || !user.isActive) {
    req.session.destroy(() => {});
    throw new HttpError(401, 'This account is unavailable. Please sign in again.');
  }
  req.user = user;
  next();
});

export function requireRole(role) {
  return (req, _res, next) => {
    if (req.user?.role !== role) return next(new HttpError(403, 'You do not have permission to do that.'));
    next();
  };
}
