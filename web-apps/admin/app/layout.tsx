import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/shell/Sidebar";
import { Topbar } from "@/components/shell/Topbar";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Nutrimate Admin",
  description: "Administer the Nutrimate food database, nutrients, users and reminders.",
  robots: { index: false, follow: false },
  icons: { icon: "/logo.png", apple: "/logo.png" },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>
        <div className="min-h-screen grid grid-cols-[240px_1fr] [&:has(.login-page)]:grid-cols-1">
          <Sidebar />
          <div className="flex flex-col min-w-0">
            <Topbar />
            <main className="flex-1">{children}</main>
          </div>
        </div>
      </body>
    </html>
  );
}
