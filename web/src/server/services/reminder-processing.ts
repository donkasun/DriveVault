import 'server-only';

import { and, eq, inArray } from 'drizzle-orm';

import { db } from '@/server/db/client';
import { documents, reminders, userDocuments, users, vehicles } from '@/server/db/schema';
import { DOC_TYPE_LABELS } from '@/server/services/driving-credentials';
import { sendFcm } from '@/server/services/fcm';

/**
 * Daily reminder scan: find expiring docs/credentials, insert reminders, send FCM.
 * Port of backend/app/services/reminder_processing.py process_reminders — faithful,
 * including the "sent" counter quirk (incremented whenever a reminder row is created,
 * regardless of whether the FCM push actually succeeded).
 */

const THRESHOLDS = [30, 7, 1]; // days before expiry

export interface ProcessRemindersResult {
  processed: number;
  sent: number;
  skipped: number;
}

/** today (UTC) as 'YYYY-MM-DD'. */
function todayUtc(): string {
  return new Date().toISOString().slice(0, 10);
}

/** today + days (UTC) as 'YYYY-MM-DD'. */
function addDaysUtc(base: string, days: number): string {
  const d = new Date(`${base}T00:00:00.000Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

async function reminderExists(
  args: { documentId?: string; userDocumentId?: string },
  dueDate: string,
): Promise<boolean> {
  const conditions = [
    eq(reminders.dueDate, dueDate),
    inArray(reminders.status, ['sent', 'pending']),
  ];
  if (args.documentId !== undefined) {
    conditions.push(eq(reminders.documentId, args.documentId));
  } else if (args.userDocumentId !== undefined) {
    conditions.push(eq(reminders.userDocumentId, args.userDocumentId));
  }
  const [row] = await db
    .select({ id: reminders.id })
    .from(reminders)
    .where(and(...conditions))
    .limit(1);
  return row !== undefined;
}

export async function processReminders(): Promise<ProcessRemindersResult> {
  const today = todayUtc();
  let processed = 0;
  let sent = 0;
  let skipped = 0;

  // ── vehicle documents ────────────────────────────────────────────────────
  for (const threshold of THRESHOLDS) {
    const targetDate = addDaysUtc(today, threshold);
    const docs = await db
      .select()
      .from(documents)
      .where(eq(documents.expiryDate, targetDate));

    for (const doc of docs) {
      processed += 1;
      const dueDate = targetDate;
      if (await reminderExists({ documentId: doc.id }, dueDate)) {
        skipped += 1;
        continue;
      }

      const [vehicle] = await db
        .select()
        .from(vehicles)
        .where(eq(vehicles.id, doc.vehicleId))
        .limit(1);
      if (!vehicle) {
        skipped += 1;
        continue;
      }
      const [user] = await db
        .select()
        .from(users)
        .where(eq(users.id, vehicle.userId))
        .limit(1);
      if (!user) {
        skipped += 1;
        continue;
      }

      const wantsFcm = user.renewalRemindersEnabled && !!user.fcmToken;
      const [reminder] = await db
        .insert(reminders)
        .values({
          vehicleId: doc.vehicleId,
          documentId: doc.id,
          reminderType: 'document_expiry',
          title: `${doc.title} expiring in ${threshold} day(s)`,
          dueDate,
          status: 'pending',
        })
        .returning();

      if (wantsFcm) {
        const ok = await sendFcm({
          token: user.fcmToken!,
          title: 'Renewal Reminder',
          body: `${doc.title} expires in ${threshold} day(s).`,
          data: { type: 'document_expiry', docType: doc.docType },
        });
        if (ok) {
          await db
            .update(reminders)
            .set({ status: 'sent' })
            .where(eq(reminders.id, reminder.id));
        }
      }
      sent += 1;
    }
  }

  // ── user driving credentials ─────────────────────────────────────────────
  for (const threshold of THRESHOLDS) {
    const targetDate = addDaysUtc(today, threshold);
    const creds = await db
      .select()
      .from(userDocuments)
      .where(eq(userDocuments.expiryDate, targetDate));

    for (const cred of creds) {
      processed += 1;
      const dueDate = targetDate;
      if (await reminderExists({ userDocumentId: cred.id }, dueDate)) {
        skipped += 1;
        continue;
      }

      const [user] = await db
        .select()
        .from(users)
        .where(eq(users.id, cred.userId))
        .limit(1);
      if (!user) {
        skipped += 1;
        continue;
      }

      const label = DOC_TYPE_LABELS[cred.docType] ?? cred.docType;
      const wantsFcm = user.renewalRemindersEnabled && !!user.fcmToken;
      const [reminder] = await db
        .insert(reminders)
        .values({
          userDocumentId: cred.id,
          reminderType: 'document_expiry',
          title: `${label} expiring in ${threshold} day(s)`,
          dueDate,
          status: 'pending',
        })
        .returning();

      if (wantsFcm) {
        const ok = await sendFcm({
          token: user.fcmToken!,
          title: 'Renewal Reminder',
          body: `Your ${label} expires in ${threshold} day(s).`,
          data: { type: 'credential_expiry', docType: cred.docType },
        });
        if (ok) {
          await db
            .update(reminders)
            .set({ status: 'sent' })
            .where(eq(reminders.id, reminder.id));
        }
      }
      sent += 1;
    }
  }

  return { processed, sent, skipped };
}
