# Kirana Enterprise — Backend API

Node.js + Express + TypeScript + Prisma + PostgreSQL

## Quick Start

```bash
# 1. Install
npm install

# 2. Environment
cp .env.example .env
# Fill in: DATABASE_URL, JWT_SECRET

# 3. Database
npm run db:generate          # generate Prisma client
npm run db:migrate           # create tables

# 4. Run
npm run dev                  # hot reload on http://localhost:3000
```

## Environment Variables (.env)

```env
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://user:password@localhost:5432/kirana_db
JWT_SECRET=your-secret-min-16-chars
JWT_EXPIRES_IN=7d
CORS_ORIGINS=http://localhost:5173

# Optional - for logo/signature upload
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

## Free Database Setup (Supabase)

```
1. supabase.com → New Project
2. Settings → Database → Connection String (URI)
3. Paste into .env as DATABASE_URL
4. npm run db:migrate
```

## API Reference

> The API is mounted at both `/api` and `/` for convenience. Example: `/api/auth/login` and `/auth/login` both work.

### Auth (public)
```
POST /api/auth/register   { name, phone, password }
POST /api/auth/login      { phone, password }  → returns { user, token }
GET  /api/auth/me         Bearer token required
```

### Shop (protected)
```
GET    /api/shop
POST   /api/shop           { name, gstin, phone, email, address, pincode }
PATCH  /api/shop           any fields
POST   /api/shop/logo      multipart: logo (image)
DELETE /api/shop/logo
POST   /api/shop/signature multipart: signature (image)
DELETE /api/shop/signature
```

### Inventory (protected)
```
GET    /api/inventory              ?search=
GET    /api/inventory/low-stock
GET    /api/inventory/:id
POST   /api/inventory              { name, unit, mrp, costPrice, stock, lowStock }
PATCH  /api/inventory/:id          any fields
DELETE /api/inventory/:id
POST   /api/inventory/:id/stock    { type: ADD|SELL|ADJUST, qty, note? }
GET    /api/inventory/:id/logs
```

### Customers (protected)
```
GET    /api/customers              ?search=
GET    /api/customers/summary
GET    /api/customers/:id
POST   /api/customers              { name, phone, balance? }
PATCH  /api/customers/:id          any fields
DELETE /api/customers/:id
GET    /api/customers/:id/transactions
POST   /api/customers/:id/transactions  { type: CREDIT|DEBIT, amount, note? }
```

### Billing (protected)
```
GET    /api/bills                  ?from= &to= &customerId=
GET    /api/bills/:id
POST   /api/bills                  { items:[{productId,qty}], discount?, paymentMode, customerId? }
PATCH  /api/bills/:id/status       { status: PAID|PENDING|CANCELLED }
```

### Reports (protected)
```
GET    /api/reports/summary        ?period=daily|weekly|monthly|yearly
GET    /api/reports/chart          ?days=7
GET    /api/reports/top-products   ?limit=5
GET    /api/reports/stock-health
GET    /api/reports/khata
```

## Project Structure

```
src/
├── server.ts              # entry point
├── app.ts                 # Express setup
├── router.ts              # mounts all routes
├── config/
│   ├── env.ts             # Zod-validated env vars
│   └── prisma.ts          # Prisma client singleton
├── middleware/
│   ├── auth.middleware.ts # JWT Bearer verification
│   ├── error.middleware.ts# global error + Zod errors
│   └── upload.middleware.ts # Multer + Cloudinary
├── utils/
│   ├── response.ts        # ok/fail/created/notFound helpers
│   ├── jwt.ts             # signToken/verifyToken
│   ├── query.ts           # safe Express query param extraction
│   └── params.ts          # safe route param extraction
├── types/
│   └── index.ts           # shared TypeScript types
├── modules/
│   ├── auth/              # routes + controller + service + schema
│   ├── shop/              # routes + controller + service + schema
│   ├── inventory/         # routes + controller + service + schema
│   ├── customers/         # routes + controller + service + schema
│   ├── billing/           # routes + controller + service + schema
│   └── reports/           # routes + controller + service
└── prisma/
    └── schema.prisma      # 9 models: User, Shop, Product, Customer, Bill, BillItem, Transaction, InventoryLog + enums
```

## Scripts

```bash
npm run dev          # development (tsx watch)
npm run build        # compile TypeScript
npm run start        # run compiled dist/
npm run db:generate  # regenerate Prisma client
npm run db:migrate   # apply migrations
npm run db:studio    # visual DB browser
npm run db:push      # push schema (no migration file)
```

## Health Check

```
GET http://localhost:3000/health
→ { "status": "ok", "env": "development" }
```
