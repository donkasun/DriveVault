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
