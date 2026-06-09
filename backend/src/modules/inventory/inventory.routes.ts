/**
 * Inventory Routes  — all protected
 *
 * GET    /api/inventory              — list all products (search via ?search=)
 * GET    /api/inventory/low-stock    — products below threshold
 * GET    /api/inventory/:id          — single product
 * POST   /api/inventory              — create product
 * PATCH  /api/inventory/:id          — update product details
 * DELETE /api/inventory/:id          — delete product
 * POST   /api/inventory/:id/stock    — adjust stock (ADD/SELL/ADJUST)
 * GET    /api/inventory/:id/logs     — stock change history
 */
import { Router } from 'express';
import {
  listHandler, lowStockHandler, getHandler,
  createHandler, updateHandler, deleteHandler,
  adjustStockHandler, stockLogsHandler,
} from './inventory.controller';

const router = Router();

router.get('/',           listHandler);
router.get('/low-stock',  lowStockHandler);
router.get('/:id',        getHandler);
router.post('/',          createHandler);
router.patch('/:id',      updateHandler);
router.delete('/:id',     deleteHandler);
router.post('/:id/stock', adjustStockHandler);
router.get('/:id/logs',   stockLogsHandler);

export default router;
