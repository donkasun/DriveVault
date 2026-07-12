/**
 * Yellow-tinted callout with dark ink text (never yellow text on white),
 * shown at the top of legal pages.
 */
export function LegalNotice() {
  return (
    <div className="rounded-lg bg-[#FFD600] px-4 py-3 text-sm text-[#171717]">
      <strong className="font-semibold">Template notice:</strong> This is a
      template policy provided as a starting point. Have it reviewed by a
      qualified professional before public launch.
    </div>
  );
}
