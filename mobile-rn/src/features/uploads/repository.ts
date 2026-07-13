/**
 * Cloudinary signed direct upload.
 * Parity with Flutter `features/vehicles/data/upload_repository.dart`.
 *
 * CRITICAL (CLAUDE.md): file bytes NEVER pass through our backend. The backend
 * signs the request; the client PUTs the file straight to Cloudinary and sends
 * back only the resulting secure_url / public_id.
 */

import { uploadsApi } from './api';
import type { CloudinaryUploadResult } from './types';

type LocalFile = {
  /** file:// URI from expo-image-picker / expo-document-picker. */
  uri: string;
  name: string;
  mimeType: string;
};

export const uploadsRepository = {
  async uploadFile(file: LocalFile, folder: string): Promise<CloudinaryUploadResult> {
    // 1. Ask our backend to sign the upload.
    const sig = await uploadsApi.signature(folder);

    // 2. Send the bytes directly to Cloudinary.
    const form = new FormData();
    form.append('file', {
      uri: file.uri,
      name: file.name,
      type: file.mimeType,
    } as unknown as Blob);
    form.append('api_key', sig.apiKey);
    form.append('timestamp', String(sig.timestamp));
    form.append('signature', sig.signature);
    form.append('folder', sig.folder);

    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${sig.cloudName}/auto/upload`,
      { method: 'POST', body: form },
    );

    if (!response.ok) {
      const detail = await response.text();
      throw new Error(`Cloudinary upload failed (${response.status}): ${detail}`);
    }

    const data = (await response.json()) as { secure_url?: string; public_id?: string };
    if (!data.secure_url || !data.public_id) {
      throw new Error('Empty Cloudinary upload response');
    }

    return { secureUrl: data.secure_url, publicId: data.public_id };
  },
};
