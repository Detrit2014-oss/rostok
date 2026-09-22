"use client";

import { C } from "@/lib/ttg/types";
import type { LucideIcon } from "lucide-react";
import type { CSSProperties, ReactNode } from "react";

/** Карточка в игровом стиле: белый фон, рамка 2px, крупные скругления. */
export function InfoCard({
  children,
  className = "",
  style,
}: {
  children: ReactNode;
  className?: string;
  style?: CSSProperties;
}) {
  return (
    <div
      className={`w-full rounded-[20px] border-2 bg-white p-4 ${className}`}
      style={{ borderColor: C.border, ...style }}
    >
      {children}
    </div>
  );
}

/** «Пухлая» кнопка Duolingo: жёсткая тень снизу, нажатие — сдвиг. */
export function BigButton({
  label,
  icon: Icon,
  onClick,
  color = C.green,
  shadow = C.greenDark,
  textColor = "#FFFFFF",
  disabled = false,
  fullWidth = false,
  className = "",
}: {
  label: string;
  icon?: LucideIcon;
  onClick?: () => void;
  color?: string;
  shadow?: string;
  textColor?: string;
  disabled?: boolean;
  fullWidth?: boolean;
  className?: string;
}) {
  const bg = disabled ? "#E5E5E5" : color;
  const sh = disabled ? "#CCCCCC" : shadow;
  const fg = disabled ? "#AFAFAF" : textColor;
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      className={`group relative inline-flex select-none items-center justify-center gap-2 rounded-2xl px-[18px] py-3.5 text-base font-extrabold transition-transform active:translate-y-1 active:shadow-none ${fullWidth ? "w-full" : ""} ${className}`}
      style={{ backgroundColor: bg, color: fg, boxShadow: `0 4px 0 0 ${sh}` }}
    >
      {Icon && <Icon size={22} strokeWidth={2.5} />}
      <span className="text-center leading-tight">{label}</span>
    </button>
  );
}

export function OutlineButton({
  label,
  icon: Icon,
  onClick,
  fullWidth = false,
  className = "",
}: {
  label: string;
  icon?: LucideIcon;
  onClick?: () => void;
  fullWidth?: boolean;
  className?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`inline-flex items-center justify-center gap-2 rounded-2xl border-2 bg-white px-[18px] py-3 text-[15px] font-bold transition-colors hover:bg-neutral-50 ${fullWidth ? "w-full" : ""} ${className}`}
      style={{ borderColor: C.border, color: C.ink }}
    >
      {Icon && <Icon size={20} strokeWidth={2.5} />}
      <span className="text-center leading-tight">{label}</span>
    </button>
  );
}

/** Плитка статистики для Профиля. */
export function StatTile({
  icon: Icon,
  value,
  label,
  color = C.green,
}: {
  icon: LucideIcon;
  value: string;
  label: string;
  color?: string;
}) {
  return (
    <InfoCard className="flex flex-col items-center justify-center !p-2.5 text-center">
      <span
        className="flex h-10 w-10 items-center justify-center rounded-full"
        style={{ backgroundColor: `${color}26` }}
      >
        <Icon size={22} style={{ color }} />
      </span>
      <span className="mt-1.5 text-[16px] font-extrabold" style={{ color: C.ink }}>
        {value}
      </span>
      <span className="mt-0.5 text-[11px] leading-tight" style={{ color: C.inkSoft }}>
        {label}
      </span>
    </InfoCard>
  );
}

export function Chip({ icon: Icon, text }: { icon: LucideIcon; text: string }) {
  return (
    <div
      className="inline-flex items-center gap-1.5 rounded-full border-[1.5px] border-white bg-white/[0.85] px-2.5 py-1.5"
      style={{ color: C.ink }}
    >
      <Icon size={16} style={{ color: C.greenDark }} />
      <span className="text-[12.5px] font-bold">{text}</span>
    </div>
  );
}

export function ProgressBar({
  value,
  height = 10,
  bg = "#EFEFEF",
  color = C.green,
}: {
  value: number;
  height?: number;
  bg?: string;
  color?: string;
}) {
  return (
    <div className="w-full overflow-hidden rounded-lg" style={{ height, backgroundColor: bg }}>
      <div
        className="h-full rounded-lg transition-[width] duration-500"
        style={{ width: `${Math.min(100, Math.max(0, value * 100))}%`, backgroundColor: color }}
      />
    </div>
  );
}
