import { Store } from 'express-session';

export class MySqlSessionStore extends Store {
  constructor(pool, { cleanupIntervalMs = 15 * 60 * 1000 } = {}) {
    super();
    this.pool = pool;
    this.cleanupTimer = setInterval(() => {
      this.pool.execute('DELETE FROM user_sessions WHERE expires <= ?', [Math.floor(Date.now() / 1000)])
        .catch((error) => console.error('Unable to remove expired sessions:', error));
    }, cleanupIntervalMs);
    this.cleanupTimer.unref();
  }

  get(sessionId, callback) {
    this.pool.execute(
      'SELECT data FROM user_sessions WHERE session_id = ? AND expires > ?',
      [sessionId, Math.floor(Date.now() / 1000)],
    ).then(([rows]) => {
      callback(null, rows[0] ? JSON.parse(rows[0].data) : null);
    }).catch(callback);
  }

  set(sessionId, session, callback = () => {}) {
    const expires = session.cookie?.expires
      ? Math.floor(new Date(session.cookie.expires).getTime() / 1000)
      : Math.floor(Date.now() / 1000 + (session.cookie?.maxAge ?? 4 * 60 * 60 * 1000) / 1000);
    this.pool.execute(
      `INSERT INTO user_sessions (session_id, expires, data) VALUES (?, ?, ?)
       ON DUPLICATE KEY UPDATE expires = VALUES(expires), data = VALUES(data)`,
      [sessionId, expires, JSON.stringify(session)],
    ).then(() => callback()).catch(callback);
  }

  touch(sessionId, session, callback = () => {}) {
    const expires = session.cookie?.expires
      ? Math.floor(new Date(session.cookie.expires).getTime() / 1000)
      : Math.floor(Date.now() / 1000 + (session.cookie?.maxAge ?? 4 * 60 * 60 * 1000) / 1000);
    this.pool.execute('UPDATE user_sessions SET expires = ? WHERE session_id = ?', [expires, sessionId])
      .then(() => callback()).catch(callback);
  }

  destroy(sessionId, callback = () => {}) {
    this.pool.execute('DELETE FROM user_sessions WHERE session_id = ?', [sessionId])
      .then(() => callback()).catch(callback);
  }

  close(callback = () => {}) {
    clearInterval(this.cleanupTimer);
    callback();
  }
}
