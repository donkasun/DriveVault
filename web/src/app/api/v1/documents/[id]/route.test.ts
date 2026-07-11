import { eq, like } from 'drizzle-orm';
import { NextRequest } from 'next/server';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import type { User } from '@/server/auth/upsert-user';
import { db } from '@/server/db/client';
import { documents, users, vehicles } from '@/server/db/schema';

const { requireUser } = vi.hoisted(() => ({ requireUser: vi.fn() }));

vi.mock('@/server/auth/require-user', () => ({ requireUser }));

const TEST_UID_PREFIX = 'test-docs-id-';

async function seedUser(
  overrides: Partial<typeof users.$inferInsert> = {},
): Promise<User> {
  const firebaseUid = overrides.firebaseUid ?? `${TEST_UID_PREFIX}${crypto.randomUUID()}`;
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid,
      email: overrides.email ?? 'docs-id@example.com',
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

async function seedDocument(vehicleId: string) {
  const [row] = await db
    .insert(documents)
    .values({
      vehicleId,
      docType: 'insurance',
      title: 'Policy',
      storageUrl: 'https://res.cloudinary.com/drivevault/image/upload/v1/doc.pdf',
      storagePublicId: 'vehicles/v1/documents/doc',
      mimeType: 'application/pdf',
      fileSizeBytes: 1000,
      issueDate: '2026-01-01',
      expiryDate: '2026-12-31',
    })
    .returning();
  return row;
}

function ctx(id: string) {
  return { params: Promise.resolve({ id }) };
}

function getRequest(id: string): NextRequest {
  return new NextRequest(`http://localhost/api/v1/documents/${id}`, { method: 'GET' });
}

function patchRequest(id: string, body: unknown): NextRequest {
  return new NextRequest(`http://localhost/api/v1/documents/${id}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
}

function deleteRequest(id: string): NextRequest {
  return new NextRequest(`http://localhost/api/v1/documents/${id}`, {
    method: 'DELETE',
  });
}

describe('GET/PATCH/DELETE /api/v1/documents/[id]', () => {
  beforeEach(() => {
    requireUser.mockReset();
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('GET returns owned document', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const doc = await seedDocument(vehicle.id);

    const { GET } = await import('./route');
    const response = await GET(getRequest(doc.id), ctx(doc.id));

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.title).toBe('Policy');
    expect(body.docType).toBe('insurance');
  });

  it('GET returns 404 for other user document', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });
    const otherDoc = await seedDocument(otherVehicle.id);

    const { GET } = await import('./route');
    const response = await GET(getRequest(otherDoc.id), ctx(otherDoc.id));

    expect(response.status).toBe(404);
    await expect(response.json()).resolves.toEqual({
      detail: 'Document not found',
    });
  });

  it('PATCH updates title and expiryDate', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const doc = await seedDocument(vehicle.id);

    const { PATCH } = await import('./route');
    const response = await PATCH(
      patchRequest(doc.id, { title: 'Renewed Policy', expiryDate: '2027-12-31' }),
      ctx(doc.id),
    );

    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body.title).toBe('Renewed Policy');
    expect(body.expiryDate).toBe('2027-12-31');
  });

  it('DELETE removes DB row only and returns 204', async () => {
    const owner = await seedUser();
    requireUser.mockResolvedValue(owner);
    const vehicle = await seedVehicle(owner.id);
    const doc = await seedDocument(vehicle.id);

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(doc.id), ctx(doc.id));

    expect(response.status).toBe(204);
    const remaining = await db
      .select()
      .from(documents)
      .where(eq(documents.id, doc.id));
    expect(remaining).toHaveLength(0);
  });

  it('DELETE returns 404 for other user document', async () => {
    const owner = await seedUser();
    const other = await seedUser({ email: 'other3@example.com' });
    requireUser.mockResolvedValue(owner);
    const otherVehicle = await seedVehicle(other.id, { make: 'Honda' });
    const otherDoc = await seedDocument(otherVehicle.id);

    const { DELETE } = await import('./route');
    const response = await DELETE(deleteRequest(otherDoc.id), ctx(otherDoc.id));

    expect(response.status).toBe(404);
  });
});
