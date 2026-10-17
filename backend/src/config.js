import 'dotenv/config';

const required = ['MONGODB_URI', 'JWT_SECRET'];
for (const name of required) {
  if (!process.env[name]) throw new Error(`${name} is required. Copy .env.example to .env.`);
}

export const config = {
  port: Number(process.env.PORT || 8080),
  mongoUri: process.env.MONGODB_URI,
  jwtSecret: process.env.JWT_SECRET,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  googleClientId: process.env.GOOGLE_CLIENT_ID || '',
  corsOrigins: (process.env.CORS_ORIGINS || '*').split(',').map((value) => value.trim()),
};
