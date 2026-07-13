/**
 * Driving-credential domain types. Parity with Flutter
 * `mobile/lib/features/driving_credentials/domain/driving_credential.dart`.
 */

export type CredentialStatus = 'ok' | 'soon' | 'overdue';

export type DrivingCredential = {
  id: string;
  docType: string; // 'license' | 'permit' | 'international_license'
  docNumber: string | null;
  issueDate: string | null;
  expiryDate: string | null;
  notes: string | null;
  status: CredentialStatus | null;
  daysUntilExpiry: number | null;
  createdAt: string;
  updatedAt: string;
};

/** Human label for a credential's `docType` — parity with `DrivingCredential.labelFor`. */
export function credentialLabelFor(docType: string): string {
  switch (docType) {
    case 'license':
      return "Driver's License";
    case 'permit':
      return 'Driving Permit';
    case 'international_license':
      return 'International Driving License';
    default:
      return docType;
  }
}

/** All selectable document types (Doc 2/3 enum) — parity with Dart's `_allDocTypes`/`_docTypes`. */
export const CREDENTIAL_DOC_TYPES = ['license', 'permit', 'international_license'] as const;

export type CredentialDocType = (typeof CREDENTIAL_DOC_TYPES)[number];

/** `POST /me/driving-credentials` body. `docType` is required on create. */
export type CreateCredentialPayload = {
  docType: CredentialDocType;
  docNumber?: string;
  issueDate?: string;
  expiryDate?: string;
  notes?: string;
};

/** `PATCH /me/driving-credentials/{id}` body — all fields optional. */
export type UpdateCredentialPayload = Partial<CreateCredentialPayload>;
