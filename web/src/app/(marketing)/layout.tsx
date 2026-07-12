import Link from "next/link";
import { Logo } from "@/components/Logo";
import { SITE } from "@/lib/site";

const NAV_LINKS = [
  { href: "/privacy", label: "Privacy" },
  { href: "/terms", label: "Terms" },
  { href: "/support", label: "Support" },
];

export default function MarketingLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  const year = new Date().getFullYear();

  return (
    <div className="flex min-h-full flex-1 flex-col bg-white text-[#171717] dark:bg-[#0A0A0A] dark:text-zinc-50">
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:absolute focus:left-4 focus:top-4 focus:z-50 focus:rounded-md focus:bg-[#FFD600] focus:px-4 focus:py-2 focus:text-sm focus:font-medium focus:text-[#171717]"
      >
        Skip to content
      </a>

      <header className="border-b border-zinc-200 dark:border-zinc-800">
        <div className="mx-auto flex w-full max-w-4xl items-center justify-between px-6 py-4">
          <Logo />
          <nav aria-label="Main">
            <ul className="flex items-center gap-6 text-sm font-medium">
              {NAV_LINKS.map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className="rounded-sm text-zinc-700 hover:text-[#171717] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#171717] dark:text-zinc-300 dark:hover:text-zinc-50 dark:focus-visible:outline-zinc-50"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
        </div>
      </header>

      <main id="main-content" className="mx-auto w-full max-w-4xl flex-1 px-6 py-12">
        {children}
      </main>

      <footer className="border-t border-zinc-200 dark:border-zinc-800">
        <div className="mx-auto flex w-full max-w-4xl flex-col items-start justify-between gap-6 px-6 py-8 sm:flex-row sm:items-center">
          <Logo />
          <nav aria-label="Footer">
            <ul className="flex flex-wrap items-center gap-6 text-sm text-zinc-600 dark:text-zinc-400">
              {NAV_LINKS.map((link) => (
                <li key={link.href}>
                  <Link
                    href={link.href}
                    className="rounded-sm hover:text-[#171717] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#171717] dark:hover:text-zinc-50 dark:focus-visible:outline-zinc-50"
                  >
                    {link.label}
                  </Link>
                </li>
              ))}
            </ul>
          </nav>
          <p className="text-sm text-zinc-500 dark:text-zinc-500">
            © {year} {SITE.name}
          </p>
        </div>
      </footer>
    </div>
  );
}
