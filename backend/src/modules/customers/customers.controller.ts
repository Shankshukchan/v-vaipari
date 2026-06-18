import type { Request, Response } from 'express';
import { createCustomerSchema, updateCustomerSchema, addTransactionSchema } from './customers.schema';
import {
  listCustomers, getCustomer, createCustomer, updateCustomer,
  deleteCustomer, addTransaction, getTransactions, getOutstandingSummary,
  getCustomerBills, clearCustomerKhata,
} from './customers.service';
import { ok, created, fail, notFound } from '../../utils/response';
import { qs } from '../../utils/query';
import { param } from '../../utils/params';

function sid(req: Request, res: Response): string | null {
  const id = req.user?.shopId;
  if (!id) { fail(res, 'No shop linked to account', 404); return null; }
  return id;
}

export async function listHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  ok(res, await listCustomers(s, qs(req.query['search'])));
}
export async function summaryHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  ok(res, await getOutstandingSummary(s));
}
export async function getHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await getCustomer(param(req, 'id'), s)); }
  catch (e) { notFound(res, (e as Error).message); }
}
export async function createHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  const p = createCustomerSchema.safeParse(req.body);
  if (!p.success) { fail(res, 'Validation failed'); return; }
  try { created(res, await createCustomer(s, p.data)); }
  catch (e) { fail(res, (e as Error).message); }
}
export async function updateHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  const p = updateCustomerSchema.safeParse(req.body);
  if (!p.success) { fail(res, 'Validation failed'); return; }
  try { ok(res, await updateCustomer(param(req, 'id'), s, p.data)); }
  catch (e) { notFound(res, (e as Error).message); }
}
export async function deleteHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { await deleteCustomer(param(req, 'id'), s); ok(res, { deleted: true }); }
  catch (e) { notFound(res, (e as Error).message); }
}
export async function addTransactionHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  const p = addTransactionSchema.safeParse(req.body);
  if (!p.success) { fail(res, 'Validation failed'); return; }
  try { created(res, await addTransaction(param(req, 'id'), s, p.data)); }
  catch (e) { fail(res, (e as Error).message); }
}
export async function getTransactionsHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await getTransactions(param(req, 'id'), s)); }
  catch (e) { notFound(res, (e as Error).message); }
}

export async function getCustomerBillsHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await getCustomerBills(param(req, 'id'), s)); }
  catch (e) { notFound(res, (e as Error).message); }
}

export async function clearKhataHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await clearCustomerKhata(param(req, 'id'), s)); }
  catch (e) { notFound(res, (e as Error).message); }
}
