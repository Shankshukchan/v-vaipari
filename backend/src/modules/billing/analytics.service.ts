import { Bill, Product, Customer, BillStatus } from '../../models';

export async function getDashboardStats(shopId: string) {
  try {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59);

    // Today's sales
    const todayBills = await Bill.find({
      shopId,
      createdAt: { $gte: startOfDay },
      status: { $ne: BillStatus.CANCELLED },
    }).lean();
    const todaySales = todayBills.reduce((sum, b) => sum + (b.total || 0), 0);
    const todayBillsCount = todayBills.length;

    // This month's bills
    const monthBills = await Bill.find({
      shopId,
      createdAt: { $gte: startOfMonth, $lte: endOfMonth },
      status: { $ne: BillStatus.CANCELLED },
    }).lean();
    const monthRevenue = monthBills.reduce((sum, b) => sum + (b.total || 0), 0);
    const monthProfit = monthBills.reduce((sum, b) => {
      const items = b.items || [];
      const billProfit = items.reduce((itemSum: number, item: any) => {
        return itemSum + ((item.price || 0) * (item.qty || 0));
      }, 0);
      return sum + billProfit * 0.3;
    }, 0);

    // Last 7 days daily sales
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
    const weeklyBills = await Bill.find({
      shopId,
      createdAt: { $gte: sevenDaysAgo },
      status: { $ne: BillStatus.CANCELLED },
    }).lean();

    const dailySales: number[] = [];
    for (let i = 6; i >= 0; i--) {
      const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      const dayEnd = new Date(dayStart.getTime() + 24 * 60 * 60 * 1000);
      const dayTotal = weeklyBills
        .filter(b => {
          const d = new Date(b.createdAt);
          return d >= dayStart && d < dayEnd;
        })
        .reduce((sum, b) => sum + (b.total || 0), 0);
      dailySales.push(dayTotal);
    }

    // Credit due
    const customers = await Customer.find({ shopId, balance: { $gt: 0 } }).lean();
    const totalCreditDue = customers.reduce((sum, c) => sum + (c.balance || 0), 0);
    const creditCustomers = customers.length;

    // Top selling products (by quantity sold in bills)
    const productSales = new Map<string, { name: string; qty: number; revenue: number }>();
    for (const bill of weeklyBills) {
      for (const item of bill.items || []) {
        const pid = item.productId?.toString() || '';
        const existing = productSales.get(pid);
        if (existing) {
          existing.qty += item.qty || 0;
          existing.revenue += item.total || 0;
        } else {
          productSales.set(pid, {
            name: item.name || 'Unknown',
            qty: item.qty || 0,
            revenue: item.total || 0,
          });
        }
      }
    }
    const topProducts = Array.from(productSales.values())
      .sort((a, b) => b.qty - a.qty)
      .slice(0, 3);

    // Low stock count
    const lowStockProducts = await Product.find({
      shopId,
      $expr: { $lte: ['$stock', '$lowStock'] },
    }).lean();

    // Category breakdown from inventory
    const allProducts = await Product.find({ shopId }).lean();
    const categoryMap = new Map<string, number>();
    for (const p of allProducts) {
      const cat = (p as any).category || 'Others';
      categoryMap.set(cat, (categoryMap.get(cat) || 0) + 1);
    }

    return {
      todaySales,
      todayBillsCount,
      monthRevenue,
      monthProfit,
      totalCreditDue,
      creditCustomers,
      topProducts,
      lowStockCount: lowStockProducts.length,
      dailySales,
      categoryBreakdown: {
        Groceries: categoryMap.get('Groceries') || 0,
        Snacks: categoryMap.get('Snacks') || 0,
        Beverages: categoryMap.get('Beverages') || 0,
        Others: categoryMap.get('Others') || 0,
      },
    };
  } catch (error) {
    console.error('Dashboard stats error:', error);
    return {
      todaySales: 0,
      todayBillsCount: 0,
      monthRevenue: 0,
      monthProfit: 0,
      totalCreditDue: 0,
      creditCustomers: 0,
      topProducts: [],
      lowStockCount: 0,
      dailySales: [0, 0, 0, 0, 0, 0, 0],
      categoryBreakdown: { Groceries: 0, Snacks: 0, Beverages: 0, Others: 0 },
    };
  }
}
