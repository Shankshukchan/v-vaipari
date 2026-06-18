/**
 * Customers Routes  — all protected
 *
 * GET    /api/customers                    — list customers (search via ?search=)
 * GET    /api/customers/summary            — total outstanding amount
 * GET    /api/customers/:id               — single customer + last 20 transactions
 * POST   /api/customers                   — create customer
 * PATCH  /api/customers/:id              — update customer
 * DELETE /api/customers/:id              — delete customer
 * GET    /api/customers/:id/transactions  — full transaction history
 * POST   /api/customers/:id/transactions  — add CREDIT or DEBIT entry
 * GET    /api/customers/:id/bills         — all bills for this customer
 * POST   /api/customers/:id/clear         — clear khata (mark all as paid)
 */
import { Router } from 'express';
import {
  listHandler, summaryHandler, getHandler,
  createHandler, updateHandler, deleteHandler,
  getTransactionsHandler, addTransactionHandler,
  getCustomerBillsHandler, clearKhataHandler,
} from './customers.controller';

const router = Router();

router.get('/',                          listHandler);
router.get('/summary',                   summaryHandler);
router.get('/:id',                       getHandler);
router.post('/',                         createHandler);
router.patch('/:id',                     updateHandler);
router.delete('/:id',                    deleteHandler);
router.get('/:id/transactions',          getTransactionsHandler);
router.post('/:id/transactions',         addTransactionHandler);
router.get('/:id/bills',                 getCustomerBillsHandler);
router.post('/:id/clear',                clearKhataHandler);

export default router;
