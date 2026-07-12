import { like } from 'drizzle-orm';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const { sendFcm } = vi.hoisted(() => ({ sendFcm: vi.fn() }));

vi.mock('@/server/services/fcm', () => ({ sendFcm }));

import { db } from '@/server/db/client';
import { documents, reminders, userDocuments, users, vehicles } from '@/server/db/schema';
import { processReminders } from '@/server/services/reminder-processing';

const TEST_UID_PREFIX = 'test-reminder-svc-';

function todayUtc(): string {
  return new Date().toISOString().slice(0, 10);
}

function addDaysUtc(base: string, days: number): string {
  const d = new Date(`${base}T00:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

async function seedUser(overrides: Partial<typeof users.$inferInsert> = {}) {
  const [row] = await db
    .insert(users)
    .values({
      firebaseUid: `${TEST_UID_PREFIX}${crypto.randomUUID()}`,
      email: overrides.email ?? 'reminder-test@example.com',
      renewalRemindersEnabled: overrides.renewalRemindersEnabled ?? true,
      fcmToken: overrides.fcmToken ?? 'fcm-token-123',
      ...overrides,
    })
    .returning();
  return row;
}

async function seedVehicle(userId: string) {
  const [row] = await db
    .insert(vehicles)
    .values({ userId, make: 'Toyota', model: 'Corolla', year: 2021 })
    .returning();
  return row;
}

async function seedDoc(vehicleId: string, expiryDate: string | null, title = 'Insurance') {
  const [row] = await db
    .insert(documents)
    .values({
      vehicleId,
      docType: 'insurance',
      title,
      storageUrl: 'https://example.com/doc.pdf',
      expiryDate,
    })
    .returning();
  return row;
}

async function seedCredential(userId: string, expiryDate: string | null, docType = 'license') {
  const [row] = await db
    .insert(userDocuments)
    .values({ userId, docType, expiryDate })
    .returning();
  return row;
}

describe('processReminders', () => {
  beforeEach(() => {
    sendFcm.mockReset();
    sendFcm.mockResolvedValue(true);
  });

  afterEach(async () => {
    await db.delete(users).where(like(users.firebaseUid, `${TEST_UID_PREFIX}%`));
  });

  it('creates a sent reminder for a document expiring in 30 days when user wants FCM', async () => {
    const owner = await seedUser({ renewalRemindersEnabled: true, fcmToken: 'tok' });
    const vehicle = await seedVehicle(owner.id);
    const today = todayUtc();
    await seedDoc(vehicle.id, addDaysUtc(today, 30), 'Insurance');

    const result = await processReminders();

    expect(result.processed).toBeGreaterThanOrEqual(1);
    expect(result.sent).toBeGreaterThanOrEqual(1);

    const rows = await db
      .select()
      .from(reminders)
      .where(like(reminders.title, 'Insurance expiring in 30 day(s)'));
    expect(rows).toHaveLength(1);
    expect(rows[0].status).toBe('sent');
    expect(rows[0].reminderType).toBe('document_expiry');
    expect(sendFcm).toHaveBeenCalledWith(
      expect.objectContaining({
        token: 'tok',
        title: 'Renewal Reminder',
        body: 'Insurance expires in 30 day(s).',
        data: { type: 'document_expiry', docType: 'insurance' },
      }),
    );
  });

  it('creates a pending reminder (no FCM) when renewalRemindersEnabled is false', async () => {
    const owner = await seedUser({ renewalRemindersEnabled: false, fcmToken: 'tok' });
    const vehicle = await seedVehicle(owner.id);
    const today = todayUtc();
    await seedDoc(vehicle.id, addDaysUtc(today, 7), 'Registration');

    await processReminders();

    const rows = await db
      .select()
      .from(reminders)
      .where(like(reminders.title, 'Registration expiring in 7 day(s)'));
    expect(rows).toHaveLength(1);
    expect(rows[0].status).toBe('pending');
    expect(sendFcm).not.toHaveBeenCalled();
  });

  it('creates a pending reminder (not sent) when FCM send fails', async () => {
    sendFcm.mockResolvedValue(false);
    const owner = await seedUser({ renewalRemindersEnabled: true, fcmToken: 'tok' });
    const vehicle = await seedVehicle(owner.id);
    const today = todayUtc();
    await seedDoc(vehicle.id, addDaysUtc(today, 1), 'Emission Test');

    const result = await processReminders();

    const rows = await db
      .select()
      .from(reminders)
      .where(like(reminders.title, 'Emission Test expiring in 1 day(s)'));
    expect(rows).toHaveLength(1);
    expect(rows[0].status).toBe('pending');
    // Python increments `sent` whenever a reminder row is created, regardless of FCM outcome.
    expect(result.sent).toBeGreaterThanOrEqual(1);
  });

  it('ignores documents whose expiry is off-threshold', async () => {
    const owner = await seedUser();
    const vehicle = await seedVehicle(owner.id);
    const today = todayUtc();
    await seedDoc(vehicle.id, addDaysUtc(today, 15), 'Off Threshold Doc');

    await processReminders();

    const rows = await db
      .select()
      .from(reminders)
      .where(like(reminders.title, 'Off Threshold Doc%'));
    expect(rows).toHaveLength(0);
  });

  it('is idempotent — second run does not create duplicate reminders', async () => {
    const owner = await seedUser();
    const vehicle = await seedVehicle(owner.id);
    const today = todayUtc();
    await seedDoc(vehicle.id, addDaysUtc(today, 30), 'Idempotent Doc');

    const first = await processReminders();
    const second = await processReminders();

    const rows = await db
      .select()
      .from(reminders)
      .where(like(reminders.title, 'Idempotent Doc%'));
    expect(rows).toHaveLength(1);
    expect(first.sent).toBeGreaterThanOrEqual(1);
    expect(second.skipped).toBeGreaterThanOrEqual(1);
  });

  it('creates a credential reminder using DOC_TYPE_LABELS', async () => {
    const owner = await seedUser({ renewalRemindersEnabled: true, fcmToken: 'tok' });
    const today = todayUtc();
    await seedCredential(owner.id, addDaysUtc(today, 7), 'license');

    await processReminders();

    const rows = await db
      .select()
      .from(reminders)
      .where(like(reminders.title, "Driver's License expiring in 7 day(s)"));
    expect(rows).toHaveLength(1);
    expect(rows[0].reminderType).toBe('document_expiry');
    expect(rows[0].status).toBe('sent');
    expect(sendFcm).toHaveBeenCalledWith(
      expect.objectContaining({
        title: 'Renewal Reminder',
        body: "Your Driver's License expires in 7 day(s).",
        data: { type: 'credential_expiry', docType: 'license' },
      }),
    );
  });

  it('ignores off-threshold credentials', async () => {
    const owner = await seedUser();
    const today = todayUtc();
    await seedCredential(owner.id, addDaysUtc(today, 3), 'permit');

    await processReminders();

    const rows = await db
      .select()
      .from(reminders)
      .where(like(reminders.title, 'Driving Permit%'));
    expect(rows).toHaveLength(0);
  });

  it('returns processed/sent/skipped counts', async () => {
    const owner = await seedUser({ renewalRemindersEnabled: true, fcmToken: 'tok' });
    const vehicle = await seedVehicle(owner.id);
    const today = todayUtc();
    await seedDoc(vehicle.id, addDaysUtc(today, 30), 'Counted Doc');
    await seedCredential(owner.id, addDaysUtc(today, 7), 'license');

    const result = await processReminders();

    expect(result).toEqual(
      expect.objectContaining({
        processed: expect.any(Number),
        sent: expect.any(Number),
        skipped: expect.any(Number),
      }),
    );
    expect(result.processed).toBeGreaterThanOrEqual(2);
    expect(result.sent).toBeGreaterThanOrEqual(2);
  });
});
