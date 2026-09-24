"use client";

import { C } from "@/lib/ttg/types";
import type { LucideIcon } from "lucide-react";
import type { CSSProperties, ReactNode } from "react";

/** Рисованая монетка (v1.9.0) — вместо эмодзи 🪙, который на части
 *  устройств Android отображается пустым квадратом. */
export function Coin({ size = 18, className = "" }: { size?: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 20 20" aria-hidden="true" className={className}>
      <circle cx="10" cy="10" r="10" fill="#E0A800" />
      <circle cx="10" cy="9.4" r="9.2" fill="#FFC800" />
      <circle cx="10" cy="9.4" r="6.2" fill="#FFDD55" />
      <polygon
        points="10,5.5 10.97,8.06 13.71,8.19 11.57,9.91 12.29,12.56 10,11.05 7.71,12.56 8.43,9.91 6.29,8.19 9.03,8.06"
        fill="#E0A800"
      />
    </svg>
  );
}

/** «N [монетка]» — сумма с рисованой монеткой. */
export function CoinText({
  amount,
  textSize = 14,
  className = "",
  color,
}: {
  amount: number;
  textSize?: number;
  className?: string;
  color?: string;
}) {
  return (
    <span className={`inline-flex items-center gap-1 ${className}`}>
      <span className="font-extrabold" style={{ fontSize: textSize, color }}>
        {amount}
      </span>
      <Coin size={textSize * 0.95} />
    </span>
  );
}

/** Белый чип с монеткой для шапки главного экрана. */
export function CoinChip({ amount }: { amount: number }) {
  return (
    <div className="inline-flex items-center gap-1.5 rounded-full border-[1.5px] border-white bg-white/[0.85] px-2.5 py-1.5">
      <Coin size={15} />
      <span className="text-[12.5px] font-bold" style={{ color: C.ink }}>
        {amount}
      </span>
    </div>
  );
}

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
