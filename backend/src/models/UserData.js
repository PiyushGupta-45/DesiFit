import mongoose from 'mongoose';

// App data is versioned as a single document so offline Flutter state can be
// uploaded/downloaded atomically without exposing any other user's records.
const userDataSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true, required: true },
    onboarded: { type: Boolean, default: false },
    profile: { type: mongoose.Schema.Types.Mixed, default: {} },
    diet: { type: [mongoose.Schema.Types.Mixed], default: [] },
    workouts: { type: [mongoose.Schema.Types.Mixed], default: [] },
    weightLogs: { type: [mongoose.Schema.Types.Mixed], default: [] },
    customFoods: { type: [mongoose.Schema.Types.Mixed], default: [] },
    reminders: { type: [mongoose.Schema.Types.Mixed], default: [] },
  },
  { timestamps: true, minimize: false },
);

export const UserData = mongoose.model('UserData', userDataSchema);
