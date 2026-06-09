import { Product, InventoryLog } from '../../models';
import type { UpdateProductInput, AdjustStockInput } from './inventory.schema';

export async function listProducts(shopId: string, search?: string) {
  return [];
}

export async function getProduct(shopId: string, productId: string) {
  return null;
}

export async function addProduct(shopId: string, input: any) {
  return null;
}

export async function updateProduct(shopId: string, productId: string, input: UpdateProductInput) {
  return null;
}

export async function deleteProduct(shopId: string, productId: string) {
  return null;
}

export async function adjustStock(shopId: string, productId: string, input: AdjustStockInput) {
  return null;
}

export async function listLowStock(shopId: string) { return []; }
export async function createProduct(shopId: string, input: any) { return null; }
export async function getStockLogs(shopId: string, productId: string) { return []; }
