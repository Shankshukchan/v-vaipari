/**
 * Billing Routes  — all protected
 *
 * GET   /api/bills                — list bills (filter: ?from= &to= &customerId=)
 * GET   /api/bills/:id            — single bill with items
 * POST  /api/bills                — create bill (deducts stock automatically)
 * PATCH /api/bills/:id/status     — update bill status (PAID/PENDING/CANCELLED)
 */
import { Router } from 'express';
import { listHandler, getHandler, createHandler, updateStatusHandler } from './billing.controller';

const router = Router();

router.get('/',              listHandler);
router.get('/:id',           getHandler);
router.post('/',             createHandler);
router.patch('/:id/status',  updateStatusHandler);

export default router;
