import { Logo } from "@/components/Logo";
import { SITE } from "@/lib/site";

export default function LandingPage() {
  return (
    <div className="flex flex-col items-center gap-8 py-16 text-center">
      <Logo withWordmark={false} />
      <div className="flex flex-col items-center gap-3">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">
          {SITE.name}
        </h1>
        <p className="text-lg text-zinc-600 dark:text-zinc-400">
          {SITE.tagline}
        </p>
      </div>
      <p className="max-w-xl text-base leading-7 text-zinc-700 dark:text-zinc-300">
        {SITE.name} is a personal vehicle records app. Keep a digital garage
        of every vehicle you own, log fuel fill-ups and maintenance history,
        and store your vehicle documents and driving credentials in one
        place. We&apos;ll remind you before your documents or licenses expire,
        so nothing slips through the cracks.
      </p>
    </div>
  );
}
