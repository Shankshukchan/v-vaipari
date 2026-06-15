import { z } from 'zod';

export const registerSchema = z.object({
  name: z.string({ required_error: 'Name is required' }).min(2, 'Name must be at least 2 characters').max(60),
  email: z.string().email('Invalid email'),
  password: z.string({ required_error: 'Password is required' }).min(6, 'Password must be at least 6 characters'),
  shopName: z.string({ required_error: 'Shop name is required' }).min(1, 'Shop name is required').max(100),
  gstin: z.string().nullish(),
});

export const checkEmailSchema = z.object({
  email: z.string().email('Invalid email address'),
});

export const loginSchema = z.object({
  phone: z.string().min(10, 'Phone number must be at least 10 characters').optional(),
  email: z.string().email('Invalid email').optional(),
  password: z.string().min(6, 'Password must be at least 6 characters').optional(),
});

export const sendOtpSchema = z.object({
  email: z.string().email('Invalid email address'),
});

export const verifyOtpSchema = z.object({
  email: z.string().email('Invalid email address'),
  otp: z.string().min(4, 'OTP must be at least 4 digits'),
});

export const googleAuthSchema = z.object({
  idToken: z.string().min(1, 'ID Token is required'),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type SendOtpInput = z.infer<typeof sendOtpSchema>;
export type VerifyOtpInput = z.infer<typeof verifyOtpSchema>;
export type GoogleAuthInput = z.infer<typeof googleAuthSchema>;
export type CheckEmailInput = z.infer<typeof checkEmailSchema>;
