import type { Metadata } from "next";
import { LegalNotice } from "@/components/LegalNotice";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Privacy Policy",
};

const lastUpdated = new Date(SITE.lastUpdated).toLocaleDateString("en-US", {
  year: "numeric",
  month: "long",
  day: "numeric",
});

export default function PrivacyPage() {
  return (
    <article className="flex flex-col gap-8">
      <div className="flex flex-col gap-4">
        <h1 className="text-3xl font-semibold tracking-tight">
          Privacy Policy
        </h1>
        <p className="text-sm text-zinc-500 dark:text-zinc-500">
          Last updated: {lastUpdated}
        </p>
        <LegalNotice />
      </div>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">1. Introduction</h2>
        <p>
          {SITE.operator} (&quot;{SITE.name}&quot;, &quot;we&quot;,
          &quot;us&quot;) operates the {SITE.name} mobile application (the
          &quot;App&quot;), a personal vehicle record-keeping tool. This
          policy explains what information we collect, how we use it, and
          the choices you have.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">2. Information we collect</h2>
        <h3 className="text-base font-semibold">Account information</h3>
        <p>
          We use Firebase Authentication to sign you in. We do not store
          your password. Depending on your sign-in method, we receive your
          email address, display name, and profile photo URL from Firebase.
        </p>
        <h3 className="text-base font-semibold">Records you enter</h3>
        <p>The App lets you store records you create yourself, including:</p>
        <ul className="list-disc pl-6 leading-7">
          <li>
            Vehicle details: make, model, year, registration number, VIN, and
            mileage/odometer readings, plus purchase information.
          </li>
          <li>Fuel logs (fill-up dates, amounts, cost, odometer readings).</li>
          <li>Maintenance records (service history, dates, cost, notes).</li>
          <li>
            Vehicle document metadata (e.g. insurance, registration papers).
          </li>
          <li>
            Driving credentials: license, permit, and international license
            numbers and their expiry dates.
          </li>
        </ul>
        <p>
          This data is stored in our PostgreSQL database, hosted by Neon.
        </p>
        <h3 className="text-base font-semibold">Uploaded files</h3>
        <p>
          When you upload a document or photo, the file itself is stored by
          Cloudinary, our file-storage provider. The App server never
          receives the file bytes — it only stores the resulting secure URL
          so it can display or link to your file later.
        </p>
        <h3 className="text-base font-semibold">Push notifications</h3>
        <p>
          If you enable reminders, we store a Firebase Cloud Messaging (FCM)
          device token so we can send you renewal reminders for documents
          and driving credentials that are about to expire. You can disable
          reminders at any time in the App&apos;s settings.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">3. How we use your information</h2>
        <p>
          We use the information above solely to operate the App: to
          authenticate you, to store and display the vehicle records you
          create, to host files you upload, and to send you the renewal
          reminders you&apos;ve opted into. We do not sell your data or use it
          for advertising.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">
          4. Sharing and sub-processors
        </h2>
        <p>
          We share data only with the service providers that help us run the
          App (our &quot;sub-processors&quot;), and only to the extent needed
          to provide the service:
        </p>
        <ul className="list-disc pl-6 leading-7">
          <li>
            <strong>Firebase / Google</strong> — authentication and push
            notifications.
          </li>
          <li>
            <strong>Cloudinary</strong> — storage of uploaded files (photos,
            documents).
          </li>
          <li>
            <strong>Neon</strong> — hosting of our PostgreSQL database.
          </li>
          <li>
            <strong>App hosting provider</strong> (e.g. Vercel or Google
            Cloud) — hosting of the App&apos;s backend and web pages.
          </li>
        </ul>
        <p>
          We do not otherwise share your personal data with third parties,
          except where required by law.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">5. Data retention</h2>
        <p>
          We keep your account and record data for as long as your account
          is active. If you delete your account or request deletion (see
          &quot;Your rights&quot; below), we delete your records and uploaded
          files within a reasonable period, except where we&apos;re required
          to retain information for legal or security purposes.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">6. Security</h2>
        <p>
          We rely on our providers&apos; security controls (Firebase, Neon,
          Cloudinary) and apply reasonable technical and organizational
          measures to protect your data. No method of transmission or
          storage is 100% secure, and we cannot guarantee absolute security.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">7. Your rights</h2>
        <p>
          You may access, correct, or delete your data at any time from
          within the App, or by contacting us at{" "}
          <a
            href={`mailto:${SITE.contactEmail}`}
            className="font-medium underline underline-offset-2"
          >
            {SITE.contactEmail}
          </a>
          . Depending on your location, you may have additional rights under
          laws such as the GDPR or CCPA; we will honor applicable requests to
          the extent required by law.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">8. Children&apos;s use</h2>
        <p>
          The App is not directed to children and is not intended for use by
          anyone under the age of 16. We do not knowingly collect data from
          children.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">9. Changes to this policy</h2>
        <p>
          We may update this policy from time to time. We will update the
          &quot;Last updated&quot; date above when we do. Continued use of the
          App after changes means you accept the updated policy.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">10. Contact us</h2>
        <p>
          Questions about this policy, or about your data, can be sent to{" "}
          <a
            href={`mailto:${SITE.contactEmail}`}
            className="font-medium underline underline-offset-2"
          >
            {SITE.contactEmail}
          </a>
          . We operate out of {SITE.jurisdiction}.
        </p>
      </section>
    </article>
  );
}
