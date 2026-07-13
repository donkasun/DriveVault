/** Cloudinary signed-upload types. Parity with Flutter's upload_repository.dart. */

/** Response from `POST /uploads/cloudinary-signature`. */
export type CloudinarySignature = {
  signature: string;
  timestamp: number;
  apiKey: string;
  cloudName: string;
  folder: string;
};

/** The subset of Cloudinary's upload response we persist. */
export type CloudinaryUploadResult = {
  secureUrl: string;
  publicId: string;
};
