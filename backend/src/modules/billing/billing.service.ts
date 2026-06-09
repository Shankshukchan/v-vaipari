import { Bill, Product, InventoryLog, Customer, Transaction } from '../../models';
import type { CreateBillInput, UpdateBillStatusInput } from './billing.schema';

export async function createBill(shopId: string, input: CreateBillInput) {
  return null;
}

export async function listBills(shopId: string, opts: { from?: string; to?: string; customerId?: string }) {
  return [];
}

export async function getBill(billId: string, shopId: string) {
  return null;
}

export async function updateBillStatus(billId: string, shopId: string, input: UpdateBillStatusInput) {
  return null;
}
