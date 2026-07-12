import Link from "next/link";
import { SITE } from "@/lib/site";

/**
 * Yellow rounded-square tile with a dark speedometer/gauge glyph, next to
 * the "DriveVault" wordmark. Reused in the marketing header and footer.
 */
export function Logo({ withWordmark = true }: { withWordmark?: boolean }) {
  return (
    <Link
      href="/"
      className="flex items-center gap-2 rounded-md focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#171717] dark:focus-visible:outline-zinc-50"
    >
      <span
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-[#FFD600]"
        aria-hidden="true"
      >
        <svg
          viewBox="0 0 24 24"
          width="20"
          height="20"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
        >
          {/* Gauge arc */}
          <path
            d="M4 16a8 8 0 1 1 16 0"
            stroke="#171717"
            strokeWidth="2"
            strokeLinecap="round"
          />
          {/* Needle */}
          <line
            x1="12"
            y1="16"
            x2="16"
            y2="10.5"
            stroke="#171717"
            strokeWidth="2"
            strokeLinecap="round"
          />
          {/* Hub */}
          <circle cx="12" cy="16" r="1.4" fill="#171717" />
        </svg>
      </span>
      {withWordmark && (
        <span className="text-lg font-semibold tracking-tight text-[#171717] dark:text-zinc-50">
          {SITE.name}
        </span>
      )}
    </Link>
  );
}
