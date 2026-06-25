/**
 * auth.controller.ts
 * ─────────────────────────────────────────────────────────────────────────────
 * Handles HTTP layer only — validates input, calls service, sends response.
 */

import type { Request, Response } from 'express';
import { registerSchema, loginSchema, sendOtpSchema, verifyOtpSchema, googleAuthSchema, checkEmailSchema, updateWithOtpSchema } from './auth.schema';
import { registerUser, loginUser, getCurrentUser, updateUser, sendOtp, verifyOtp, googleAuth, checkEmail, sendSettingsOtp, updateWithOtp } from './auth.service';
import { ok, created, fail, serverError } from '../../utils/response';

// POST /api/auth/register
export async function register(req: Request, res: Response) {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    fail(res, 'Validation failed');
    return;
  }

  try {
    const result = await registerUser(parsed.data);
    created(res, result);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Registration failed';
    fail(res, message);
  }
}

// POST /api/auth/login
export async function login(req: Request, res: Response) {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    fail(res, 'Validation failed');
    return;
  }

  try {
    const result = await loginUser(parsed.data);
    ok(res, result);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Login failed';
    fail(res, message, 401);
  }
}

export async function me(req: Request, res: Response) {
  try {
    const user = await getCurrentUser(req.user!.userId);
    ok(res, user);
  } catch (err) {
    serverError(res);
  }
}

// PATCH /api/auth/me
export async function updateMe(req: Request, res: Response) {
  try {
    const user = await updateUser(req.user!.userId, req.body);
    ok(res, user);
  } catch (err) {
    serverError(res);
  }
}

// POST /api/auth/check-email
export async function checkEmailHandler(req: Request, res: Response) {
  const parsed = checkEmailSchema.safeParse(req.body);
  if (!parsed.success) {
    fail(res, 'Validation failed');
    return;
  }

  try {
    const result = await checkEmail(parsed.data);
    ok(res, result);
  } catch (err: any) {
    fail(res, err.message);
  }
}

// POST /api/auth/send-otp
export async function sendOtpHandler(req: Request, res: Response) {
  try {
    const result = await sendOtp(req.body);
    ok(res, result);
  } catch (err: any) {
    fail(res, err.message);
  }
}

// POST /api/auth/verify-otp
export async function verifyOtpHandler(req: Request, res: Response) {
  try {
    const result = await verifyOtp(req.body);
    ok(res, result);
  } catch (err: any) {
    fail(res, err.message);
  }
}

// POST /api/auth/send-settings-otp
export async function sendSettingsOtpHandler(req: Request, res: Response) {
  try {
    const result = await sendSettingsOtp(req.user!.userId);
    ok(res, result);
  } catch (err: any) {
    fail(res, err.message);
  }
}

// POST /api/auth/update-with-otp
export async function updateWithOtpHandler(req: Request, res: Response) {
  const parsed = updateWithOtpSchema.safeParse(req.body);
  if (!parsed.success) {
    fail(res, 'Validation failed');
    return;
  }

  try {
    const result = await updateWithOtp(req.user!.userId, parsed.data);
    ok(res, result);
  } catch (err: any) {
    fail(res, err.message);
  }
}

// POST /api/auth/google
export async function googleAuthHandler(req: Request, res: Response) {
  try {
    const result = await googleAuth(req.body);
    ok(res, result);
  } catch (err: any) {
    fail(res, err.message);
  }
}
