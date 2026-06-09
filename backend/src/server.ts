import app from './app';
import { env } from './config/env';
import { connectDB } from './config/db';

async function main() {
  // Verify DB connection before accepting traffic
  await connectDB();

  app.listen(env.PORT, () => {
    console.log(`🚀  Server running on http://localhost:${env.PORT}`);
    console.log(`📦  Environment: ${env.NODE_ENV}`);
  });
}

main().catch((err) => {
  console.error('❌  Failed to start server :', err);
  process.exit(1);
});
