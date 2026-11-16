import { app, sessionStore } from './app.js';
import { config } from './config/env.js';

const host = config.nodeEnv === 'production' ? '0.0.0.0' : '127.0.0.1';
const server = app.listen(config.port, host, () => {
  console.log(`CalWatt API listening on http://localhost:${config.port}`);
});

function shutdown() {
  server.close(() => {
    sessionStore.close(() => process.exit(0));
  });
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
