import test from 'node:test';
import assert from 'node:assert/strict';
import { MySqlSessionStore } from '../src/config/mysql-session-store.js';

test('stores and loads a server-side session as JSON', async () => {
  let savedData;
  const fakePool = {
    async execute(sql, params) {
      if (sql.startsWith('INSERT INTO user_sessions')) {
        savedData = { sessionId: params[0], expires: params[1], data: params[2] };
        return [{ affectedRows: 1 }];
      }
      if (sql.startsWith('SELECT data')) return [[{ data: savedData.data }]];
      if (sql.startsWith('DELETE FROM user_sessions')) return [{ affectedRows: 1 }];
      throw new Error(`Unexpected SQL in session store test: ${sql}`);
    },
  };
  const store = new MySqlSessionStore(fakePool, { cleanupIntervalMs: 60_000 });
  const session = { userId: 7, cookie: { maxAge: 60_000 } };
  await new Promise((resolve, reject) => store.set('session-id', session, (error) => error ? reject(error) : resolve()));
  const loaded = await new Promise((resolve, reject) => store.get('session-id', (error, value) => error ? reject(error) : resolve(value)));
  assert.deepEqual(loaded, session);
  assert.equal(savedData.sessionId, 'session-id');
  await new Promise((resolve, reject) => store.destroy('session-id', (error) => error ? reject(error) : resolve()));
  store.close();
});
