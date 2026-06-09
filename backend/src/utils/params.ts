import type { Request } from 'express';

/** Extract a route param as string (always safe — Express guarantees string for named params) */
export function param(req: Request, key: string): string {
  return req.params[key] as string;
}
