import fs from 'node:fs/promises';
import path from 'node:path';

import mongoose from 'mongoose';

import { config } from '../src/config.js';
import { Food } from '../src/models/Food.js';

const styleSets = {
  _veg: ['home', 'tadka', 'restaurant', 'plain'],
  _dal: ['plain', 'home', 'tadka', 'restaurant'],
  _curry: ['home', 'tadka', 'restaurant', 'shallow'],
  _bread: ['tawa', 'home', 'tadka', 'shallow', 'restaurant'],
  _fry: ['deep', 'shallow', 'air', 'tawa'],
  _rice: ['plain', 'home', 'tadka', 'restaurant'],
  _tiffin: ['tawa', 'home', 'shallow', 'restaurant'],
  _steam: ['plain', 'home'],
  _grill: ['tandoor', 'air', 'shallow', 'deep', 'restaurant'],
  _raw: ['plain'],
  _sweet: ['plain', 'tadka'],
};

// Food declarations are intentionally kept in a simple single-line format in
// lib/data/foods.dart. This importer makes that file a deploy-time seed source
// without duplicating hundreds of records in a second hand-maintained file.
const foodPattern = /^\s*_f\('([^']*)',\s*'([^']*)',\s*'([^']*)',\s*'([^']*)',\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*(.+)\),\s*$/;

function parseFood(line) {
  const match = line.match(foodPattern);
  if (!match) return null;
  const [, name, hindi, unit, cat, kcal, p, c, f, oil, styleExpression] = match;
  const variable = Object.keys(styleSets).find((key) => styleExpression.startsWith(key));
  const inlineStyles = [...styleExpression.matchAll(/CookStyle\.(\w+)/g)].map((entry) => entry[1]);
  const availableStyles = variable ? styleSets[variable] : inlineStyles;
  if (!availableStyles.length) throw new Error(`No cooking styles parsed for ${name}`);
  const explicitDefault = styleExpression.match(/,\s*CookStyle\.(\w+)\s*$/)?.[1];
  return {
    name,
    nameKey: name.toLowerCase(),
    hindi,
    unit,
    cat,
    kcal: Number(kcal), p: Number(p), c: Number(c), f: Number(f), oil: Number(oil),
    styles: [...new Set(availableStyles)],
    defaultStyle: explicitDefault || availableStyles[0],
    // _f(..., CookStyle.plain, true) marks values as per 100 g in Dart.
    weightBased: /,\s*true\s*$/.test(styleExpression),
    active: true,
  };
}

async function main() {
  const source = path.resolve(process.cwd(), '..', 'lib', 'data', 'foods.dart');
  const lines = (await fs.readFile(source, 'utf8')).split(/\r?\n/);
  const foods = lines.map(parseFood).filter(Boolean);
  if (!foods.length) throw new Error(`No foods parsed from ${source}`);

  if (process.argv.includes('--check')) {
    console.log(`Parsed ${foods.length} foods from lib/data/foods.dart.`);
    return;
  }

  await mongoose.connect(config.mongoUri);
  await Food.bulkWrite(
    foods.map((food) => ({
      updateOne: {
        filter: { nameKey: food.nameKey },
        // Existing remote foods are never overwritten by a deploy. A new line
        // in foods.dart is inserted automatically on the next Render deploy.
        update: { $setOnInsert: food },
        upsert: true,
      },
    })),
    { ordered: false },
  );
  console.log(`Food catalogue seed checked: ${foods.length} built-in foods.`);
  await mongoose.disconnect();
}

main().catch(async (error) => {
  console.error('Food catalogue seed failed:', error.message);
  await mongoose.disconnect();
  process.exit(1);
});
