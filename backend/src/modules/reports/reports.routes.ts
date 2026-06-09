/**
 * Reports Routes  — all protected
 *
 * GET /api/reports/summary       — sales KPIs (?period=daily|weekly|monthly|yearly)
 * GET /api/reports/chart         — daily sales chart (?days=7)
 * GET /api/reports/top-products  — top 5 products by revenue (?limit=5)
 * GET /api/reports/stock-health  — healthy / low / out-of-stock counts
 * GET /api/reports/khata         — total outstanding summary
 */
import { Router } from 'express';
import {
  summaryHandler, chartHandler,
  topProductsHandler, stockHealthHandler, khataHandler,
} from './reports.controller';

const router = Router();

router.get('/summary',       summaryHandler);
router.get('/chart',         chartHandler);
router.get('/top-products',  topProductsHandler);
router.get('/stock-health',  stockHealthHandler);
router.get('/khata',         khataHandler);

export default router;
