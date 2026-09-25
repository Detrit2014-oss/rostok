import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  // Разрешаем загрузку dev-ресурсов с превью-домена (иначе Next 16+ блокирует).
  allowedDevOrigins: [
    "preview-*.space-z.ai",
    "preview-chat-*.space-z.ai",
    "*.space-z.ai",
  ],
  /* config options here */
  typescript: {
    ignoreBuildErrors: true,
  },
  reactStrictMode: false,
};

export default nextConfig;
