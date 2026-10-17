import jwt from 'jsonwebtoken';

import { config } from '../config.js';

export const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function issueToken(user) {
  return jwt.sign({ sub: user.id, email: user.email }, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn,
  });
}

export function publicUser(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    avatarUrl: user.avatarUrl || '',
    hasPassword: Boolean(user.passwordHash),
    createdAt: user.createdAt,
  };
}
