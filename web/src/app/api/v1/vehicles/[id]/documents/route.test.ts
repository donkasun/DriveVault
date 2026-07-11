import { like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { documents, users, vehicles } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-docs-list-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'docs@example.com',
      displayName: overrides.displayName ?? null,
      photoUrl: overrides.photoUrl ?? null,
      currency: overrides.currency ?? 'LKR',
      distanceUnit: overrides.distanceUnit ?? 'km',
      renewalRemindersEnabled: overrides.renewalRemindersEnabled ?? true,
    })
    .returning();
  return row;
}

async function seedVehicle(
  userId: string,
  overrides: Partial<typeof vehicles.$inferInsert> = {},
) {
  const [row] = await db
    .insert(vehicles)
    .values({
      userId,
      make: overrides.make ?? 'Toyota',
      model: overrides.model ?? 'Hilux',
      year: overrides.year ?? 2020,
      ...overrides,
    })
    .returning();
  return row;
}

async function seedDocument(
  vehicleId: string,
  overrides: Partial<typeof documents.$inferInsert> = {},
) {
  const [row] = await db
    .insert(documents)
    .values({
      vehicleId,
      docType: overrides.docType ?? 'insurance',
      title: overrides.title ?? 'Policy',
      storageUrl:
        overrides.storageUrl ??
        'https://res.cloudinary.com/drivevault/image/upload/v1/doc.pdf',
      storagePublicId: overrides.storagePublicId ?? 'vehicles/v1/documents/doc',
      mimeType: overrides.mimeType ?? 'application/pdf',
      fileSizeBytes: overrides.fileSizeBytes ?? 1000,
      issueDate: overrides.issueDate ?? '2026-01-01',
      expiryDate: overrides.expiryDate ?? '2026-12-31',
      ...overrides,
    })
    .returning();
  return row;
}

function ctx(id: string) {
  return { params: Promise.resolve({ id }) };
}

function listRequest(vehicleId: string, query = ''): NextRequest {
  return new NextRequest(
    `http://localhost/api/v1/vehicles/${vehicleId}/documents${query}`,
    { method: 'GET' },
  );
}

function createRequest(vehicleId: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/v1/vehicles/${vehicleId}/documents`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

describe('GET/POST /api/v1/vehicles/[id]/documents', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET filters by docType and orders by expiryDate desc', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const later = await seedDocument(vehicle.id, {
      docType: 'insurance',
      title: 'Later',
      expiryDate: '2027-06-01',
    });
    await seedDocument(vehicle.id, {
      docType: 'registration',
      title: 'Reg',
      expiryDate: '2026-06-01',
    });
    await seedDocument(vehicle.id, {
      docType: 'insurance',
      title: 'Earlier',
      expiryDate: '2026-01-01',
    });

    const { GET } = await import('./route');
    const response = await GET(
      listRequest(vehicle.id, '?docType=insurance'),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toHaveLength(2);
    expect(body[0].id).toBe(later.id);
    expect(body.every((d: { docType: string }) => d.docType === 'insurance')).toBe(
      true,
    );
  });

  it('POST creates document metadata (201)', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, {
        docType: 'insurance',
        title: '2026 Insurance Policy',
        storageUrl: 'https://res.cloudinary.com/drivevault/image/upload/v1/doc123.pdf',
        storagePublicId: 'vehicles/v1/documents/doc123',
        mimeType: 'application/pdf',
        fileSizeBytes: 482000,
        issueDate: '2026-01-01',
        expiryDate: '2026-12-31',
      }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(201);
    const created = await response.json();
    expect(created.vehicleId).toBe(vehicle.id);
    expect(created.docType).toBe('insurance');
    expect(created.title).toBe('2026 Insurance Policy');
    expect(created.storageUrl).toContain('doc123.pdf');
    expect(created.fileSizeBytes).toBe(482000);
  });

  it('POST rejects missing required fields', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);

    const { POST } = await import('./route');
    const response = await POST(
      createRequest(vehicle.id, { title: 'No type or url' }),
      ctx(vehicle.id),
    );

    expect(response.status).toBe(400);
  });

  it('GET returns 404 for other user vehicle', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });

    const { GET } = await import('./route');
    const response = await GET(listRequest(otherVehicle.id), ctx(otherVehicle.id));

    expect(response.status).toBe(404);
  });
});
