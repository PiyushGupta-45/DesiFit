import mongoose from 'mongoose';

const foodSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true, maxlength: 100 },
    nameKey: { type: String, required: true, unique: true, index: true },
    hindi: { type: String, trim: true, default: '', maxlength: 160 },
    unit: { type: String, trim: true, default: '1 serving', maxlength: 100 },
    cat: { type: String, trim: true, default: 'Other', maxlength: 50 },
    kcal: { type: Number, required: true, min: 0, max: 5000 },
    p: { type: Number, default: 0, min: 0, max: 1000 },
    c: { type: Number, default: 0, min: 0, max: 1000 },
    f: { type: Number, default: 0, min: 0, max: 1000 },
    oil: { type: Number, default: 0, min: 0, max: 2 },
    styles: { type: [String], default: ['plain'] },
    defaultStyle: { type: String, default: 'plain' },
    weightBased: { type: Boolean, default: false },
    active: { type: Boolean, default: true, index: true },
  },
  { timestamps: true, versionKey: false },
);

export const Food = mongoose.model('Food', foodSchema);
