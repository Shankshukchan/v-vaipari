import { Product, InventoryLog, StockType } from '../../models';
import type { CreateProductInput, UpdateProductInput, AdjustStockInput } from './inventory.schema';

export async function listProducts(shopId: string, search?: string) {
  const filter: any = { shopId };
  if (search) {
    filter.$or = [
      { name: { $regex: search, $options: 'i' } },
      { barcode: { $regex: search, $options: 'i' } },
    ];
  }
  return Product.find(filter).sort({ createdAt: -1 }).lean();
}

export async function getProduct(productId: string, shopId: string) {
  const product = await Product.findOne({ _id: productId, shopId }).lean();
  if (!product) throw new Error('Product not found');
  return product;
}

export async function getProductByBarcode(shopId: string, barcode: string) {
  const product = await Product.findOne({ shopId, barcode }).lean();
  if (!product) throw new Error('No product found with this barcode');
  return product;
}

export async function createProduct(shopId: string, input: CreateProductInput) {
  if (input.barcode) {
    const existing = await Product.findOne({ shopId, barcode: input.barcode });
    if (existing) throw new Error('A product with this barcode already exists');
  }
  return Product.create({ ...input, shopId });
}

export async function updateProduct(productId: string, shopId: string, input: UpdateProductInput) {
  if (input.barcode) {
    const existing = await Product.findOne({
      shopId,
      barcode: input.barcode,
      _id: { $ne: productId },
    });
    if (existing) throw new Error('Another product with this barcode already exists');
  }
  const product = await Product.findOneAndUpdate(
    { _id: productId, shopId },
    { $set: input },
    { returnDocument: 'after' },
  ).lean();
  if (!product) throw new Error('Product not found');
  return product;
}

export async function deleteProduct(productId: string, shopId: string) {
  const product = await Product.findOneAndDelete({ _id: productId, shopId });
  if (!product) throw new Error('Product not found');
  await InventoryLog.deleteMany({ productId });
  return product;
}

export async function adjustStock(productId: string, shopId: string, input: AdjustStockInput) {
  const product = await Product.findOne({ _id: productId, shopId });
  if (!product) throw new Error('Product not found');

  const currentStock = product.stock || 0;
  let newStock = currentStock;

  switch (input.type) {
    case 'ADD':
      newStock = currentStock + input.qty;
      break;
    case 'SELL':
      if (currentStock < input.qty) throw new Error('Insufficient stock');
      newStock = currentStock - input.qty;
      break;
    case 'ADJUST':
      newStock = input.qty;
      break;
  }

  product.stock = newStock;
  await product.save();

  await InventoryLog.create({
    shopId,
    productId,
    type: input.type as StockType,
    qty: input.qty,
    note: input.note,
  });

  return product.toObject();
}

export async function listLowStock(shopId: string) {
  return Product.find({
    shopId,
    $expr: { $lte: ['$stock', '$lowStock'] },
  }).lean();
}

export async function getStockLogs(shopId: string, productId: string) {
  const product = await Product.findOne({ _id: productId, shopId });
  if (!product) throw new Error('Product not found');
  return InventoryLog.find({ productId }).sort({ createdAt: -1 }).limit(50).lean();
}
