/**
 * query.ts — safe Express query-param helpers
 * Express req.query values are complex union types.
 * These helpers extract a plain string/number safely.
 */

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function qs(val: any): string | undefined {
  if (typeof val === 'string') return val || undefined;
  if (Array.isArray(val) && typeof val[0] === 'string') return (val[0] as string) || undefined;
  return undefined;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function qn(val: any, defaultVal: number, max?: number): number {
  const n      = parseInt(typeof val === 'string' ? val : '', 10);
  const result = isNaN(n) || n <= 0 ? defaultVal : n;
  return max !== undefined ? Math.min(result, max) : result;
}
