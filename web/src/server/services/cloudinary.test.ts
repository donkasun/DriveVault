import { createHash } from 'node:crypto';

import { afterEach, describe, expect, it } from 'vitest';

import { signCloudinaryUpload } from './cloudinary';

describe('signCloudinaryUpload', () => {
  const prev = {
    cloudName: process.env.CLOUDINARY_CLOUD_NAME,
    apiKey: process.env.CLOUDINARY_API_KEY,
    apiSecret: process.env.CLOUDINARY_API_SECRET,
  };

  afterEach(() => {
    if (prev.cloudName === undefined) delete process.env.CLOUDINARY_CLOUD_NAME;
    else process.env.CLOUDINARY_CLOUD_NAME = prev.cloudName;
    if (prev.apiKey === undefined) delete process.env.CLOUDINARY_API_KEY;
    else process.env.CLOUDINARY_API_KEY = prev.apiKey;
    if (prev.apiSecret === undefined) delete process.env.CLOUDINARY_API_SECRET;
    else process.env.CLOUDINARY_API_SECRET = prev.apiSecret;
  });

  it('matches hand-computed SHA1 for fixed timestamp (Python parity)', () => {
    process.env.CLOUDINARY_CLOUD_NAME = 'drivevault';
    process.env.CLOUDINARY_API_KEY = '1234567890';
    process.env.CLOUDINARY_API_SECRET = 'top-secret';

    const folder = 'vehicles/vehicle-123/documents';
    const timestamp = 1733692800;
    const expectedSignature = createHash('sha1')
      .update(
        `folder=${folder}&timestamp=${timestamp}top-secret`,
      )
      .digest('hex');

    const result = signCloudinaryUpload(folder, timestamp);

    expect(result).toEqual({
      signature: expectedSignature,
      timestamp,
      apiKey: '1234567890',
      cloudName: 'drivevault',
      folder,
    });
    expect(JSON.stringify(result)).not.toContain('top-secret');
  });

  it('defaults missing Cloudinary env vars to empty string', () => {
    delete process.env.CLOUDINARY_CLOUD_NAME;
    delete process.env.CLOUDINARY_API_KEY;
    delete process.env.CLOUDINARY_API_SECRET;

    const result = signCloudinaryUpload('vehicles/x/documents', 1);
    expect(result.apiKey).toBe('');
    expect(result.cloudName).toBe('');
    expect(result.signature).toBe(
      createHash('sha1')
        .update('folder=vehicles/x/documents&timestamp=1')
        .digest('hex'),
    );
  });
});
