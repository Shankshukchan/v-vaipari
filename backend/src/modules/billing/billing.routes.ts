/**
 * Billing Routes  — all protected
 *
 * GET   /api/bills/dashboard     — dashboard stats
 * GET   /api/bills                — list bills (filter: ?from= &to= &customerId=)
 * GET   /api/bills/:id            — single bill with items
 * POST  /api/bills                — create bill (deducts stock automatically)
 * PATCH /api/bills/:id/status     — update bill status (PAID/PENDING/CANCELLED)
 */
import { Router } from 'express';
import { listHandler, getHandler, createHandler, updateStatusHandler, deleteHandler } from './billing.controller';
import { dashboardHandler } from './analytics.controller';

const router = Router();

router.get('/dashboard',       dashboardHandler);
router.get('/',              listHandler);
router.post('/',             createHandler);
router.patch('/:id/status',  updateStatusHandler);
router.delete('/:id',        deleteHandler);
router.get('/:id',           getHandler);

export default router;
