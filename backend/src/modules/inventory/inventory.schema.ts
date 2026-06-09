import { z } from 'zod';

export const createProductSchema = z.object({
  name:      z.string().min(1, 'Product name is required').max(100),
  unit:      z.string().default('pcs'),
  mrp:       z.number({ required_error: 'MRP is required' }).positive('MRP must be positive'),
  costPrice: z.number({ required_error: 'Cost price is required' }).positive('Cost price must be positive'),
  stock:     z.number().min(0).default(0),
  lowStock:  z.number().min(0).default(5),
});

export const updateProductSchema = createProductSchema.partial();

export const adjustStockSchema = z.object({
  type: z.enum(['ADD', 'SELL', 'ADJUST']),
  qty:  z.number().positive('Quantity must be positive'),
  note: z.string().max(200).optional(),
});

export type CreateProductInput = z.infer<typeof createProductSchema>;
export type UpdateProductInput = z.infer<typeof updateProductSchema>;
export type AdjustStockInput   = z.infer<typeof adjustStockSchema>;
