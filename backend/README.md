# DesiFit backend

Node.js API for email/password login, Google Sign-In, JWT authentication and per-user DesiFit data sync in MongoDB Atlas.

## Setup

1. Install Node.js 20+.
2. Copy `.env.example` to `.env` and fill in `MONGODB_URI`, `JWT_SECRET`, and `GOOGLE_CLIENT_ID`.
3. In MongoDB Atlas, create a database user and allow the IP address of this API server under **Network Access**.
4. Run:

   ```bash
   cd backend
   npm install
   npm run dev
   ```

Health check: `GET http://localhost:8080/health`

## Auth API

| Method | URL | Body |
| --- | --- | --- |
| POST | `/api/v1/auth/register` | `{ "name", "email", "password" }` |
| POST | `/api/v1/auth/login` | `{ "email", "password" }` |
| POST | `/api/v1/auth/google` | `{ "idToken" }` |
| GET | `/api/v1/auth/me` | `Authorization: Bearer <jwt>` |

`register`, `login`, and `google` return `{ token, user }`. Store the token in Flutter Secure Storage, not SharedPreferences.

## App-data sync API

All routes below require `Authorization: Bearer <jwt>`.

| Method | URL | Purpose |
| --- | --- | --- |
| GET | `/api/v1/data` | Download the signed-in user's profile, food logs, workouts, weight logs, custom foods and reminders. |
| PUT | `/api/v1/data` | Upload any or all of `profile`, `diet`, `workouts`, `weightLogs`, `customFoods`, `reminders`. |

The API document is isolated by JWT user id—one user cannot request another user's data. For production, deploy this API over HTTPS (Render/Railway/Fly.io/VPS), set `CORS_ORIGINS` to your real domain, and make a strong unique `JWT_SECRET`.
