import { Bill, Product, Customer } from '../../models';

export async function getDashboardStats(shopId: string, fromDate: Date, toDate: Date) {
  return {
    salesAmount: 0,
    salesCount: 0,
    productsCount: 0,
    customersCount: 0,
    lowStockCount: 0,
    creditPending: 0,
  };
}

export async function getDailySales(shopId: string, fromDate: Date, toDate: Date) {
  return [];
}

export async function getLowStockProducts(shopId: string) {
  return [];
}

export async function getPendingCredits(shopId: string) {
  return [];
}

export async function getSalesSummary(shopId: string, period?: any) { return {}; }
export async function getDailyChart(shopId: string, days?: any) { return []; }
export async function getTopProducts(shopId: string, limit?: any) { return []; }
export async function getStockHealth(shopId: string) { return {}; }
export async function getKhataSummary(shopId: string) { return {}; }
