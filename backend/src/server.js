import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import mongoose from 'mongoose';

import { config } from './config.js';
import authRoutes from './routes/auth.js';
import dataRoutes from './routes/data.js';

const app = express();
app.disable('x-powered-by');
app.use(helmet());
app.use(cors({ origin: config.corsOrigins.includes('*') ? true : config.corsOrigins }));
app.use(express.json({ limit: '1mb' }));
app.use('/api/v1/auth', rateLimit({ windowMs: 15 * 60 * 1000, limit: 30, standardHeaders: true }), authRoutes);
app.use('/api/v1/data', dataRoutes);
app.get('/health', (_, res) => res.json({ ok: true }));

app.use((_, res) => res.status(404).json({ error: 'Route not found.' }));
app.use((error, _, res, __) => {
  console.error(error);
  res.status(500).json({ error: 'Internal server error.' });
});

mongoose
  .connect(config.mongoUri)
  .then(() => {
    console.log('MongoDB Atlas connected.');
    app.listen(config.port, '0.0.0.0', () =>
      console.log(`DesiFit API running on 0.0.0.0:${config.port}`),
    );
  })
  .catch((error) => {
    console.error('MongoDB connection failed:', error.message);
    process.exit(1);
  });
