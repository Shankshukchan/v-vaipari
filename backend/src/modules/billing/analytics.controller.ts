import type { Request, Response } from 'express';
import { getDashboardStats } from './analytics.service';
import { ok, fail } from '../../utils/response';

function sid(req: Request, res: Response): string | null {
  const id = req.user?.shopId;
  if (!id) { fail(res, 'No shop linked to account', 404); return null; }
  return id;
}

export async function dashboardHandler(req: Request, res: Response) {
  const s = sid(req, res); if (!s) return;
  try { ok(res, await getDashboardStats(s)); }
  catch (e) { fail(res, (e as Error).message); }
}
