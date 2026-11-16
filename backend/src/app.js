import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import session from 'express-session';
import { rateLimit } from 'express-rate-limit';
import { config } from './config/env.js';
import { pool } from './config/database.js';
import { MySqlSessionStore } from './config/mysql-session-store.js';
import authRoutes from './routes/auth.js';
import userRoutes from './routes/user.js';
import adminRoutes from './routes/admin.js';
import { HttpError } from './utils/http.js';
import { requireCsrf } from './middleware/csrf.js';

const app = express();
const sessionStore = new MySqlSessionStore(pool);

app.disable('x-powered-by');
app.set('trust proxy', config.nodeEnv === 'production' ? 1 : false);
app.use(helmet());
app.use(cors({ origin: config.frontendOrigin, credentials: true }));
app.use(express.json({ limit: '100kb' }));
app.use(session({
  name: 'calwatts.sid',
  secret: config.sessionSecret,
  store: sessionStore,
  resave: false,
  saveUninitialized: false,
  rolling: true,
  cookie: {
    httpOnly: true,
    secure: config.cookieSecure,
    sameSite: 'lax',
    maxAge: 4 * 60 * 60 * 1000,
  },
}));

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
});
app.use('/api/auth/login', authLimiter);
app.use('/api/auth/register', authLimiter);

app.get('/api/health', async (_req, res, next) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: 'connected' });
  } catch (error) {
    next(error);
  }
});
app.use('/api/auth', authRoutes);
app.use('/api/admin', requireCsrf, adminRoutes);
app.use('/api', requireCsrf, userRoutes);
app.use((req, _res, next) => next(new HttpError(404, `Route not found: ${req.method} ${req.path}`)));
app.use((error, _req, res, _next) => {
  if (error.code === 'ER_NO_SUCH_TABLE' || error.code === 'ECONNREFUSED') {
    console.error('Database request failed:', error.message);
    return res.status(503).json({ error: 'The database is unavailable. Check the database setup and try again.' });
  }
  const status = Number.isInteger(error.status) ? error.status : 500;
  if (status >= 500) console.error(error);
  res.status(status).json({ error: status >= 500 ? 'An unexpected server error occurred.' : error.message });
});

export { app, sessionStore };
