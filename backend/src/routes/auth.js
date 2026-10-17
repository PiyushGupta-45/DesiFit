import bcrypt from 'bcryptjs';
import { OAuth2Client } from 'google-auth-library';
import { Router } from 'express';

import { config } from '../config.js';
import { User } from '../models/User.js';
import { UserData } from '../models/UserData.js';
import { authenticate } from '../middleware/auth.js';
import { emailPattern, issueToken, publicUser } from '../utils/auth.js';

const router = Router();
const google = new OAuth2Client();

const credentials = (body) => ({
  name: String(body.name || '').trim(),
  email: String(body.email || '').trim().toLowerCase(),
  password: String(body.password || ''),
});

router.post('/register', async (req, res, next) => {
  try {
    const { name, email, password } = credentials(req.body);
    if (!name || !emailPattern.test(email) || password.length < 8) {
      return res.status(400).json({ error: 'Name, valid email and an 8+ character password are required.' });
    }
    if (await User.exists({ email })) return res.status(409).json({ error: 'An account already exists for this email.' });

    const user = await User.create({ name, email, passwordHash: await bcrypt.hash(password, 12) });
    await UserData.create({ userId: user.id });
    return res.status(201).json({ token: issueToken(user), user: publicUser(user) });
  } catch (error) {
    return next(error);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = credentials(req.body);
    const user = await User.findOne({ email }).select('+passwordHash');
    if (!user?.passwordHash || !(await bcrypt.compare(password, user.passwordHash))) {
      return res.status(401).json({ error: 'Incorrect email or password.' });
    }
    return res.json({ token: issueToken(user), user: publicUser(user) });
  } catch (error) {
    return next(error);
  }
});

router.post('/google', async (req, res, next) => {
  try {
    if (!config.googleClientId) return res.status(503).json({ error: 'Google sign-in is not configured.' });
    const idToken = String(req.body.idToken || '');
    const ticket = await google.verifyIdToken({ idToken, audience: config.googleClientId });
    const payload = ticket.getPayload();
    if (!payload?.sub || !payload.email || !payload.email_verified) {
      return res.status(401).json({ error: 'Google account email could not be verified.' });
    }

    let user = await User.findOne({ $or: [{ googleId: payload.sub }, { email: payload.email.toLowerCase() }] });
    if (!user) {
      user = await User.create({
        name: payload.name || '', email: payload.email.toLowerCase(), googleId: payload.sub, avatarUrl: payload.picture || '',
      });
      await UserData.create({ userId: user.id });
    } else if (!user.googleId) {
      user.googleId = payload.sub;
      if (!user.avatarUrl && payload.picture) user.avatarUrl = payload.picture;
      await user.save();
    }
    return res.json({ token: issueToken(user), user: publicUser(user) });
  } catch (_) {
    return res.status(401).json({ error: 'Google sign-in token is invalid.' });
  }
});

router.get('/me', authenticate, async (req, res, next) => {
  try {
    const user = await User.findById(req.auth.sub).select('+passwordHash');
    if (!user) return res.status(404).json({ error: 'Account not found.' });
    return res.json({ user: publicUser(user) });
  } catch (error) {
    return next(error);
  }
});

router.put('/profile', authenticate, async (req, res, next) => {
  try {
    const name = String(req.body.name || '').trim();
    if (!name || name.length > 80) {
      return res.status(400).json({ error: 'Enter a name between 1 and 80 characters.' });
    }
    const user = await User.findByIdAndUpdate(req.auth.sub, { name }, { new: true }).select('+passwordHash');
    if (!user) return res.status(404).json({ error: 'Account not found.' });
    return res.json({ user: publicUser(user) });
  } catch (error) {
    return next(error);
  }
});

router.post('/password', authenticate, async (req, res, next) => {
  try {
    const currentPassword = String(req.body.currentPassword || '');
    const newPassword = String(req.body.newPassword || '');
    if (newPassword.length < 8) {
      return res.status(400).json({ error: 'New password must be at least 8 characters.' });
    }
    const user = await User.findById(req.auth.sub).select('+passwordHash');
    if (!user) return res.status(404).json({ error: 'Account not found.' });
    if (user.passwordHash && !(await bcrypt.compare(currentPassword, user.passwordHash))) {
      return res.status(401).json({ error: 'Current password is incorrect.' });
    }
    user.passwordHash = await bcrypt.hash(newPassword, 12);
    await user.save();
    return res.json({ user: publicUser(user), message: 'Password saved.' });
  } catch (error) {
    return next(error);
  }
});

export default router;
