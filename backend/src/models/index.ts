import mongoose, { Schema, Document } from 'mongoose';

// ─── Enums ────────────────────────────────────────────────────────────────────
export enum Role {
  OWNER = 'OWNER',
  STAFF = 'STAFF',
}

export enum StockType {
  ADD = 'ADD',
  SELL = 'SELL',
  ADJUST = 'ADJUST',
}

export enum TransactionType {
  CREDIT = 'CREDIT',
  DEBIT = 'DEBIT',
}

export enum PaymentMode {
  CASH = 'CASH',
  UPI = 'UPI',
  CREDIT = 'CREDIT',
}

export enum BillStatus {
  PAID = 'PAID',
  PENDING = 'PENDING',
  CANCELLED = 'CANCELLED',
}

// ─── Schemas ──────────────────────────────────────────────────────────────────

const userSchema = new Schema({
  name: { type: String, required: true },
  phone: { type: String, unique: true, sparse: true },
  email: { type: String, unique: true, sparse: true },
  googleId: { type: String, unique: true, sparse: true },
  passwordHash: { type: String },
  role: { type: String, enum: Object.values(Role), default: Role.OWNER },
  shopId: { type: Schema.Types.ObjectId, ref: 'Shop' },
}, { timestamps: true });

const otpSchema = new Schema({
  email: { type: String, unique: true, required: true },
  code: { type: String, required: true },
  expiresAt: { type: Date, required: true },
}, { timestamps: true });

const shopSchema = new Schema({
  name: { type: String, required: true },
  gstin: { type: String },
  phone: { type: String },
  email: { type: String },
  address: { type: String },
  pincode: { type: String },
  logoUrl: { type: String },
  signatureUrl: { type: String },
  upiId: { type: String },
}, { timestamps: true });

const productSchema = new Schema({
  shopId: { type: Schema.Types.ObjectId, ref: 'Shop', required: true },
  name: { type: String, required: true },
  barcode: { type: String },
  category: { type: String, enum: ['Groceries', 'Snacks', 'Beverages', 'Others'], default: 'Others' },
  unit: { type: String, default: 'pcs' },
  mrp: { type: Number, required: true },
  costPrice: { type: Number, required: true },
  stock: { type: Number, default: 0 },
  lowStock: { type: Number, default: 5 },
}, { timestamps: true });

// Barcode must be unique per shop, not globally
productSchema.index({ shopId: 1, barcode: 1 }, { unique: true, sparse: true });

const inventoryLogSchema = new Schema({
  shopId: { type: Schema.Types.ObjectId, ref: 'Shop', required: true },
  productId: { type: Schema.Types.ObjectId, ref: 'Product', required: true },
  type: { type: String, enum: Object.values(StockType), required: true },
  qty: { type: Number, required: true },
  note: { type: String },
}, { timestamps: true });

const customerSchema = new Schema({
  shopId: { type: Schema.Types.ObjectId, ref: 'Shop', required: true },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  balance: { type: Number, default: 0 },
}, { timestamps: true });

customerSchema.index({ shopId: 1, phone: 1 }, { unique: true });

const transactionSchema = new Schema({
  shopId: { type: Schema.Types.ObjectId, ref: 'Shop', required: true },
  customerId: { type: Schema.Types.ObjectId, ref: 'Customer', required: true },
  type: { type: String, enum: Object.values(TransactionType), required: true },
  amount: { type: Number, required: true },
  note: { type: String },
}, { timestamps: true });

const billItemSchema = new Schema({
  productId: { type: Schema.Types.ObjectId, ref: 'Product', required: true },
  name: { type: String, required: true },
  qty: { type: Number, required: true },
  price: { type: Number, required: true },
  total: { type: Number, required: true },
}, { _id: false });

const billSchema = new Schema({
  shopId: { type: Schema.Types.ObjectId, ref: 'Shop', required: true },
  customerId: { type: Schema.Types.ObjectId, ref: 'Customer' },
  customerName: { type: String },
  customerPhone: { type: String },
  items: [billItemSchema],
  subtotal: { type: Number, required: true },
  discount: { type: Number, default: 0 },
  total: { type: Number, required: true },
  paymentMode: { type: String, enum: Object.values(PaymentMode), default: PaymentMode.CASH },
  status: { type: String, enum: Object.values(BillStatus), default: BillStatus.PAID },
}, { timestamps: true });

// ─── Models ───────────────────────────────────────────────────────────────────

export const User = mongoose.model('User', userSchema);
export const Otp = mongoose.model('Otp', otpSchema);
export const Shop = mongoose.model('Shop', shopSchema);
export const Product = mongoose.model('Product', productSchema);
export const InventoryLog = mongoose.model('InventoryLog', inventoryLogSchema);
export const Customer = mongoose.model('Customer', customerSchema);
export const Transaction = mongoose.model('Transaction', transactionSchema);
export const Bill = mongoose.model('Bill', billSchema);
