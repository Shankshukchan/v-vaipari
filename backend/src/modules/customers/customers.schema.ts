import { z } from 'zod';

export const createCustomerSchema = z.object({
  name:  z.string().min(2, 'Name must be at least 2 characters').max(80),
  phone: z.string().regex(/^[6-9]\d{9}$/, 'Enter a valid 10-digit mobile number'),
  balance: z.number().default(0), // optional opening balance
});

export const updateCustomerSchema = createCustomerSchema.partial();

export const addTransactionSchema = z.object({
  type:   z.enum(['CREDIT', 'DEBIT']),
  amount: z.number().positive('Amount must be positive'),
  note:   z.string().max(200).optional(),
});

export type CreateCustomerInput  = z.infer<typeof createCustomerSchema>;
export type UpdateCustomerInput  = z.infer<typeof updateCustomerSchema>;
export type AddTransactionInput  = z.infer<typeof addTransactionSchema>;
