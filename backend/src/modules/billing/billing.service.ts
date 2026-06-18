import { Bill, Product, InventoryLog, Customer, Transaction, StockType, PaymentMode, BillStatus, TransactionType } from '../../models';
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
      shopId,
      productId: product._id,
      type: StockType.SELL,
      qty: item.qty,
      note: 'Bill sale',
    });
  }

  const total = subtotal - (input.discount || 0);
  const paymentMode = (input.paymentMode || 'CASH') as PaymentMode;

  // For CREDIT: find or create customer and link to bill
  let linkedCustomerId = input.customerId || undefined;
  if (linkedCustomerId) {
    const existingCustomer = await Customer.findOne({ _id: linkedCustomerId, shopId });
    if (!existingCustomer) throw new Error('Customer not found or does not belong to this shop');
    linkedCustomerId = existingCustomer._id.toString();
  }
  if (paymentMode === PaymentMode.CREDIT && input.customerPhone) {
    let customer = await Customer.findOne({ shopId, phone: input.customerPhone });
    if (!customer) {
      customer = await Customer.create({
        shopId,
        name: input.customerName || 'Walk-in',
        phone: input.customerPhone,
        balance: 0,
      });
    }
    linkedCustomerId = customer._id.toString();
  }

  const bill = await Bill.create({
    shopId,
    customerId: linkedCustomerId,
    customerName: input.customerName || undefined,
    customerPhone: input.customerPhone || undefined,
    items,
    subtotal,
    discount: input.discount || 0,
    total,
    paymentMode,
    status: paymentMode === PaymentMode.CREDIT ? BillStatus.PENDING : BillStatus.PAID,
  });

  // If CREDIT payment, create a CREDIT transaction for the customer
  if (paymentMode === PaymentMode.CREDIT && linkedCustomerId) {
    const customer = await Customer.findOne({ _id: linkedCustomerId, shopId });
    if (customer) {
      await Transaction.create({
        shopId,
        customerId: customer._id,
        type: TransactionType.CREDIT,
        amount: total,
        note: `Bill #${bill._id}`,
      });
      customer.balance += total;
      await customer.save();
    }
  }

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
  const bill = await Bill.findOne({ _id: billId, shopId });
  if (!bill) throw new Error('Bill not found');

  const oldStatus = bill.status;
  bill.status = input.status as BillStatus;
  await bill.save();

  // If changing from PENDING (CREDIT) to PAID, create a DEBIT transaction for the customer
  if (oldStatus === BillStatus.PENDING && input.status === 'PAID' && bill.customerId) {
    const customer = await Customer.findOne({ _id: bill.customerId, shopId });
    if (customer) {
      await Transaction.create({
        shopId,
        customerId: customer._id,
        type: TransactionType.DEBIT,
        amount: bill.total,
        note: `Payment received for Bill #${bill._id}`,
      });
      customer.balance -= bill.total;
      await customer.save();
    }
  }

  return bill.toObject();
}

export async function deleteBill(billId: string, shopId: string) {
  const bill = await Bill.findOne({ _id: billId, shopId });
  if (!bill) throw new Error('Bill not found');

  // Restore stock for each item
  for (const item of bill.items || []) {
    const product = await Product.findOne({ _id: item.productId, shopId });
    if (product) {
      product.stock += item.qty || 0;
      await product.save();

      await InventoryLog.create({
        shopId,
        productId: product._id,
        type: StockType.SELL,
        qty: -(item.qty || 0),
        note: 'Bill deleted - stock restored',
      });
    }
  }

  // If CREDIT bill, reverse the balance on the customer
  if (bill.paymentMode === PaymentMode.CREDIT && bill.customerId) {
    const customer = await Customer.findOne({ _id: bill.customerId, shopId });
    if (customer) {
      await Transaction.create({
        shopId,
        customerId: customer._id,
        type: TransactionType.DEBIT,
        amount: bill.total,
        note: `Bill #${bill._id} deleted`,
      });
      customer.balance -= bill.total;
      await customer.save();
    }
  }

  await Bill.deleteOne({ _id: billId, shopId });
  return { deleted: true };
}
