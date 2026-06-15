/**
 * Auth Routes
 * POST /api/auth/register  — create new owner account + return JWT
 * POST /api/auth/login     — verify credentials + return JWT
 * GET  /api/auth/me        — return current user profile (protected)
 */

import { Router } from 'express';
import { register, login, me, updateMe, sendOtpHandler, verifyOtpHandler, googleAuthHandler, checkEmailHandler } from './auth.controller';
import { authenticate } from '../../middleware/auth.middleware';

const router = Router();

router.post('/register',    register);
router.post('/login',       login);
router.post('/check-email', checkEmailHandler);
router.post('/send-otp',    sendOtpHandler);
router.post('/verify-otp',  verifyOtpHandler);
router.post('/google',      googleAuthHandler);

router.get('/me',        authenticate, me);
router.patch('/me',      authenticate, updateMe);

export default router;
