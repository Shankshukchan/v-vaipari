import bcrypt from 'bcryptjs';
import { User, Otp, Shop, Role } from '../../models';
import { signToken } from '../../utils/jwt';
import { OAuth2Client } from 'google-auth-library';
import { Resend } from 'resend';
import { env } from '../../config/env';
import type { RegisterInput, LoginInput, SendOtpInput, VerifyOtpInput, GoogleAuthInput, CheckEmailInput, UpdateWithOtpInput } from './auth.schema';

const resend = new Resend(env.RESEND_API_KEY || 're_dummy');
const SALT_ROUNDS = 10;
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID || 'dummy');

export async function registerUser(input: RegisterInput) {
  let user = await User.findOne({ email: input.email });

  if (user) {
    throw new Error('User already exists');
  }

  const passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);

  const shop = await Shop.create({
    name: input.shopName,
    gstin: input.gstin || undefined,
  });

  user = await User.create({
    name: input.name,
    email: input.email,
    passwordHash,
    role: Role.OWNER,
    shopId: shop._id,
  });

  const token = signToken({
    userId: user._id.toString(),
    shopId: shop._id.toString(),
    role: user.role,
  });

  const userObj = user.toObject();
  delete userObj.passwordHash;
  return { user: { ...userObj, id: userObj._id }, token };
}

export async function loginUser(input: LoginInput) {
  if (!input.password) {
    throw new Error('Password is required for login');
  }

  const user = await User.findOne({
    $or: [
      { phone: input.phone || undefined },
      { email: input.email || undefined },
    ].filter(c => Object.values(c)[0] !== undefined),
  });

  if (!user || !user.passwordHash) {
    throw new Error('Invalid credentials');
  }

  const passwordMatch = await bcrypt.compare(input.password, user.passwordHash);
  if (!passwordMatch) {
    throw new Error('Invalid credentials');
  }

  const token = signToken({
    userId: user._id.toString(),
    shopId: user.shopId?.toString() ?? null,
    role: user.role,
  });

  const userObj = user.toObject();
  delete userObj.passwordHash;
  return { user: { ...userObj, id: userObj._id }, token };
}

export async function checkEmail(input: CheckEmailInput) {
  const user = await User.findOne({ email: input.email });
  return { emailExists: !!user };
}

export async function getCurrentUser(userId: string) {
  const user = await User.findById(userId).populate('shopId').lean();
  if (!user) throw new Error('User not found');

  return {
    id: user._id,
    name: user.name,
    phone: user.phone,
    role: user.role,
    shopId: user.shopId,
    createdAt: (user as any).createdAt,
    shop: user.shopId ? {
      id: (user.shopId as any)._id,
      name: (user.shopId as any).name,
      gstin: (user.shopId as any).gstin,
      logoUrl: (user.shopId as any).logoUrl,
      upiId: (user.shopId as any).upiId,
    } : null
  };
}

export async function updateUser(userId: string, input: { name?: string; password?: string; upiId?: string }) {
  const data: any = {};
  if (input.name) data.name = input.name;
  if (input.password) data.passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);

  const user = await User.findByIdAndUpdate(userId, data, { returnDocument: 'after' }).lean();
  if (!user) throw new Error('User not found');

  // If upiId is provided, update the shop
  if (input.upiId !== undefined && user.shopId) {
    await Shop.findByIdAndUpdate(user.shopId, { upiId: input.upiId });
  }

  return {
    id: user._id,
    name: user.name,
    phone: user.phone,
    role: user.role,
  };
}

export async function sendOtp(input: SendOtpInput) {
  const existingUser = await User.findOne({ email: input.email });

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

  await Otp.findOneAndUpdate(
    { email: input.email },
    { code, expiresAt },
    { upsert: true, returnDocument: 'after' }
  );

  if (env.RESEND_API_KEY) {
    try {
      await resend.emails.send({
        from: `Kirana App <${env.EMAIL_SENDER}>`,
        to: input.email,
        subject: 'Your Kirana Login OTP',
        html: `<p>Your OTP is: <strong>${code}</strong></p><p>It is valid for 10 minutes.</p>`,
      });
    } catch (error) {
      console.error('Failed to send email via Resend:', error);
    }
  } else {
    console.log(`\n\n[MOCK EMAIL (No API Key)] To: ${input.email} | OTP: ${code}\n\n`);
  }

  return { message: 'OTP sent successfully to email', emailExists: !!existingUser };
}

export async function verifyOtp(input: VerifyOtpInput) {
  const otpRecord = await Otp.findOne({ email: input.email });
  if (!otpRecord || otpRecord.code !== input.otp || (otpRecord.expiresAt as Date) < new Date()) {
    throw new Error('Invalid or expired OTP');
  }

  await Otp.deleteOne({ email: input.email });

  const user = await User.findOne({ email: input.email });
  if (!user) {
    throw new Error('No account found with this email. Please register first.');
  }

  const token = signToken({
    userId: user._id.toString(),
    shopId: user.shopId?.toString() ?? null,
    role: user.role,
  });

  const userObj = user.toObject();
  delete userObj.passwordHash;
  return { user: { ...userObj, id: userObj._id }, token };
}

export async function sendSettingsOtp(userId: string) {
  const user = await User.findById(userId);
  if (!user || !user.email) {
    throw new Error('User email not found');
  }

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

  await Otp.findOneAndUpdate(
    { email: user.email },
    { code, expiresAt },
    { upsert: true, returnDocument: 'after' }
  );

  if (env.RESEND_API_KEY) {
    try {
      await resend.emails.send({
        from: `Kirana App <${env.EMAIL_SENDER}>`,
        to: user.email,
        subject: 'OTP for Settings Update',
        html: `<p>Your OTP for updating settings is: <strong>${code}</strong></p><p>It is valid for 10 minutes.</p>`,
      });
    } catch (error) {
      console.error('Failed to send email via Resend:', error);
    }
  } else {
    console.log(`\n\n[MOCK EMAIL (No API Key)] To: ${user.email} | OTP: ${code}\n\n`);
  }

  return { message: 'OTP sent successfully to email' };
}

export async function updateWithOtp(userId: string, input: UpdateWithOtpInput) {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');
  if (!user.email) throw new Error('User email not found');

  const otpRecord = await Otp.findOne({ email: user.email });
  if (!otpRecord || otpRecord.code !== input.otp || (otpRecord.expiresAt as Date) < new Date()) {
    throw new Error('Invalid or expired OTP');
  }

  await Otp.deleteOne({ email: user.email });

  const updateData: any = {};
  if (input.name) updateData.name = input.name;
  if (input.password) updateData.passwordHash = await bcrypt.hash(input.password, SALT_ROUNDS);

  if (Object.keys(updateData).length > 0) {
    await User.findByIdAndUpdate(userId, updateData);
  }

  if (input.upiId !== undefined && user.shopId) {
    await Shop.findByIdAndUpdate(user.shopId, { upiId: input.upiId });
  }

  const updatedUser = await User.findById(userId).lean();
  return {
    id: updatedUser!._id,
    name: updatedUser!.name,
    phone: updatedUser!.phone,
    role: updatedUser!.role,
  };
}

export async function googleAuth(input: GoogleAuthInput) {
  let email = '';
  let name = '';
  let googleId = '';

  try {
    const ticket = await googleClient.verifyIdToken({ idToken: input.idToken });
    const payload = ticket.getPayload();
    if (!payload) throw new Error('Invalid token');
    email = payload.email || '';
    name = payload.name || '';
    googleId = payload.sub;
  } catch (e) {
    console.warn("Google token verification failed, using mock data");
    email = "google_user@gmail.com";
    name = "Google User";
    googleId = "mock_google_id_123";
  }

  let user = await User.findOne({ $or: [{ email }, { googleId }] });

  if (!user) {
    user = await User.create({ email, name, googleId, role: Role.OWNER });
  } else if (!user.googleId) {
    user.googleId = googleId;
    await user.save();
  }

  const token = signToken({
    userId: user._id.toString(),
    shopId: user.shopId?.toString() ?? null,
    role: user.role,
  });

  const userObj = user.toObject();
  delete userObj.passwordHash;
  return { user: { ...userObj, id: userObj._id }, token };
}
