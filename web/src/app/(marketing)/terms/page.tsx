import type { Metadata } from "next";
import { LegalNotice } from "@/components/LegalNotice";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Terms of Service",
};

const lastUpdated = new Date(SITE.lastUpdated).toLocaleDateString("en-US", {
  year: "numeric",
  month: "long",
  day: "numeric",
});

export default function TermsPage() {
  return (
    <article className="flex flex-col gap-8">
      <div className="flex flex-col gap-4">
        <h1 className="text-3xl font-semibold tracking-tight">
          Terms of Service
        </h1>
        <p className="text-sm text-zinc-500 dark:text-zinc-500">
          Last updated: {lastUpdated}
        </p>
        <LegalNotice />
      </div>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">1. Acceptance of terms</h2>
        <p>
          By creating an account or using the {SITE.name} mobile application
          (the &quot;App&quot;), you agree to these Terms of Service. If you
          do not agree, please do not use the App.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">2. Description of service</h2>
        <p>
          {SITE.name} is a personal record-keeping tool that lets you track
          vehicles, fuel logs, maintenance history, documents, and driving
          credentials, and receive optional reminders about upcoming
          expirations. It is provided for personal, informational use.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">3. Account responsibilities</h2>
        <p>
          You are responsible for maintaining the security of your account
          and for all activity that occurs under it. You must provide
          accurate information and promptly update it if it changes. Notify
          us if you believe your account has been compromised.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">4. Acceptable use</h2>
        <p>
          You agree not to misuse the App, including by: attempting to
          access another user&apos;s data, interfering with the App&apos;s
          operation, uploading unlawful content, or using the App for any
          purpose other than tracking your own vehicle records.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">5. Your content</h2>
        <p>
          You own the vehicle records, documents, and other content you
          submit to the App (&quot;your content&quot;). By using the App, you
          grant us a limited license to store, process, and display your
          content solely for the purpose of providing the service to you. We
          do not claim ownership of your content.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">6. Disclaimers</h2>
        <p>
          The App is provided &quot;as is&quot; and &quot;as available&quot;,
          without warranties of any kind, express or implied. {SITE.name} is a
          personal record-keeping aid only and is{" "}
          <strong>not a substitute</strong> for official renewal, licensing,
          insurance, or regulatory compliance obligations. Expiry reminders
          are provided on a best-effort basis and may be delayed, not
          delivered, or inaccurate — you remain solely responsible for
          tracking and meeting your own legal and regulatory deadlines.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">7. Limitation of liability</h2>
        <p>
          To the maximum extent permitted by law, {SITE.operator} shall not
          be liable for any indirect, incidental, special, or consequential
          damages, or any loss of data, revenue, or profits, arising out of
          or in connection with your use of the App, including reliance on
          any reminder or record stored in it.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">8. Termination</h2>
        <p>
          You may stop using the App and request deletion of your account at
          any time (see the Support page). We may suspend or terminate
          access to the App if we believe these terms have been violated.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">9. Changes to these terms</h2>
        <p>
          We may update these terms from time to time. We will update the
          &quot;Last updated&quot; date above when we do. Continued use of the
          App after changes means you accept the updated terms.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">10. Governing law</h2>
        <p>
          These terms are governed by the laws of {SITE.jurisdiction},
          without regard to conflict-of-law principles.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">11. Contact us</h2>
        <p>
          Questions about these terms can be sent to{" "}
          <a
            href={`mailto:${SITE.contactEmail}`}
            className="font-medium underline underline-offset-2"
          >
            {SITE.contactEmail}
          </a>
          .
        </p>
      </section>
    </article>
  );
}
