import bcrypt from 'bcrypt';
import { pool } from '../config/database.js';
import { requirePassword, requireValidEmail } from '../services/energy.js';
import { requireText } from '../utils/http.js';

const fullName = requireText(process.env.ADMIN_NAME, 'ADMIN_NAME', 120);
const email = requireValidEmail(process.env.ADMIN_EMAIL);
const password = requirePassword(process.env.ADMIN_PASSWORD);

try {
  const passwordHash = await bcrypt.hash(password, 12);
  await pool.execute(
    `INSERT INTO users (full_name, email, password_hash, role)
     VALUES (?, ?, ?, 'admin')
     ON DUPLICATE KEY UPDATE full_name = VALUES(full_name)`,
    [fullName, email, passwordHash],
  );
  const [rows] = await pool.execute('SELECT role FROM users WHERE email = ?', [email]);
  if (rows[0]?.role !== 'admin') {
    throw new Error('That email belongs to a non-admin account; refusing to promote it automatically.');
  }
  console.log(`Administrator account is ready for ${email}.`);
} finally {
  await pool.end();
}
