import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import mysql from 'mysql2/promise';
import { config } from '../config/env.js';

const migrationPath = fileURLToPath(new URL('./migrations/001_initial.sql', import.meta.url));
const connection = await mysql.createConnection({ ...config.database, multipleStatements: true, timezone: 'Z' });
try {
  const sql = await readFile(migrationPath, 'utf8');
  await connection.query(sql);
  await connection.execute(
    `INSERT INTO electricity_rates (rate_per_kwh, effective_at)
     SELECT 12.0000, UTC_TIMESTAMP(3)
     WHERE NOT EXISTS (SELECT 1 FROM electricity_rates)`,
  );
  console.log('Database migration completed successfully.');
} finally {
  await connection.end();
}
