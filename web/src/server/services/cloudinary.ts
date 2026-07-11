import 'server-only';

import { createHash } from 'node:crypto';

import type { CloudinarySignatureResponse } from '@/server/schemas/uploads';

/**
 * Sign a Cloudinary direct-upload request (SHA1, same as Python uploads.py).
 *
 * Optional `timestamp` injects a fixed value for unit tests — small deviation
 * from Python which always uses `int(time())`. Production callers omit it.
 *
 * Env vars default to '' like Python pydantic-settings config.
 */
export function signCloudinaryUpload(
  folder: string,
  timestamp?: number,
): CloudinarySignatureResponse {
  const ts = timestamp ?? Math.floor(Date.now() / 1000);
  const cloudName = process.env.CLOUDINARY_CLOUD_NAME ?? '';
  const apiKey = process.env.CLOUDINARY_API_KEY ?? '';
  const apiSecret = process.env.CLOUDINARY_API_SECRET ?? '';

  const params: Record<string, string | number> = {
    folder,
    timestamp: ts,
  };
  const paramString = Object.keys(params)
    .sort()
    .map((key) => `${key}=${params[key]}`)
    .join('&');
  const signature = createHash('sha1')
    .update(`${paramString}${apiSecret}`)
    .digest('hex');

  return {
    signature,
    timestamp: ts,
    apiKey,
    cloudName,
    folder,
  };
}
