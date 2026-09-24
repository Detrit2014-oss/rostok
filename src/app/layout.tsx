import type { Metadata, Viewport } from "next";
import { Nunito } from "next/font/google";
import "./globals.css";

const nunito = Nunito({
  variable: "--font-nunito",
  subsets: ["latin", "cyrillic"],
  weight: ["400", "600", "700", "800", "900"],
});

export const metadata: Metadata = {
  title: "Росток — цифровая гигиена в игровой форме",
  description:
    "Веб-демонстратор Flutter-приложения «Росток» v1.0.0: питомец растёт от минут без телефона, вечерний дневник с ИИ-садовником, челленджи с друзьями и система обновлений.",
  keywords: ["цифровой детокс", "ментальное здоровье", "Росток", "Flutter"],
  icons: {
    icon: "🌱",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  themeColor: "#4CB944",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="ru" suppressHydrationWarning>
      <body className={`${nunito.variable} antialiased`} style={{ fontFamily: "var(--font-nunito), system-ui, sans-serif" }}>
        {children}
      </body>
    </html>
  );
}
