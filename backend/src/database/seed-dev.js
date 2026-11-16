import bcrypt from 'bcrypt';
import { pool } from '../config/database.js';
import { requirePassword, requireValidEmail } from '../services/energy.js';
import { requireText } from '../utils/http.js';
import { insertMissingSampleAppliances } from './sample-appliances.js';

if (process.env.NODE_ENV !== 'development') {
  throw new Error('The development seed is disabled unless NODE_ENV=development.');
}

const accounts = [
  {
    name: requireText(process.env.ADMIN_NAME, 'ADMIN_NAME', 120),
    email: requireValidEmail(process.env.ADMIN_EMAIL),
    password: requirePassword(process.env.ADMIN_PASSWORD),
    role: 'admin',
  },
  {
    name: requireText(process.env.SAMPLE_USER_NAME, 'SAMPLE_USER_NAME', 120),
    email: requireValidEmail(process.env.SAMPLE_USER_EMAIL),
    password: requirePassword(process.env.SAMPLE_USER_PASSWORD),
    role: 'user',
  },
];

try {
  for (const account of accounts) {
    const passwordHash = await bcrypt.hash(account.password, 12);
    await pool.execute(
      `INSERT INTO users (full_name, email, password_hash, role)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE full_name = VALUES(full_name)`,
      [account.name, account.email, passwordHash, account.role],
    );
  }
  const [adminRows] = await pool.execute('SELECT role FROM users WHERE email = ?', [accounts[0].email]);
  if (adminRows[0]?.role !== 'admin') {
    throw new Error('The configured admin email belongs to a regular user; refusing to promote it automatically.');
  }
  const [sampleUsers] = await pool.execute('SELECT id FROM users WHERE email = ? AND role = ?', [accounts[1].email, 'user']);
  if (!sampleUsers[0]) throw new Error('The sample user email must not be assigned to an administrator account.');
  const sampleUserId = sampleUsers[0].id;
  const inserted = await insertMissingSampleAppliances(pool, sampleUserId);
  console.log(`Development admin and sample-user accounts are ready; added ${inserted} missing sample appliances.`);
} finally {
  await pool.end();
}
