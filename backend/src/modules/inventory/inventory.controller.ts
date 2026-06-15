import type { Request, Response } from 'express';
import { createProductSchema, updateProductSchema, adjustStockSchema } from './inventory.schema';
import {
  listProducts, listLowStock, getProduct, createProduct,
  updateProduct, deleteProduct, adjustStock, getStockLogs, getProductByBarcode,
} from './inventory.service';
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
  ok(res, await listProducts(s, qs(req.query['search'])));
}
export async function lowStockHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  ok(res, await listLowStock(s));
}
export async function getHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await getProduct(param(req, 'id'), s)); }
  catch (e) { notFound(res, (e as Error).message); }
}
export async function getBarcodeHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await getProductByBarcode(s, param(req, 'barcode'))); }
  catch (e) { notFound(res, (e as Error).message); }
}
export async function createHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  const p = createProductSchema.safeParse(req.body);
  if (!p.success) { fail(res, 'Validation failed'); return; }
  try { created(res, await createProduct(s, p.data)); }
  catch (e) { fail(res, (e as Error).message); }
}
export async function updateHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  const p = updateProductSchema.safeParse(req.body);
  if (!p.success) { fail(res, 'Validation failed'); return; }
  try { ok(res, await updateProduct(param(req, 'id'), s, p.data)); }
  catch (e) { notFound(res, (e as Error).message); }
}
export async function deleteHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { await deleteProduct(param(req, 'id'), s); ok(res, { deleted: true }); }
  catch (e) { notFound(res, (e as Error).message); }
}
export async function adjustStockHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  const p = adjustStockSchema.safeParse(req.body);
  if (!p.success) { fail(res, 'Validation failed'); return; }
  try { ok(res, await adjustStock(param(req, 'id'), s, p.data)); }
  catch (e) { fail(res, (e as Error).message); }
}
export async function stockLogsHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await getStockLogs(s, param(req, 'id'))); }
  catch (e) { notFound(res, (e as Error).message); }
}
