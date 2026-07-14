import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Emit .next/standalone so the Cloud Run image ships only the traced runtime
  // files rather than the whole node_modules tree.
  output: "standalone",
};

export default nextConfig;
