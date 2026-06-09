import mongoose from 'mongoose';
import { env } from './env';

export async function connectDB() {
  try {
    const conn = await mongoose.connect(env.DATABASE_URL);
    console.log(`✅  MongoDB connected: ${conn.connection.host}`);
  } catch (error: any) {
    console.error(`❌  Error connecting to MongoDB: ${error.message}`);
    process.exit(1);
  }
}
