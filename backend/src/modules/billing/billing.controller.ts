import type { Request, Response } from 'express';
import { createBillSchema, updateBillStatusSchema } from './billing.schema';
import { createBill, listBills, getBill, updateBillStatus, deleteBill } from './billing.service';
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
  ok(res, await listBills(s, {
    from:       qs(req.query['from']),
    to:         qs(req.query['to']),
    customerId: qs(req.query['customerId']),
  }));
}
export async function getHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await getBill(param(req, 'id'), s)); }
  catch (e) { notFound(res, (e as Error).message); }
}
export async function createHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  const p = createBillSchema.safeParse(req.body);
  if (!p.success) { fail(res, 'Validation failed'); return; }
  try { created(res, await createBill(s, p.data)); }
  catch (e) { fail(res, (e as Error).message); }
}
export async function updateStatusHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  const p = updateBillStatusSchema.safeParse(req.body);
  if (!p.success) { fail(res, 'Validation failed'); return; }
  try { ok(res, await updateBillStatus(param(req, 'id'), s, p.data)); }
  catch (e) { notFound(res, (e as Error).message); }
}

export async function deleteHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await deleteBill(param(req, 'id'), s)); }
  catch (e) { notFound(res, (e as Error).message); }
}
