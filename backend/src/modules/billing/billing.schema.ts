import { z } from 'zod';

const billItemSchema = z.object({
  productId: z.string().min(1, 'Product ID is required'),
  qty:       z.number().positive('Quantity must be positive'),
});

export const createBillSchema = z.object({
  customerId:    z.string().optional(),
  customerName:  z.string().min(1, 'Customer name is required'),
  customerPhone: z.string().min(1, 'Customer phone is required'),
  items:       z.array(billItemSchema).min(1, 'At least one item is required'),
  discount:    z.number().min(0).default(0),
  paymentMode: z.enum(['CASH', 'UPI', 'CREDIT']).default('CASH'),
});

export const updateBillStatusSchema = z.object({
  status: z.enum(['PAID', 'PENDING', 'CANCELLED']),
});

export type CreateBillInput      = z.infer<typeof createBillSchema>;
export type UpdateBillStatusInput = z.infer<typeof updateBillStatusSchema>;
