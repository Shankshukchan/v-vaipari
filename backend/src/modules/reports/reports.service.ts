import { Bill, Product, Customer, Transaction, BillStatus } from '../../models';

function periodRange(period: string): { from: Date; to: Date } {
  const to = new Date();
  const from = new Date();
  switch (period) {
    case 'daily':
      from.setDate(from.getDate() - 1);
      break;
    case 'weekly':
      from.setDate(from.getDate() - 7);
      break;
    case 'monthly':
      from.setMonth(from.getMonth() - 1);
      break;
    case 'yearly':
      from.setFullYear(from.getFullYear() - 1);
      break;
    default:
      from.setMonth(from.getMonth() - 1);
  }
  return { from, to };
}

export async function getSalesSummary(shopId: string, period: string) {
  const { from, to } = periodRange(period);
  const prevFrom = new Date(from);
  const prevTo = new Date(from);

  // Current period bills
  const bills = await Bill.find({
    shopId,
    createdAt: { $gte: from, $lte: to },
    status: { $ne: BillStatus.CANCELLED },
  }).lean();

  // Previous period bills for comparison
  const prevBills = await Bill.find({
    shopId,
    createdAt: { $gte: prevFrom, $lte: prevTo },
    status: { $ne: BillStatus.CANCELLED },
  }).lean();

  const totalRevenue = bills.reduce((sum, b) => sum + (b.total || 0), 0);
  const totalBills = bills.length;
  const avgBill = totalBills > 0 ? totalRevenue / totalBills : 0;

  const prevRevenue = prevBills.reduce((sum, b) => sum + (b.total || 0), 0);
  const revenueChange = prevRevenue > 0
    ? ((totalRevenue - prevRevenue) / prevRevenue * 100).toFixed(1)
    : '0';

  // Total products
  const productsCount = await Product.countDocuments({ shopId });

  // Low stock
  const lowStockCount = await Product.countDocuments({
    shopId,
    $expr: { $lte: ['$stock', '$lowStock'] },
  });

  // Outstanding credit
  const customersWithDues = await Customer.find({ shopId, balance: { $gt: 0 } }).lean();
  const creditPending = customersWithDues.reduce((sum, c) => sum + (c.balance || 0), 0);

  return {
    totalRevenue,
    totalBills,
    avgBill: Math.round(avgBill),
    revenueChange: `${revenueChange}%`,
    productsCount,
    lowStockCount,
    creditPending,
    customersWithDues: customersWithDues.length,
    period,
  };
}

export async function getDailyChart(shopId: string, days: number) {
  const from = new Date();
  from.setDate(from.getDate() - days);

  const bills = await Bill.find({
    shopId,
    createdAt: { $gte: from },
    status: { $ne: BillStatus.CANCELLED },
  }).lean();

  // Group by day
  const dailyMap: Record<string, number> = {};
  for (let i = 0; i < days; i++) {
    const d = new Date();
    d.setDate(d.getDate() - (days - 1 - i));
    const key = d.toISOString().split('T')[0];
    dailyMap[key] = 0;
  }

  for (const bill of bills) {
    const key = (bill.createdAt as Date).toISOString().split('T')[0];
    if (dailyMap[key] !== undefined) {
      dailyMap[key] += bill.total || 0;
    }
  }

  return Object.entries(dailyMap).map(([date, amount]) => ({
    date,
    day: new Date(date).toLocaleDateString('en-US', { weekday: 'short' }),
    amount,
  }));
}

export async function getTopProducts(shopId: string, limit: number) {
  const from = new Date();
  from.setMonth(from.getMonth() - 1);

  const bills = await Bill.find({
    shopId,
    createdAt: { $gte: from },
    status: { $ne: BillStatus.CANCELLED },
  }).lean();

  // Aggregate product sales
  const productMap: Record<string, { name: string; qty: number; revenue: number }> = {};

  for (const bill of bills) {
    for (const item of bill.items || []) {
      const pid = String(item.productId);
      if (!productMap[pid]) {
        productMap[pid] = { name: item.name, qty: 0, revenue: 0 };
      }
      productMap[pid].qty += item.qty || 0;
      productMap[pid].revenue += item.total || 0;
    }
  }

  return Object.entries(productMap)
    .map(([productId, data]) => ({ productId, ...data }))
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, limit);
}

export async function getStockHealth(shopId: string) {
  const products = await Product.find({ shopId }).lean();

  let healthy = 0;
  let low = 0;
  let outOfStock = 0;

  for (const p of products) {
    if (p.stock <= 0) {
      outOfStock++;
    } else if (p.stock <= (p.lowStock || 5)) {
      low++;
    } else {
      healthy++;
    }
  }

  return {
    total: products.length,
    healthy,
    low,
    outOfStock,
    lowStockProducts: products
      .filter((p) => p.stock > 0 && p.stock <= (p.lowStock || 5))
      .map((p) => ({ name: p.name, stock: p.stock, lowStock: p.lowStock }))
      .slice(0, 10),
  };
}

export async function getKhataSummary(shopId: string) {
  const customers = await Customer.find({ shopId }).lean();
  const totalOutstanding = customers.reduce((sum, c) => sum + (c.balance || 0), 0);
  const customersWithDues = customers.filter((c) => (c.balance || 0) > 0);

  return {
    totalOutstanding,
    totalCustomers: customers.length,
    customersWithDues: customersWithDues.length,
    topDebtors: customersWithDues
      .sort((a, b) => (b.balance || 0) - (a.balance || 0))
      .slice(0, 10)
      .map((c) => ({ name: c.name, phone: c.phone, balance: c.balance })),
  };
}
