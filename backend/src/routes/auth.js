import { Router } from 'express';
import bcrypt from 'bcrypt';
import { pool } from '../config/database.js';
import { requireAuth } from '../middleware/auth.js';
import { requireCsrf, issueCsrfToken } from '../middleware/csrf.js';
import { requirePassword, requireValidEmail } from '../services/energy.js';
import { asyncRoute, HttpError, requireText } from '../utils/http.js';
import { insertMissingSampleAppliances } from '../database/sample-appliances.js';

const router = Router();

function regenerateSession(req) {
  return new Promise((resolve, reject) => {
    req.session.regenerate((error) => error ? reject(error) : resolve());
  });
}

router.get('/csrf', (req, res) => {
  res.json({ csrfToken: issueCsrfToken(req) });
});

router.get('/me', requireAuth, (req, res) => res.json({ user: req.user }));

router.post('/register', requireCsrf, asyncRoute(async (req, res) => {
  const fullName = requireText(req.body.fullName, 'Full name', 120);
  const email = requireValidEmail(req.body.email);
  const password = requirePassword(req.body.password);
  const passwordHash = await bcrypt.hash(password, 12);
  const connection = await pool.getConnection();
  let userId;
  try {
    await connection.beginTransaction();
    try {
      const [result] = await connection.execute(
        'INSERT INTO users (full_name, email, password_hash, role) VALUES (?, ?, ?, ?)',
        [fullName, email, passwordHash, 'user'],
      );
      userId = result.insertId;
    } catch (error) {
      if (error.code === 'ER_DUP_ENTRY') throw new HttpError(409, 'An account with that email already exists.');
      throw error;
    }
    await insertMissingSampleAppliances(connection, userId);
    await connection.commit();
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
  await regenerateSession(req);
  req.session.userId = userId;
  res.status(201).json({
    user: { id: userId, fullName, email, role: 'user', isActive: 1 },
  });
}));

router.post('/login', requireCsrf, asyncRoute(async (req, res) => {
  const email = requireValidEmail(req.body.email);
  const password = requirePassword(req.body.password);
  const [rows] = await pool.execute(
    'SELECT id, full_name AS fullName, email, password_hash AS passwordHash, role, is_active AS isActive FROM users WHERE email = ? LIMIT 1',
    [email],
  );
  const user = rows[0];
  if (!user || !user.isActive || !(await bcrypt.compare(password, user.passwordHash))) {
    throw new HttpError(401, 'Email or password is incorrect.');
  }
  await regenerateSession(req);
  req.session.userId = user.id;
  delete user.passwordHash;
  res.json({ user });
}));

router.post('/logout', requireCsrf, asyncRoute(async (req, res) => {
  if (req.session) {
    await new Promise((resolve, reject) => req.session.destroy((error) => error ? reject(error) : resolve()));
  }
  res.clearCookie('calwatts.sid');
  res.status(204).end();
}));

export default router;
