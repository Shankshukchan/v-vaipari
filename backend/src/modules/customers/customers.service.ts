import { Customer, Transaction } from '../../models';
import type { CreateCustomerInput, UpdateCustomerInput, AddTransactionInput } from './customers.schema';

export async function listCustomers(shopId: string, search?: string) {
  return [];
}

export async function getCustomer(shopId: string, customerId: string) {
  return null;
}

export async function createCustomer(shopId: string, input: CreateCustomerInput) {
  return null;
}

export async function updateCustomer(shopId: string, customerId: string, input: UpdateCustomerInput) {
  return null;
}

export async function addTransaction(shopId: string, customerId: string, input: AddTransactionInput) {
  return null;
}

export async function getCustomerTransactions(shopId: string, customerId: string) {
  return [];
}

export async function deleteCustomer(shopId: string, customerId: string) { return null; }
export async function getTransactions(shopId: string, customerId: string) { return []; }
export async function getOutstandingSummary(shopId: string) { return {}; }
