import mongoose from 'mongoose';

const userSchema = new mongoose.Schema(
  {
    name: { type: String, trim: true, maxlength: 80, default: '' },
    email: { type: String, required: true, trim: true, lowercase: true, unique: true },
    passwordHash: { type: String, select: false },
    googleId: { type: String, sparse: true, unique: true },
    avatarUrl: { type: String, default: '' },
  },
  { timestamps: true },
);

export const User = mongoose.model('User', userSchema);
