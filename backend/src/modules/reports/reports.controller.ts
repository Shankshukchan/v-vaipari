import type { Request, Response } from 'express';
import { getSalesSummary, getDailyChart, getTopProducts, getStockHealth, getKhataSummary } from './reports.service';
import { ok, fail } from '../../utils/response';
import { qs, qn } from '../../utils/query';

function sid(req: Request, res: Response): string | null {
  const id = req.user?.shopId;
  if (!id) { fail(res, 'No shop linked to account', 404); return null; }
  return id;
}

type Period = 'daily' | 'weekly' | 'monthly' | 'yearly';
const VALID_PERIODS: Period[] = ['daily', 'weekly', 'monthly', 'yearly'];
function resolvePeriod(val: unknown): Period {
  return VALID_PERIODS.includes(val as Period) ? (val as Period) : 'monthly';
}

export async function summaryHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  ok(res, await getSalesSummary(s, resolvePeriod(qs(req.query['period']))));
}
export async function chartHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  ok(res, await getDailyChart(s, qn(req.query['days'], 7, 90)));
}
export async function topProductsHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  ok(res, await getTopProducts(s, qn(req.query['limit'], 5, 20)));
}
export async function stockHealthHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  ok(res, await getStockHealth(s));
}
export async function khataHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  ok(res, await getKhataSummary(s));
}
