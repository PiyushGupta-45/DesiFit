import { timingSafeEqual } from 'node:crypto';

import { Router } from 'express';

import { config } from '../config.js';
import { Food } from '../models/Food.js';

const router = Router();
const styles = new Set(['plain', 'tawa', 'tandoor', 'air', 'home', 'tadka', 'shallow', 'restaurant', 'deep']);

function allowedAdmin(req, res, next) {
  const supplied = Buffer.from(req.get('x-admin-food-key') || '');
  const expected = Buffer.from(config.adminFoodKey || '');
  if (!expected.length || supplied.length !== expected.length || !timingSafeEqual(supplied, expected)) {
    return res.status(403).json({ error: 'Food catalogue admin access denied.' });
  }
  return next();
}

function number(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function normaliseFood(body) {
  const name = String(body.name || '').trim();
  if (name.length < 2 || name.length > 100) throw new Error('Food name must be between 2 and 100 characters.');
  const selectedStyles = [...new Set((Array.isArray(body.styles) ? body.styles : [])
    .map((style) => String(style))
    .filter((style) => styles.has(style)))];
  const safeStyles = selectedStyles.length ? selectedStyles : ['plain'];
  const defaultStyle = safeStyles.includes(String(body.defaultStyle))
    ? String(body.defaultStyle)
    : safeStyles[0];
  return {
    name,
    nameKey: name.toLowerCase(),
    hindi: String(body.hindi || '').trim(),
    unit: String(body.unit || '1 serving').trim(),
    cat: String(body.cat || 'Other').trim(),
    kcal: number(body.kcal),
    p: number(body.p), c: number(body.c), f: number(body.f), oil: number(body.oil),
    styles: safeStyles,
    defaultStyle,
    weightBased: body.weightBased === true,
    active: body.active !== false,
  };
}

// The app can read active catalogue entries without authentication so the
// search catalogue stays available independently from a user's cloud data.
router.get('/', async (_req, res, next) => {
  try {
    const foods = await Food.find({ active: true }).sort({ name: 1 }).lean();
    return res.json({ foods });
  } catch (error) {
    return next(error);
  }
});

// Add or update by name. This endpoint is intentionally protected by a
// server-only ADMIN_FOOD_KEY; never put this key in the Flutter app.
router.post('/', allowedAdmin, async (req, res, next) => {
  try {
    const food = normaliseFood(req.body);
    const saved = await Food.findOneAndUpdate(
      { nameKey: food.nameKey },
      { $set: food },
      { new: true, upsert: true, runValidators: true, setDefaultsOnInsert: true },
    ).lean();
    return res.status(200).json({ food: saved });
  } catch (error) {
    if (error.message) return res.status(400).json({ error: error.message });
    return next(error);
  }
});

router.patch('/:id', allowedAdmin, async (req, res, next) => {
  try {
    const food = normaliseFood(req.body);
    const saved = await Food.findByIdAndUpdate(req.params.id, { $set: food }, { new: true, runValidators: true }).lean();
    if (!saved) return res.status(404).json({ error: 'Food not found.' });
    return res.json({ food: saved });
  } catch (error) {
    if (error.message) return res.status(400).json({ error: error.message });
    return next(error);
  }
});

router.delete('/:id', allowedAdmin, async (req, res, next) => {
  try {
    const food = await Food.findByIdAndUpdate(req.params.id, { active: false }, { new: true }).lean();
    if (!food) return res.status(404).json({ error: 'Food not found.' });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

export default router;
