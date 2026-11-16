import { randomBytes, timingSafeEqual } from 'node:crypto';
import { HttpError } from '../utils/http.js';

export function issueCsrfToken(req) {
  if (!req.session.csrfToken) req.session.csrfToken = randomBytes(32).toString('hex');
  return req.session.csrfToken;
}

export function requireCsrf(req, _res, next) {
  if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) return next();
  const expected = req.session.csrfToken;
  const actual = req.get('x-csrf-token');
  if (!expected || !actual) return next(new HttpError(403, 'A valid CSRF token is required.'));
  const expectedBytes = Buffer.from(expected);
  const actualBytes = Buffer.from(actual);
  if (expectedBytes.length !== actualBytes.length || !timingSafeEqual(expectedBytes, actualBytes)) {
    return next(new HttpError(403, 'A valid CSRF token is required.'));
  }
  next();
}
