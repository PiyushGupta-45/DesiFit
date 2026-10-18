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

## Global food catalogue

The app has an offline built-in food list, plus a MongoDB-backed global
catalogue. Apps fetch `GET /api/v1/foods` after sign-in and cache the result,
so foods added to this API appear without an APK update.

On every production start, `npm start` safely imports any *new* `_f(...)`
entry from `lib/data/foods.dart` into MongoDB. Existing database foods are not
overwritten. Therefore, a newly committed static food is inserted on the next
Render deploy; later catalogue-only additions can use the admin API below.

Set a separate, long random `ADMIN_FOOD_KEY` in the server/Render environment.
Never place it in Flutter's `config/app.env`.

| Method | URL | Access |
| --- | --- | --- |
| GET | `/api/v1/foods` | Public app catalogue fetch |
| POST | `/api/v1/foods` | `x-admin-food-key` required; creates or updates by name |
| PATCH | `/api/v1/foods/:id` | `x-admin-food-key` required |
| DELETE | `/api/v1/foods/:id` | `x-admin-food-key` required; deactivates the food |

Example admin request:

```bash
curl -X POST https://YOUR-API.onrender.com/api/v1/foods \
  -H "Content-Type: application/json" \
  -H "x-admin-food-key: YOUR_ADMIN_FOOD_KEY" \
  -d '{"name":"Oats Chilla","hindi":"ओट्स चीला","unit":"1 medium (80 g)","cat":"Tiffin","kcal":160,"p":7,"c":24,"f":4,"oil":0.5,"styles":["tawa","home"],"defaultStyle":"tawa"}'
```

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
