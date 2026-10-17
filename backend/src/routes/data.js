import { Router } from 'express';

import { authenticate } from '../middleware/auth.js';
import { UserData } from '../models/UserData.js';

const router = Router();
const allowed = ['onboarded', 'profile', 'diet', 'workouts', 'weightLogs', 'customFoods', 'reminders'];

router.use(authenticate);

router.get('/', async (req, res, next) => {
  try {
    const data = await UserData.findOneAndUpdate(
      { userId: req.auth.sub },
      { $setOnInsert: { userId: req.auth.sub } },
      { upsert: true, new: true },
    ).lean();
    return res.json({ data, updatedAt: data.updatedAt });
  } catch (error) {
    return next(error);
  }
});

router.put('/', async (req, res, next) => {
  try {
    const update = {};
    for (const key of allowed) {
      if (Object.hasOwn(req.body, key)) update[key] = req.body[key];
    }
    if (Object.keys(update).length === 0) return res.status(400).json({ error: 'No app data was supplied.' });
    for (const key of ['diet', 'workouts', 'weightLogs', 'customFoods', 'reminders']) {
      if (key in update && !Array.isArray(update[key])) return res.status(400).json({ error: `${key} must be an array.` });
    }
    const data = await UserData.findOneAndUpdate(
      { userId: req.auth.sub },
      { $set: update, $setOnInsert: { userId: req.auth.sub } },
      { upsert: true, new: true, runValidators: true },
    ).lean();
    return res.json({ data, updatedAt: data.updatedAt });
  } catch (error) {
    return next(error);
  }
});

export default router;
