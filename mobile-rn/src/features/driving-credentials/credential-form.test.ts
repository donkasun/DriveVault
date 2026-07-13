import {
  buildCreatePayload,
  buildUpdatePayload,
  credentialExpiryText,
  credentialSubtitle,
  formatCredentialDate,
  missingDocTypes,
  type CredentialFormState,
} from './credential-form';
import type { DrivingCredential } from './types';

function baseState(overrides: Partial<CredentialFormState> = {}): CredentialFormState {
  return {
    docType: 'license',
    docNumber: '',
    issueDate: '',
    expiryDate: '',
    notes: '',
    ...overrides,
  };
}

function baseCredential(overrides: Partial<DrivingCredential> = {}): DrivingCredential {
  return {
    id: 'c1',
    docType: 'license',
    docNumber: null,
    issueDate: null,
    expiryDate: null,
    notes: null,
    status: null,
    daysUntilExpiry: null,
    createdAt: '2026-01-01T00:00:00Z',
    updatedAt: '2026-01-01T00:00:00Z',
    ...overrides,
  };
}

describe('buildCreatePayload', () => {
  it('includes docType and trims optional text fields', () => {
    const state = baseState({
      docType: 'permit',
      docNumber: '  DL-123  ',
      issueDate: '2024-01-01',
      expiryDate: '2029-01-01',
      notes: '  some notes  ',
    });

    expect(buildCreatePayload(state)).toEqual({
      docType: 'permit',
      docNumber: 'DL-123',
      issueDate: '2024-01-01',
      expiryDate: '2029-01-01',
      notes: 'some notes',
    });
  });

  it('omits blank/whitespace-only optional fields', () => {
    const state = baseState({ docNumber: '   ', issueDate: '', expiryDate: '', notes: '' });

    expect(buildCreatePayload(state)).toEqual({
      docType: 'license',
      docNumber: undefined,
      issueDate: undefined,
      expiryDate: undefined,
      notes: undefined,
    });
  });
});

describe('buildUpdatePayload', () => {
  it('omits docType since it is not editable after creation', () => {
    const state = baseState({ docType: 'international_license', docNumber: 'X1' });

    const payload = buildUpdatePayload(state);

    expect(payload).not.toHaveProperty('docType');
    expect(payload).toEqual({
      docNumber: 'X1',
      issueDate: undefined,
      expiryDate: undefined,
      notes: undefined,
    });
  });
});

describe('missingDocTypes', () => {
  it('returns all doc types when there are no credentials', () => {
    expect(missingDocTypes([])).toEqual(['license', 'permit', 'international_license']);
  });

  it('excludes doc types already present', () => {
    const creds = [baseCredential({ docType: 'license' }), baseCredential({ id: 'c2', docType: 'permit' })];

    expect(missingDocTypes(creds)).toEqual(['international_license']);
  });

  it('returns an empty list once every doc type exists', () => {
    const creds = [
      baseCredential({ docType: 'license' }),
      baseCredential({ id: 'c2', docType: 'permit' }),
      baseCredential({ id: 'c3', docType: 'international_license' }),
    ];

    expect(missingDocTypes(creds)).toEqual([]);
  });
});

describe('formatCredentialDate', () => {
  it('formats an ISO date as "d MMM y"', () => {
    expect(formatCredentialDate('2027-03-05')).toBe('5 Mar 2027');
  });

  it('returns the raw string when unparsable', () => {
    expect(formatCredentialDate('not-a-date')).toBe('not-a-date');
  });
});

describe('credentialExpiryText', () => {
  it('shows the formatted expiry date when present', () => {
    expect(credentialExpiryText('2027-03-05')).toBe('Expires 5 Mar 2027');
  });

  it('falls back to "No expiry set" when null', () => {
    expect(credentialExpiryText(null)).toBe('No expiry set');
  });
});

describe('credentialSubtitle', () => {
  it('appends the doc number when present', () => {
    expect(credentialSubtitle("Driver's License", 'DL-123')).toBe("Driver's License · DL-123");
  });

  it('falls back to just the label when there is no doc number', () => {
    expect(credentialSubtitle("Driver's License", null)).toBe("Driver's License");
  });
});
