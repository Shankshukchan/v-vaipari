import express from 'express';
import cors from 'cors';
import { env } from './config/env';
import api from './router';
import { errorMiddleware } from './middleware/error.middleware';

const app = express();

// ── Core middleware ───────────────────────────────────────────────────────────
app.use(cors({
  origin: function (origin, callback) {
    if (!origin || env.NODE_ENV === 'development') {
      callback(null, true);
    } else {
      const allowedOrigins = env.CORS_ORIGINS.split(',').map((o) => o.trim());
      if (allowedOrigins.indexOf(origin) !== -1) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    }
  },
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', env: env.NODE_ENV });
});

// ── API routes ────────────────────────────────────────────────────────────────
app.use(['/api', '/'], api);

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    method: req.method,
    path: req.originalUrl,
  });
});

// ── Global error handler ──────────────────────────────────────────────────────
app.use(errorMiddleware);

export default app;
