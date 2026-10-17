import jwt from 'jsonwebtoken';

import { config } from '../config.js';

export function authenticate(req, res, next) {
  const header = req.get('authorization') || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'Authentication required.' });
  }

  try {
    req.auth = jwt.verify(token, config.jwtSecret);
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'Invalid or expired access token.' });
  }
}
