import { Bill, Product, InventoryLog, StockType, PaymentMode, BillStatus } from '../../models';
import type { CreateBillInput, UpdateBillStatusInput } from './billing.schema';

export async function createBill(shopId: string, input: CreateBillInput) {
  const items: any[] = [];
  let subtotal = 0;

  for (const item of input.items) {
    const product = await Product.findOne({ _id: item.productId, shopId });
    if (!product) throw new Error(`Product not found: ${item.productId}`);
    if (product.stock < item.qty) throw new Error(`Insufficient stock for ${product.name}`);

    const total = product.mrp * item.qty;
    subtotal += total;

    items.push({
      productId: product._id,
      name: product.name,
      qty: item.qty,
      price: product.mrp,
      total,
    });

    // Deduct stock
    product.stock -= item.qty;
    await product.save();

    // Log the sale
    await InventoryLog.create({
      productId: product._id,
      type: StockType.SELL,
      qty: item.qty,
      note: 'Bill sale',
    });
  }

  const total = subtotal - (input.discount || 0);

  const bill = await Bill.create({
    shopId,
    customerId: input.customerId || undefined,
    items,
    subtotal,
    discount: input.discount || 0,
    total,
    paymentMode: input.paymentMode as PaymentMode,
    status: BillStatus.PAID,
  });

  return bill.toObject();
}

export async function listBills(shopId: string, opts: { from?: string; to?: string; customerId?: string }) {
  const filter: any = { shopId };
  if (opts.customerId) filter.customerId = opts.customerId;
  if (opts.from || opts.to) {
    filter.createdAt = {};
    if (opts.from) filter.createdAt.$gte = new Date(opts.from);
    if (opts.to) filter.createdAt.$lte = new Date(opts.to);
  }
  return Bill.find(filter).sort({ createdAt: -1 }).lean();
}

export async function getBill(billId: string, shopId: string) {
  const bill = await Bill.findOne({ _id: billId, shopId }).lean();
  if (!bill) throw new Error('Bill not found');
  return bill;
}

export async function updateBillStatus(billId: string, shopId: string, input: UpdateBillStatusInput) {
  const bill = await Bill.findOneAndUpdate(
    { _id: billId, shopId },
    { $set: { status: input.status as BillStatus } },
    { returnDocument: 'after' },
  ).lean();
  if (!bill) throw new Error('Bill not found');
  return bill;
}
