import { Customer, Transaction, Bill, BillStatus, TransactionType } from '../../models';
import type { CreateCustomerInput, UpdateCustomerInput, AddTransactionInput } from './customers.schema';

export async function listCustomers(shopId: string, search?: string) {
  const filter: any = { shopId };
  if (search) {
    filter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { phone: { $regex: search, $options: 'i' } },
    ];
  }
  return Customer.find(filter).sort({ createdAt: -1 }).lean();
}

export async function getCustomer(customerId: string, shopId: string) {
  const customer = await Customer.findOne({ _id: customerId, shopId }).lean();
  if (!customer) throw new Error('Customer not found');
  const transactions = await Transaction.find({ customerId })
    .sort({ createdAt: -1 })
    .limit(20)
    .lean();
  return { ...customer, transactions };
}

export async function createCustomer(shopId: string, input: CreateCustomerInput) {
  const existing = await Customer.findOne({ shopId, phone: input.phone });
  if (existing) throw new Error('A customer with this phone number already exists');
  return Customer.create({ ...input, shopId });
}

export async function updateCustomer(customerId: string, shopId: string, input: UpdateCustomerInput) {
  if (input.phone) {
    const existing = await Customer.findOne({
      shopId,
      phone: input.phone,
      _id: { $ne: customerId },
    });
    if (existing) throw new Error('Another customer with this phone number already exists');
  }
  const customer = await Customer.findOneAndUpdate(
    { _id: customerId, shopId },
    { $set: input },
    { returnDocument: 'after' },
  ).lean();
  if (!customer) throw new Error('Customer not found');
  return customer;
}

export async function deleteCustomer(customerId: string, shopId: string) {
  const customer = await Customer.findOneAndDelete({ _id: customerId, shopId });
  if (!customer) throw new Error('Customer not found');
  await Transaction.deleteMany({ customerId });
  return customer;
}

export async function addTransaction(customerId: string, shopId: string, input: AddTransactionInput) {
  const customer = await Customer.findOne({ _id: customerId, shopId });
  if (!customer) throw new Error('Customer not found');

  const transaction = await Transaction.create({
    shopId,
    customerId,
    type: input.type as TransactionType,
    amount: input.amount,
    note: input.note,
  });

  // Update customer balance: CREDIT increases balance (owes more), DEBIT decreases (pays back)
  if (input.type === 'CREDIT') {
    customer.balance += input.amount;
  } else {
    customer.balance -= input.amount;
  }
  await customer.save();

  return transaction.toObject();
}

export async function getTransactions(customerId: string, shopId: string) {
  const customer = await Customer.findOne({ _id: customerId, shopId });
  if (!customer) throw new Error('Customer not found');
  return Transaction.find({ customerId }).sort({ createdAt: -1 }).lean();
}

export async function getOutstandingSummary(shopId: string) {
  const customers = await Customer.find({ shopId }).lean();
  const totalOutstanding = customers.reduce((sum, c) => sum + (c.balance || 0), 0);
  const totalCustomers = customers.length;
  const customersWithDues = customers.filter((c) => (c.balance || 0) > 0).length;
  return { totalOutstanding, totalCustomers, customersWithDues };
}

export async function getCustomerBills(customerId: string, shopId: string) {
  const customer = await Customer.findOne({ _id: customerId, shopId });
  if (!customer) throw new Error('Customer not found');
  return Bill.find({ customerId, shopId }).sort({ createdAt: -1 }).lean();
}

export async function clearCustomerKhata(customerId: string, shopId: string) {
  const customer = await Customer.findOne({ _id: customerId, shopId });
  if (!customer) throw new Error('Customer not found');

  // Mark all pending bills as paid
  await Bill.updateMany(
    { customerId, shopId, status: BillStatus.PENDING },
    { $set: { status: BillStatus.PAID } },
  );

  // Create DEBIT transactions for each pending bill
  const pendingBills = await Bill.find({ customerId, shopId, status: BillStatus.PENDING }).lean();
  for (const bill of pendingBills) {
    await Transaction.create({
      shopId,
      customerId: customer._id,
      type: TransactionType.DEBIT,
      amount: bill.total,
      note: `Payment received for Bill #${bill._id}`,
    });
  }

  // Reset customer balance
  customer.balance = 0;
  await customer.save();

  return customer.toObject();
}
