import { Shop, User } from '../../models';
import { storeFile } from '../../middleware/upload.middleware';
import type { CreateShopInput, UpdateShopInput } from './shop.schema';

export async function getShop(shopId: string) {
  const shop = await Shop.findById(shopId).lean();
  if (!shop) throw new Error('Shop not found');
  return { ...shop, id: shop._id };
}

export async function createShop(userId: string, input: CreateShopInput) {
  const user = await User.findById(userId);
  if (!user) throw new Error('User not found');
  if (user.shopId) throw new Error('You already have a shop. Use update instead.');

  const shop = await Shop.create({
    name: input.name,
    gstin: input.gstin || null,
    phone: input.phone || null,
    email: input.email || null,
    address: input.address || null,
    pincode: input.pincode || null,
  });

  await User.findByIdAndUpdate(userId, { shopId: shop._id });

  const shopObj = shop.toObject();
  return { ...shopObj, id: shopObj._id };
}

export async function updateShop(shopId: string, input: UpdateShopInput) {
  const data: any = {};
  if (input.name !== undefined) data.name = input.name;
  if (input.gstin !== undefined) data.gstin = input.gstin || null;
  if (input.phone !== undefined) data.phone = input.phone || null;
  if (input.email !== undefined) data.email = input.email || null;
  if (input.address !== undefined) data.address = input.address || null;
  if (input.pincode !== undefined) data.pincode = input.pincode || null;

  const shop = await Shop.findByIdAndUpdate(shopId, data, { new: true }).lean();
  if (!shop) throw new Error('Shop not found');
  return { ...shop, id: shop._id };
}

export async function uploadLogo(shopId: string, file: Express.Multer.File) {
  const logoUrl = await storeFile(file, 'kirana/logos', `shop_${shopId}_logo`);
  const shop = await Shop.findByIdAndUpdate(shopId, { logoUrl }, { new: true }).lean();
  return { ...shop, id: shop?._id };
}

export async function uploadSignature(shopId: string, file: Express.Multer.File) {
  const signatureUrl = await storeFile(file, 'kirana/signatures', `shop_${shopId}_signature`);
  const shop = await Shop.findByIdAndUpdate(shopId, { signatureUrl }, { new: true }).lean();
  return { ...shop, id: shop?._id };
}

export async function removeAsset(shopId: string, field: 'logoUrl' | 'signatureUrl') {
  const shop = await Shop.findByIdAndUpdate(shopId, { [field]: null }, { returnDocument: 'after' }).lean();
  return { ...shop, id: shop?._id };
}
