import 'server-only';

import { firebaseMessaging } from '@/server/auth/firebase-admin';

export interface FcmMessage {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Best-effort FCM send. Returns true on success, false on any failure (logged,
 * never throws). Mirrors reminder_processing._send_fcm.
 */
export async function sendFcm(message: FcmMessage): Promise<boolean> {
  try {
    await firebaseMessaging.send({
      notification: { title: message.title, body: message.body },
      data: message.data ?? {},
      token: message.token,
    });
    return true;
  } catch (err) {
    console.warn('FCM send failed:', err);
    return false;
  }
}
