/**
 * Pure helpers for the driving-credentials feature — payload building, date
 * formatting, and "which doc types are still available to add" derivation.
 * Kept dependency-free so they're cheap to unit test (parity with Flutter's
 * `DrivingCredentialFormScreen._save` / `_CredentialsList` logic).
 */

import {
  CREDENTIAL_DOC_TYPES,
  type CreateCredentialPayload,
  type CredentialDocType,
  type DrivingCredential,
  type UpdateCredentialPayload,
} from './types';

export type CredentialFormState = {
  docType: CredentialDocType;
  docNumber: string;
  issueDate: string;
  expiryDate: string;
  notes: string;
};

/** Returns undefined for a blank/whitespace-only string, otherwise the trimmed value. */
function trimmedOrUndefined(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

/** Builds the `POST /me/driving-credentials` body — parity with Dart's `_save` body map. */
export function buildCreatePayload(state: CredentialFormState): CreateCredentialPayload {
  return {
    docType: state.docType,
    docNumber: trimmedOrUndefined(state.docNumber),
    issueDate: trimmedOrUndefined(state.issueDate),
    expiryDate: trimmedOrUndefined(state.expiryDate),
    notes: trimmedOrUndefined(state.notes),
  };
}

/**
 * Builds the `PATCH /me/driving-credentials/{id}` body. `docType` is not
 * editable once created (Dart disables the picker in edit mode), so it is
 * intentionally omitted here.
 */
export function buildUpdatePayload(state: CredentialFormState): UpdateCredentialPayload {
  const { docType: _docType, ...rest } = buildCreatePayload(state);
  return rest;
}

/** The doc types not yet represented among `creds` — parity with Dart's `allTypesPresent` check. */
export function missingDocTypes(creds: DrivingCredential[]): CredentialDocType[] {
  const existing = new Set(creds.map((c) => c.docType));
  return CREDENTIAL_DOC_TYPES.filter((docType) => !existing.has(docType));
}

const MONTHS_SHORT = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/**
 * Formats an ISO "YYYY-MM-DD" date as "d MMM y" (e.g. "5 Mar 2027") — parity
 * with Dart's `DateFormat('d MMM y')`. Returns the raw string unchanged if it
 * can't be parsed.
 */
export function formatCredentialDate(iso: string): string {
  const parsed = new Date(`${iso}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) return iso;
  return `${parsed.getDate()} ${MONTHS_SHORT[parsed.getMonth()]} ${parsed.getFullYear()}`;
}

/** "Expires {date}" or "No expiry set" — parity with `_CredentialTile.expiryText`. */
export function credentialExpiryText(expiryDate: string | null): string {
  return expiryDate ? `Expires ${formatCredentialDate(expiryDate)}` : 'No expiry set';
}

/** "{label} · {docNumber}" or just the label — parity with `_CredentialTile.subtitle`. */
export function credentialSubtitle(label: string, docNumber: string | null): string {
  return docNumber ? `${label} · ${docNumber}` : label;
}
