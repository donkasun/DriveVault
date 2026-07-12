import type { Metadata } from "next";
import { SITE } from "@/lib/site";

export const metadata: Metadata = {
  title: "Support",
};

export default function SupportPage() {
  return (
    <div className="flex flex-col gap-8">
      <div className="flex flex-col gap-4">
        <h1 className="text-3xl font-semibold tracking-tight">Support</h1>
        <p className="text-base leading-7 text-zinc-700 dark:text-zinc-300">
          Need help with {SITE.name}? We&apos;re happy to help — reach out by
          email and we&apos;ll get back to you as soon as we can.
        </p>
      </div>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">Contact us</h2>
        <p>
          Email us at{" "}
          <a
            href={`mailto:${SITE.contactEmail}`}
            className="font-medium underline underline-offset-2"
          >
            {SITE.contactEmail}
          </a>
          . {SITE.name} is a small, independently operated app, so please
          allow a few business days for a response.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">Report a bug</h2>
        <p>
          If something isn&apos;t working as expected, email us at{" "}
          <a
            href={`mailto:${SITE.contactEmail}`}
            className="font-medium underline underline-offset-2"
          >
            {SITE.contactEmail}
          </a>{" "}
          with a description of the issue, the steps to reproduce it, and
          your device/app version if you have it. Screenshots are always
          helpful.
        </p>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xl font-semibold">
          Request account or data deletion
        </h2>
        <p>
          To request deletion of your account and associated data, email{" "}
          <a
            href={`mailto:${SITE.contactEmail}`}
            className="font-medium underline underline-offset-2"
          >
            {SITE.contactEmail}
          </a>{" "}
          from the email address associated with your account, with the
          subject line &quot;Account deletion request&quot;. We&apos;ll
          confirm once your account and records have been deleted.
        </p>
      </section>
    </div>
  );
}
