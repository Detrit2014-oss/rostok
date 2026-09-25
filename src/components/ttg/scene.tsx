"use client";

// Порт lib/widgets/pet_canvas.dart: небо, солнце, облака, лужайка
// и питомцы, нарисованные полностью процедурно (SVG) — ни одной картинки.

import type { CSSProperties } from "react";

import { bodyColor, isPlant, Pet, petStage, stageProgress } from "@/lib/ttg/types";
import type { PetType } from "@/lib/ttg/types";

const GROUND_Y = 182.4; // 0.76 * 240
const BEAK = "#FF9500";
const DARK = "#3A3A3A";
const SPIKE = "#8B5E34";
const CRACK = "#C9A96E";

function Cloud({
  cx,
  cy,
  r,
  dur,
  delay,
}: {
  cx: number;
  cy: number;
  r: number;
  dur: number;
  delay: number;
}) {
  return (
    <g
      className="ttg-drift"
      style={{ animationDuration: `${dur}s`, animationDelay: `${delay}s` }}
    >
      <circle cx={cx - r * 0.8} cy={cy + r * 0.25} r={r * 0.65} fill="#FFFFFF" opacity="0.9" />
      <circle cx={cx} cy={cy} r={r} fill="#FFFFFF" opacity="0.9" />
      <circle cx={cx + r * 0.8} cy={cy + r * 0.25} r={r * 0.6} fill="#FFFFFF" opacity="0.9" />
    </g>
  );
}

/**
 * Большое яйцо (v1.2.0): в ~1,8 раза крупнее прежнего, растёт с прогрессом,
 * заметно покачивается перед вылуплением и покрывается трещинками.
 */
function Egg({ spot, progress }: { spot: string; progress: number }) {
  const eggS = 0.95 + 0.45 * progress;
  const w = 34 * eggS;
  const h = 44 * eggS;
  const wobbleDeg = (1.5 + 4 * progress).toFixed(1);
  return (
    <g
      className="ttg-egg"
      style={{ "--wobble": `${wobbleDeg}deg` } as CSSProperties}
    >
      <ellipse cx={0} cy={-h / 2} rx={w / 2} ry={h / 2} fill="#FFF6E3" />
      <ellipse
        cx={0}
        cy={-h / 2}
        rx={w / 2 - w * 0.12}
        ry={h / 2 - w * 0.12}
        fill="#FFFBF0"
      />
      <circle cx={-w * 0.18} cy={-h * 0.55} r={3.5 * eggS} fill={spot} opacity="0.65" />
      <circle cx={w * 0.15} cy={-h * 0.35} r={2.6 * eggS} fill={spot} opacity="0.65" />
      <circle cx={-w * 0.05} cy={-h * 0.75} r={2.0 * eggS} fill={spot} opacity="0.65" />
      {/* Трещинки: первая после ~45%, вторая после ~75% прогресса */}
      {progress > 0.45 && (
        <polyline
          points={`0,${-h * 0.78} ${w * 0.14},${-h * 0.66} ${-w * 0.07},${-h * 0.54} ${w * 0.1},${-h * 0.44}`}
          fill="none"
          stroke={CRACK}
          strokeWidth="2.2"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      )}
      {progress > 0.75 && (
        <polyline
          points={`${-w * 0.05},${-h * 0.52} ${-w * 0.2},${-h * 0.4} ${w * 0.02},${-h * 0.28}`}
          fill="none"
          stroke={CRACK}
          strokeWidth="2.2"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      )}
    </g>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Анатомия v2 — мультяшная, но узнаваемая: у каждого вида есть голова,
// туловище, лапы, хвост/крылья/колючки и своя морда. Тело больше не
// «шарик», ноги не «палочки». Координаты — для масштаба s = 1 (лапы на
// y = 0, вверх — отрицательно); весь вид масштабируется группой scale(s).
// ─────────────────────────────────────────────────────────────────────

interface ArtProps {
  sleeping: boolean;
}

/** Смешивает hex к белому (f > 0) или к чёрному (f < 0). */
function shade(hex: string, f: number): string {
  const h = hex.replace("#", "");
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  const m = (c: number) =>
    Math.round(
      Math.max(0, Math.min(255, f >= 0 ? c + (255 - c) * f : c * (1 + f)))
    );
  const to = (n: number) => n.toString(16).padStart(2, "0");
  return `#${to(m(r))}${to(m(g))}${to(m(b))}`;
}

/** Большие выразительные глаза: белок, зрачок, блик; моргание CSS-классом. */
function Eyes({
  dx,
  y,
  r = 6,
  sleeping,
}: {
  dx: number;
  y: number;
  r?: number;
  sleeping: boolean;
}) {
  if (sleeping) {
    return (
      <g stroke="#33261A" strokeWidth="2.3" strokeLinecap="round" fill="none">
        <path d={`M ${-dx - r * 0.5} ${y} Q ${-dx} ${y + r * 0.7} ${-dx + r * 0.5} ${y}`} />
        <path d={`M ${dx - r * 0.5} ${y} Q ${dx} ${y + r * 0.7} ${dx + r * 0.5} ${y}`} />
      </g>
    );
  }
  return (
    <g className="ttg-blink" style={{ transformBox: "fill-box", transformOrigin: "center" }}>
      <circle cx={-dx} cy={y} r={r} fill="#FFFFFF" />
      <circle cx={dx} cy={y} r={r} fill="#FFFFFF" />
      <circle cx={-dx + 1.1} cy={y + 0.9} r={r * 0.52} fill="#33261A" />
      <circle cx={dx + 1.1} cy={y + 0.9} r={r * 0.52} fill="#33261A" />
      <circle cx={-dx + 2} cy={y - r * 0.32} r={r * 0.17} fill="#FFFFFF" />
      <circle cx={dx + 2} cy={y - r * 0.32} r={r * 0.17} fill="#FFFFFF" />
    </g>
  );
}

function Blush({
  dx,
  y,
  r = 4,
  opacity = 0.5,
}: {
  dx: number;
  y: number;
  r?: number;
  opacity?: number;
}) {
  return (
    <g fill="#FF8FA3" opacity={opacity}>
      <circle cx={-dx} cy={y} r={r} />
      <circle cx={dx} cy={y} r={r} />
    </g>
  );
}

/** ЛИСЁНОК: острая морда с носом, большие уши, пышный хвост с белым кончиком. */
function FoxArt({ sleeping }: ArtProps) {
  const body = bodyColor("fox");
  const cream = "#FFF6EA";
  const dark = shade(body, -0.16);
  return (
    <g>
      {/* Хвост — пышный, набок, с кремовым кончиком */}
      <ellipse cx={27} cy={-32} rx={11.5} ry={18} fill={body} transform="rotate(38 27 -32)" />
      <circle cx={37} cy={-46} r={6.5} fill={cream} />
      {/* Тело + грудка */}
      <ellipse cx={0} cy={-17} rx={17} ry={14} fill={body} />
      <ellipse cx={0} cy={-13} rx={9.5} ry={10} fill={cream} />
      {/* Лапы */}
      <ellipse cx={-8.5} cy={-3.2} rx={5.6} ry={4.2} fill={dark} />
      <ellipse cx={8.5} cy={-3.2} rx={5.6} ry={4.2} fill={dark} />
      {/* Бакенбарды-шерсть по бокам головы */}
      <path d="M -21 -40 L -30 -33 L -19 -30 Z" fill={cream} />
      <path d="M 21 -40 L 30 -33 L 19 -30 Z" fill={cream} />
      {/* Голова */}
      <ellipse cx={0} cy={-46} rx={23} ry={19.5} fill={body} />
      {/* Уши: треугольные, с розовой серединкой */}
      <path d="M -18 -57 L -27 -79 L -5 -66 Z" fill={body} stroke={body} strokeWidth="3" strokeLinejoin="round" />
      <path d="M 18 -57 L 27 -79 L 5 -66 Z" fill={body} stroke={body} strokeWidth="3" strokeLinejoin="round" />
      <path d="M -17 -60 L -22.5 -73.5 L -9.5 -65.5 Z" fill="#E8938F" />
      <path d="M 17 -60 L 22.5 -73.5 L 9.5 -65.5 Z" fill="#E8938F" />
      {/* Морда: кремовый клин, чёрный нос, улыбка */}
      <path d="M -10.5 -46 Q 0 -51 10.5 -46 Q 9 -34.5 0 -32.5 Q -9 -34.5 -10.5 -46 Z" fill={cream} />
      <path d="M -3.2 -44.2 Q 0 -46.4 3.2 -44.2 Q 2 -41.4 0 -41.4 Q -2 -41.4 -3.2 -44.2 Z" fill={DARK} />
      <path
        d="M 0 -41.4 L 0 -38.6 M 0 -38.6 Q -3.2 -35.8 -5.8 -38 M 0 -38.6 Q 3.2 -35.8 5.8 -38"
        stroke="#4A3B2A"
        strokeWidth="1.9"
        strokeLinecap="round"
        fill="none"
      />
      <Blush dx={17} y={-44} r={4} opacity={0.45} />
      <Eyes dx={9.5} y={-50} r={6.2} sleeping={sleeping} />
    </g>
  );
}

/** КОТИК: треугольные уши, полоски на лбу, усы, хвост трубой с тёмным кончиком. */
function CatArt({ sleeping }: ArtProps) {
  const body = bodyColor("cat");
  const cream = "#F6FAFD";
  const dark = shade(body, -0.2);
  return (
    <g>
      {/* Хвост — изогнут вверх, с тёмным кончиком */}
      <path
        d="M 11 -14 Q 31 -16 28.5 -38 Q 27.5 -47 20 -49"
        stroke={body}
        strokeWidth="7.5"
        fill="none"
        strokeLinecap="round"
      />
      <circle cx={20} cy={-49} r={3.8} fill={dark} />
      {/* Тело */}
      <ellipse cx={0} cy={-16} rx={16} ry={13.5} fill={body} />
      <ellipse cx={0} cy={-12.5} rx={8.5} ry={9} fill={cream} />
      {/* Лапы */}
      <ellipse cx={-7.5} cy={-3} rx={5.4} ry={4} fill={dark} />
      <ellipse cx={7.5} cy={-3} rx={5.4} ry={4} fill={dark} />
      {/* Голова */}
      <ellipse cx={0} cy={-44} rx={21} ry={18} fill={body} />
      {/* Уши — со скруглением, розовая серединка */}
      <path d="M -18.5 -52 L -23 -70 L -6.5 -60 Z" fill={body} stroke={body} strokeWidth="3.4" strokeLinejoin="round" />
      <path d="M 18.5 -52 L 23 -70 L 6.5 -60 Z" fill={body} stroke={body} strokeWidth="3.4" strokeLinejoin="round" />
      <path d="M -17.5 -55 L -20 -65 L -10.5 -59.5 Z" fill="#F0A8B8" />
      <path d="M 17.5 -55 L 20 -65 L 10.5 -59.5 Z" fill="#F0A8B8" />
      {/* Полоски на лбу */}
      <g fill={dark} opacity="0.75">
        <rect x={-8.6} y={-62.5} width={3.6} height={7.5} rx={1.8} />
        <rect x={-1.8} y={-64} width={3.6} height={8.5} rx={1.8} />
        <rect x={5} y={-62.5} width={3.6} height={7.5} rx={1.8} />
      </g>
      {/* Нос, улыбка, усы */}
      <path d="M -2.9 -40.6 Q 0 -42.6 2.9 -40.6 Q 1.9 -38.2 0 -38.2 Q -1.9 -38.2 -2.9 -40.6 Z" fill="#E58FA2" />
      <path
        d="M 0 -38.2 L 0 -36.2 M 0 -36.2 Q -3 -33.6 -5.4 -35.6 M 0 -36.2 Q 3 -33.6 5.4 -35.6"
        stroke="#4A3B2A"
        strokeWidth="1.8"
        strokeLinecap="round"
        fill="none"
      />
      <g stroke="#5F7182" strokeWidth="1.5" strokeLinecap="round">
        <path d="M 16 -39.5 L 25.5 -41" />
        <path d="M 16 -36.8 L 25 -35.2" />
        <path d="M -16 -39.5 L -25.5 -41" />
        <path d="M -16 -36.8 L -25 -35.2" />
      </g>
      <Blush dx={15} y={-42} r={3.6} opacity={0.45} />
      <Eyes dx={8.5} y={-46.5} r={6} sleeping={sleeping} />
    </g>
  );
}

/** СОВЁНОК: лицевой диск, кисточки, перья-дуги на животе, лапки-коготки. */
function OwlArt({ sleeping }: ArtProps) {
  const body = bodyColor("owl");
  const light = "#EDE3FA";
  const dark = shade(body, -0.15);
  return (
    <g>
      {/* Кисточки на голове */}
      <path d="M -19 -54 L -16.5 -71 L -7 -57 Z" fill={body} stroke={body} strokeWidth="3" strokeLinejoin="round" />
      <path d="M 19 -54 L 16.5 -71 L 7 -57 Z" fill={body} stroke={body} strokeWidth="3" strokeLinejoin="round" />
      {/* Корпус-яйцо */}
      <ellipse cx={0} cy={-30} rx={22} ry={27} fill={body} />
      {/* Животик с перьями-дугами */}
      <ellipse cx={0} cy={-16} rx={12.5} ry={13} fill={light} />
      <g stroke={shade(body, -0.1)} strokeWidth="1.6" fill="none" strokeLinecap="round">
        <path d="M -8 -14 Q -4 -10.5 0 -14 Q 4 -10.5 8 -14" />
        <path d="M -8 -8.5 Q -4 -5 0 -8.5 Q 4 -5 8 -8.5" />
      </g>
      {/* Крылья */}
      <ellipse cx={-20.5} cy={-19} rx={6} ry={11.5} fill={dark} transform="rotate(14 -20.5 -19)" />
      <ellipse cx={20.5} cy={-19} rx={6} ry={11.5} fill={dark} transform="rotate(-14 20.5 -19)" />
      {/* Лицевой диск: два белых круга + клюв */}
      <circle cx={-8.5} cy={-44} r={10.5} fill="#FFFFFF" />
      <circle cx={8.5} cy={-44} r={10.5} fill="#FFFFFF" />
      <path d="M -4.6 -36.5 L 4.6 -36.5 L 0 -29 Z" fill="#FFB703" />
      {/* Лапки-коготки */}
      <g fill="#FFB703">
        <ellipse cx={-7} cy={-2.2} rx={5} ry={2.8} />
        <ellipse cx={7} cy={-2.2} rx={5} ry={2.8} />
      </g>
      <Blush dx={15.5} y={-36} r={3.6} opacity={0.4} />
      <Eyes dx={8.5} y={-44} r={4.9} sleeping={sleeping} />
    </g>
  );
}

/** ДРАКОНЧИК: крылья, рога, шип, морда с ноздрями, брюшные пластинки, хвост-стрела. */
function DragonArt({ sleeping }: ArtProps) {
  const body = bodyColor("dragon");
  const light = "#D8F3C8";
  const dark = shade(body, -0.22);
  return (
    <g>
      {/* Крылья за телом */}
      <path d="M -13 -36 Q -34 -54 -29 -30 Q -26.5 -19 -13 -23 Z" fill={dark} />
      <path d="M 13 -36 Q 34 -54 29 -30 Q 26.5 -19 13 -23 Z" fill={dark} />
      {/* Хвост с наконечником-стрелой */}
      <path d="M 11 -13 Q 30 -11 33.5 -28" stroke={body} strokeWidth="7.5" fill="none" strokeLinecap="round" />
      <path d="M 30.5 -32.5 L 40.5 -33.5 L 33.5 -22.5 Z" fill={dark} />
      {/* Тело с брюшными пластинками */}
      <ellipse cx={0} cy={-16} rx={17} ry={14} fill={body} />
      <g fill={light}>
        <rect x={-8.5} y={-21.5} width={17} height={4.6} rx={2.3} />
        <rect x={-6.8} y={-15.4} width={13.6} height={4.4} rx={2.2} />
        <rect x={-4.6} y={-9.8} width={9.2} height={4.2} rx={2.1} />
      </g>
      {/* Лапы */}
      <ellipse cx={-7.5} cy={-3} rx={5.4} ry={4} fill={dark} />
      <ellipse cx={7.5} cy={-3} rx={5.4} ry={4} fill={dark} />
      {/* Голова + морда с ноздрями */}
      <ellipse cx={0} cy={-44} rx={21} ry={18} fill={body} />
      <ellipse cx={0} cy={-36.5} rx={11} ry={7} fill={shade(body, 0.28)} />
      <circle cx={-3.6} cy={-37.6} r={1.25} fill={DARK} />
      <circle cx={3.6} cy={-37.6} r={1.25} fill={DARK} />
      {/* Рога и шип на лбу */}
      <path d="M -12.5 -55.5 L -17 -68 L -6.5 -58.5 Z" fill="#F6E7C1" />
      <path d="M 12.5 -55.5 L 17 -68 L 6.5 -58.5 Z" fill="#F6E7C1" />
      <path d="M -3.4 -60.5 L -1.2 -67.5 L 2.6 -60.8 Z" fill="#F6E7C1" />
      <Blush dx={16} y={-42} r={3.8} opacity={0.4} />
      <Eyes dx={9} y={-47} r={6} sleeping={sleeping} />
    </g>
  );
}

/** УТЁНОК: широкий клюв, хохолок, крылышки, хвостовые пёрышки, лапки-ласты. */
function DuckArt({ sleeping }: ArtProps) {
  const body = bodyColor("duck");
  const dark = shade(body, -0.12);
  return (
    <g>
      {/* Хвостовые пёрышки */}
      <path d="M -15 -19 L -26 -25 L -17 -13 Z" fill={dark} />
      <path d="M -16 -13 L -25 -9.5 L -15 -7.5 Z" fill={dark} opacity="0.85" />
      {/* Тело + крылышки */}
      <ellipse cx={0} cy={-16} rx={17} ry={14} fill={body} />
      <ellipse cx={-14.5} cy={-17} rx={6} ry={9.5} fill={dark} transform="rotate(22 -14.5 -17)" />
      <ellipse cx={14.5} cy={-17} rx={6} ry={9.5} fill={dark} transform="rotate(-22 14.5 -17)" />
      {/* Лапки-ласты */}
      <g fill={BEAK}>
        <ellipse cx={-7.5} cy={-2} rx={6.2} ry={2.8} />
        <ellipse cx={7.5} cy={-2} rx={6.2} ry={2.8} />
      </g>
      {/* Голова + хохолок */}
      <circle cx={0} cy={-43} r={18.5} fill={body} />
      <g fill={body}>
        <circle cx={-4} cy={-60.5} r={2.7} />
        <circle cx={0} cy={-62.5} r={3} />
        <circle cx={4} cy={-60.5} r={2.7} />
      </g>
      {/* Клюв */}
      <ellipse cx={0} cy={-36.5} rx={10.5} ry={5.4} fill={BEAK} />
      <path d="M -7 -33.8 Q 0 -30.6 7 -33.8" stroke={shade(BEAK, -0.3)} strokeWidth="1.5" fill="none" strokeLinecap="round" />
      <Blush dx={14.5} y={-42} r={3.8} opacity={0.45} />
      <Eyes dx={8.2} y={-46.5} r={6} sleeping={sleeping} />
    </g>
  );
}

/** ЗАЙЧИК: длинные уши с розовой серединкой, зубки, помпон-хвост. */
function BunnyArt({ sleeping }: ArtProps) {
  const body = bodyColor("bunny");
  const cream = "#FDFBF5";
  const dark = shade(body, -0.16);
  return (
    <g>
      {/* Уши — длинные, чуть наклонены, с розовой серединкой */}
      <g transform="rotate(-9 -10 -70)">
        <rect x={-13.7} y={-88} width={7.6} height={32} rx={3.8} fill={body} />
        <rect x={-11.7} y={-84.5} width={3.9} height={25} rx={1.95} fill="#F5B8C4" />
      </g>
      <g transform="rotate(9 10 -70)">
        <rect x={6.1} y={-88} width={7.6} height={32} rx={3.8} fill={body} />
        <rect x={8.1} y={-84.5} width={3.9} height={25} rx={1.95} fill="#F5B8C4" />
      </g>
      {/* Хвост-помпон */}
      <circle cx={13} cy={-14} r={5} fill={cream} />
      {/* Тело */}
      <ellipse cx={0} cy={-15} rx={15} ry={12.5} fill={body} />
      <ellipse cx={0} cy={-11.5} rx={8} ry={8.5} fill={cream} />
      {/* Лапы */}
      <ellipse cx={-7} cy={-2.8} rx={5.2} ry={3.8} fill={dark} />
      <ellipse cx={7} cy={-2.8} rx={5.2} ry={3.8} fill={dark} />
      {/* Голова */}
      <ellipse cx={0} cy={-44} rx={20} ry={17.5} fill={body} />
      {/* Нос, зубки, улыбка */}
      <path d="M -2.7 -40.2 Q 0 -42.2 2.7 -40.2 Q 1.8 -38 0 -38 Q -1.8 -38 -2.7 -40.2 Z" fill="#E58FA2" />
      <rect x={-2.3} y={-37.8} width={4.6} height={4.4} rx={1.1} fill="#FFFFFF" stroke={shade(body, -0.3)} strokeWidth="0.9" />
      <path
        d="M -5.5 -38.9 Q -7.5 -37.5 -8.8 -39 M 5.5 -38.9 Q 7.5 -37.5 8.8 -39"
        stroke="#4A3B2A"
        strokeWidth="1.5"
        strokeLinecap="round"
        fill="none"
      />
      <Blush dx={14.5} y={-41.5} r={3.8} opacity={0.45} />
      <Eyes dx={8.5} y={-46} r={5.8} sleeping={sleeping} />
    </g>
  );
}

/** ПИНГВИНОНОК: яйцо-тело, белое лицо и живот, ласты, клюв, лапки. */
function PenguinArt({ sleeping }: ArtProps) {
  const body = bodyColor("penguin");
  const white = "#FDFBF5";
  const dark = shade(body, -0.14);
  return (
    <g>
      {/* Тело-яйцо */}
      <ellipse cx={0} cy={-25} rx={20} ry={26} fill={body} />
      {/* Белое лицо и живот */}
      <circle cx={0} cy={-39.5} r={11.5} fill={white} />
      <ellipse cx={0} cy={-19} rx={13.5} ry={16} fill={white} />
      {/* Ласты */}
      <ellipse cx={-21} cy={-26} rx={5.5} ry={12} fill={dark} transform="rotate(16 -21 -26)" />
      <ellipse cx={21} cy={-26} rx={5.5} ry={12} fill={dark} transform="rotate(-16 21 -26)" />
      {/* Лапки */}
      <g fill={BEAK}>
        <ellipse cx={-7.5} cy={-1.8} rx={6} ry={2.8} />
        <ellipse cx={7.5} cy={-1.8} rx={6} ry={2.8} />
      </g>
      {/* Клюв */}
      <path d="M -4.6 -38.5 L 4.6 -38.5 L 0 -31.5 Z" fill={BEAK} />
      <Blush dx={10.5} y={-36} r={3.2} opacity={0.4} />
      <Eyes dx={6.4} y={-42.5} r={4.7} sleeping={sleeping} />
    </g>
  );
}

/** ЁЖИК: колючий купол с остриями, вытянутая мордочка с носом, ушки. */
function HedgehogArt({ sleeping }: ArtProps) {
  const body = bodyColor("hedgehog");
  const dark = shade(body, -0.16);
  const snoutC = shade(body, 0.32);
  return (
    <g>
      {/* Колючая «причёска»: купол с зигзагом + острые кончики */}
      <path
        d="M -24 -44 Q -28 -75 0 -77 Q 28 -75 24 -44 L 17 -51 L 11 -42.5 L 4.5 -50 L 0 -42.5 L -4.5 -50 L -11 -42.5 L -17 -51 Z"
        fill={SPIKE}
      />
      <path d="M -17 -60 L -20 -73 L -9 -63 Z" fill={SPIKE} />
      <path d="M 17 -60 L 20 -73 L 9 -63 Z" fill={SPIKE} />
      <path d="M -5 -63 L 0 -76 L 5 -63 Z" fill={SPIKE} />
      {/* Тело */}
      <ellipse cx={0} cy={-13.5} rx={15} ry={12} fill={body} />
      {/* Лапы */}
      <ellipse cx={-7} cy={-2.8} rx={5.2} ry={3.8} fill={dark} />
      <ellipse cx={7} cy={-2.8} rx={5.2} ry={3.8} fill={dark} />
      {/* Голова + ушки */}
      <ellipse cx={0} cy={-42} rx={21} ry={18} fill={body} />
      <circle cx={-15} cy={-56.5} r={4.2} fill={body} stroke={shade(body, -0.25)} strokeWidth="1.4" />
      <circle cx={15} cy={-56.5} r={4.2} fill={body} stroke={shade(body, -0.25)} strokeWidth="1.4" />
      {/* Вытянутая мордочка с носом */}
      <path d="M -8.5 -38 Q 0 -42 8.5 -38 Q 6.5 -28.5 0 -27.5 Q -6.5 -28.5 -8.5 -38 Z" fill={snoutC} />
      <circle cx={0} cy={-28.5} r={3} fill={DARK} />
      <path
        d="M 0 -31.5 L 0 -33.8 M 0 -33.8 Q -2.6 -35.6 -4.6 -34.2 M 0 -33.8 Q 2.6 -35.6 4.6 -34.2"
        stroke="#4A3B2A"
        strokeWidth="1.5"
        strokeLinecap="round"
        fill="none"
      />
      <Blush dx={14.5} y={-40} r={3.4} opacity={0.4} />
      <Eyes dx={8.5} y={-44.5} r={5.4} sleeping={sleeping} />
    </g>
  );
}

/** ПАНДА: чёрные уши, пятна вокруг глаз, чёрные лапы-обнимашки. */
function PandaArt({ sleeping }: ArtProps) {
  const white = "#F2EEE4";
  return (
    <g>
      {/* Тело + чёрные лапы */}
      <ellipse cx={0} cy={-16} rx={17} ry={14} fill={white} />
      <ellipse cx={-15.5} cy={-19} rx={6} ry={9.5} fill={DARK} transform="rotate(18 -15.5 -19)" />
      <ellipse cx={15.5} cy={-19} rx={6} ry={9.5} fill={DARK} transform="rotate(-18 15.5 -19)" />
      <ellipse cx={-8} cy={-3} rx={6} ry={4.2} fill={DARK} />
      <ellipse cx={8} cy={-3} rx={6} ry={4.2} fill={DARK} />
      {/* Голова + уши */}
      <ellipse cx={0} cy={-44} rx={22} ry={19} fill={white} />
      <circle cx={-14.5} cy={-58.5} r={6.8} fill={DARK} />
      <circle cx={14.5} cy={-58.5} r={6.8} fill={DARK} />
      {/* Пятна вокруг глаз */}
      <ellipse cx={-9.2} cy={-46} rx={5.6} ry={7.2} fill={DARK} transform="rotate(-16 -9.2 -46)" />
      <ellipse cx={9.2} cy={-46} rx={5.6} ry={7.2} fill={DARK} transform="rotate(16 9.2 -46)" />
      {sleeping ? (
        <g stroke="#FFFFFF" strokeWidth="2.2" strokeLinecap="round" fill="none">
          <path d="M -11.5 -46 Q -9.2 -44 -6.9 -46" />
          <path d="M 6.9 -46 Q 9.2 -44 11.5 -46" />
        </g>
      ) : (
        <g className="ttg-blink" style={{ transformBox: "fill-box", transformOrigin: "center" }}>
          <circle cx={-9.2} cy={-46.5} r={3.7} fill="#FFFFFF" />
          <circle cx={9.2} cy={-46.5} r={3.7} fill="#FFFFFF" />
          <circle cx={-8.6} cy={-46.2} r={2} fill="#33261A" />
          <circle cx={8.6} cy={-46.2} r={2} fill="#33261A" />
          <circle cx={-8} cy={-47.2} r={0.7} fill="#FFFFFF" />
          <circle cx={8} cy={-47.2} r={0.7} fill="#FFFFFF" />
        </g>
      )}
      {/* Нос и улыбка */}
      <path d="M -3 -38.4 Q 0 -40.4 3 -38.4 Q 2 -36 0 -36 Q -2 -36 -3 -38.4 Z" fill={DARK} />
      <path
        d="M 0 -36 L 0 -34.2 M 0 -34.2 Q -2.6 -31.8 -4.8 -33.6 M 0 -34.2 Q 2.6 -31.8 4.8 -33.6"
        stroke="#4A3B2A"
        strokeWidth="1.7"
        strokeLinecap="round"
        fill="none"
      />
      <Blush dx={16} y={-39} r={3.4} opacity={0.35} />
    </g>
  );
}

/** МЕДВЕЖОНОК: круглые уши, морда со светлой серединкой, косолапые лапы. */
function BearArt({ sleeping }: ArtProps) {
  const body = bodyColor("bear");
  const muzzleC = shade(body, 0.35);
  const dark = shade(body, -0.12);
  return (
    <g>
      {/* Тело + животик */}
      <ellipse cx={0} cy={-16.5} rx={18} ry={14.5} fill={body} />
      <ellipse cx={0} cy={-12.5} rx={10} ry={9.5} fill={muzzleC} />
      {/* Лапы */}
      <ellipse cx={-9} cy={-3.2} rx={6.4} ry={4.4} fill={dark} />
      <ellipse cx={9} cy={-3.2} rx={6.4} ry={4.4} fill={dark} />
      {/* Голова + уши со светлой серединкой */}
      <ellipse cx={0} cy={-44} rx={22} ry={19} fill={body} />
      <circle cx={-14} cy={-58.5} r={7} fill={body} />
      <circle cx={14} cy={-58.5} r={7} fill={body} />
      <circle cx={-14} cy={-58.5} r={3.4} fill={muzzleC} />
      <circle cx={14} cy={-58.5} r={3.4} fill={muzzleC} />
      {/* Морда */}
      <ellipse cx={0} cy={-36.5} rx={10} ry={7.4} fill={muzzleC} />
      <ellipse cx={0} cy={-39.4} rx={3.3} ry={2.5} fill={DARK} />
      <path
        d="M 0 -37 L 0 -34.8 M 0 -34.8 Q -3 -32.2 -5.6 -34.4 M 0 -34.8 Q 3 -32.2 5.6 -34.4"
        stroke="#4A3B2A"
        strokeWidth="1.8"
        strokeLinecap="round"
        fill="none"
      />
      <Blush dx={16.5} y={-42} r={3.8} opacity={0.4} />
      <Eyes dx={9.2} y={-48} r={5.8} sleeping={sleeping} />
    </g>
  );
}

// ────────────────────────────────────────────────────────────────────
// Растения v1.3.0 — в горшочках, и никак не из яйца: семечко → росток
// → кустик → цветение. Горшок общий, у каждого вида своя «крона».
// ────────────────────────────────────────────────────────────────────

const POT = "#D97941";
const POT_DARK = "#B85F36";
const POT_LIGHT = "#EB9A66";
const SOIL = "#6B4A2E";
const LEAF = "#57B85C";
const TRUNK = "#8B5E34";

/** Терракотовый горшок с землёй — общий для всех растений. */
function Pot() {
  return (
    <g>
      {/* корпус */}
      <path d="M -14.5 -14 L 14.5 -14 L 11.5 0 Q 0 2.4 -11.5 0 Z" fill={POT} />
      {/* блик */}
      <path d="M -10 -11.5 L -7.5 -2" stroke={POT_LIGHT} strokeWidth="2.4" strokeLinecap="round" fill="none" />
      {/* ободок */}
      <rect x={-17} y={-22.5} width={34} height={9} rx={3} fill={POT_DARK} />
      {/* земля */}
      <ellipse cx={0} cy={-16.5} rx={12.6} ry={3.4} fill={SOIL} />
    </g>
  );
}

function Smile({
  y,
  w = 4.6,
  color = "#4A3B2A",
}: {
  y: number;
  w?: number;
  color?: string;
}) {
  return (
    <path
      d={`M ${-w} ${y} Q 0 ${y + w * 0.9} ${w} ${y}`}
      stroke={color}
      strokeWidth="1.7"
      strokeLinecap="round"
      fill="none"
    />
  );
}

/** Лист-сердечко (клевер): черешок в точке (0,0), лепестки вверх. */
function HeartLeaf({
  x,
  y,
  rot,
  s = 1,
}: {
  x: number;
  y: number;
  rot: number;
  s?: number;
}) {
  return (
    <g transform={`translate(${x} ${y}) rotate(${rot}) scale(${s})`}>
      <path
        d="M 0 0 C -6.5 -2.5 -9 -9.5 -3.5 -11.5 C -1.2 -12.3 0 -10.8 0 -9.5 C 0 -10.8 1.2 -12.3 3.5 -11.5 C 9 -9.5 6.5 -2.5 0 0 Z"
        fill={LEAF}
      />
      <path d="M 0 -1.5 L 0 -8.5" stroke={shade(LEAF, -0.18)} strokeWidth="1" strokeLinecap="round" />
    </g>
  );
}

/** Стадия 0 у растений — семечко в горшочке: земля трескается, петелька ростка выглядывает. */
function SeedArt({ progress }: { progress: number }) {
  return (
    <g className="ttg-egg" style={{ "--wobble": "1.2deg" } as CSSProperties}>
      <Pot />
      <ellipse cx={0} cy={-19.5} rx={7.5} ry={2.6} fill={shade(SOIL, -0.12)} />
      <g transform="rotate(-14 0 -23)">
        <ellipse cx={0} cy={-23} rx={4.4} ry={6} fill="#A9744F" />
        <ellipse cx={-1.2} cy={-25} rx={1.5} ry={2.6} fill="#C08A5E" opacity="0.85" />
      </g>
      {progress > 0.5 && (
        <polyline
          points="-6,-18.4 -2.5,-17.6 1.5,-18.6 5.5,-17.8"
          fill="none"
          stroke={shade(SOIL, -0.3)}
          strokeWidth="1.4"
          strokeLinecap="round"
        />
      )}
      {progress > 0.8 && (
        <path
          d="M 0 -26.5 Q 1 -31 4.6 -28.6"
          stroke={LEAF}
          strokeWidth="2.2"
          strokeLinecap="round"
          fill="none"
        />
      )}
    </g>
  );
}

/** КАКТУСЁНОК: ствол с рёбрами, ручки-отростки, иголочки, цветок на макушке. */
function CactusArt({ stage, sleeping }: { stage: number; sleeping: boolean }) {
  const body = bodyColor("cactus");
  const ridge = shade(body, -0.16);
  const rx = stage === 1 ? 8 : stage === 2 ? 9.5 : 11;
  const ry = stage === 1 ? 11 : stage === 2 ? 16 : 20.5;
  const cy = -13 - ry;
  const faceY = cy + 2;
  return (
    <g>
      {stage >= 3 && (
        <path
          d={`M ${rx - 2.5} ${cy + 5} Q 17 ${cy + 5} 17 ${cy - 2} L 17 ${cy - 7}`}
          stroke={body}
          strokeWidth="8"
          strokeLinecap="round"
          fill="none"
        />
      )}
      {stage >= 2 && (
        <path
          d={`M ${-(rx - 2.5)} ${cy + 8} Q -16.5 ${cy + 8} -16.5 ${cy} L -16.5 ${cy - 6}`}
          stroke={body}
          strokeWidth="7.5"
          strokeLinecap="round"
          fill="none"
        />
      )}
      <ellipse cx={0} cy={cy} rx={rx} ry={ry} fill={body} />
      <g stroke={ridge} strokeWidth="1.5" strokeLinecap="round" opacity="0.6" fill="none">
        <path d={`M ${-rx * 0.45} ${cy - ry + 4} L ${-rx * 0.45} -16`} />
        <path d={`M ${rx * 0.45} ${cy - ry + 4} L ${rx * 0.45} -16`} />
      </g>
      <g stroke="#FFFFFF" strokeWidth="1.3" strokeLinecap="round" opacity="0.75">
        <path d="M -6.5 -33 l 2.4 -2.4" />
        <path d="M 6.5 -29 l 2.4 -2.4" />
        <path d="M -6 -21.5 l 2.4 -2.4" />
        {stage >= 2 && <path d="M 6.5 -40 l 2.4 -2.4" />}
        {stage >= 3 && <path d="M -6.5 -45 l 2.4 -2.4" />}
      </g>
      {stage >= 3 && (
        <g>
          {[0, 72, 144, 216, 288].map((a) => (
            <circle
              key={a}
              cx={7.2 * Math.cos((a * Math.PI) / 180)}
              cy={cy - ry - 3 + 7.2 * Math.sin((a * Math.PI) / 180)}
              r={3.4}
              fill="#FFD24C"
            />
          ))}
          <circle cx={0} cy={cy - ry - 3} r={2.6} fill="#E8890C" />
        </g>
      )}
      <Blush dx={rx * 0.72} y={faceY + 4.5} r={2.8} opacity={0.4} />
      <Eyes dx={4.6} y={faceY} r={4.1} sleeping={sleeping} />
      <Smile y={faceY + 6.4} w={3.4} />
    </g>
  );
}

/** ПОДСОЛНУШЕК: стебель, листья с прожилками, бутон → жёлтая головка с лицом. */
function SunflowerArt({ stage, sleeping }: { stage: number; sleeping: boolean }) {
  const stemTop = stage === 1 ? -31 : stage === 2 ? -47 : -50;
  const petalY = -64;
  return (
    <g>
      <path d={`M 0 -17 Q 2 ${(stemTop - 17) / 2} 0 ${stemTop}`} stroke="#57B85C" strokeWidth={stage === 1 ? 3 : 4.2} strokeLinecap="round" fill="none" />
      {stage >= 2 && (
        <g>
          <ellipse cx={-9.5} cy={-30} rx={8.5} ry={4} fill={LEAF} transform="rotate(-18 -9.5 -30)" />
          <path d="M -14.5 -31.5 L -4.5 -28.5" stroke={shade(LEAF, -0.2)} strokeWidth="1.2" strokeLinecap="round" />
          <ellipse cx={9.5} cy={-36} rx={8.5} ry={4} fill={LEAF} transform="rotate(18 9.5 -36)" />
          <path d="M 14.5 -37.5 L 4.5 -34.5" stroke={shade(LEAF, -0.2)} strokeWidth="1.2" strokeLinecap="round" />
        </g>
      )}
      {stage === 1 && (
        <g>
          <ellipse cx={-6} cy={-30.5} rx={5.5} ry={3} fill={LEAF} transform="rotate(-22 -6 -30.5)" />
          <ellipse cx={6} cy={-30.5} rx={5.5} ry={3} fill={LEAF} transform="rotate(22 6 -30.5)" />
          <circle cx={0} cy={-34.5} r={4.4} fill="#8FCF7A" />
          <Eyes dx={2.3} y={-35.4} r={2} sleeping={sleeping} />
          <Smile y={-33.2} w={1.7} />
        </g>
      )}
      {stage === 2 && (
        <g>
          <path d="M -6.5 -46.5 L 0 -50.5 L 6.5 -46.5 Q 0 -43.5 -6.5 -46.5 Z" fill={shade(LEAF, -0.05)} />
          <ellipse cx={0} cy={-53.5} rx={7} ry={8.5} fill="#7FB069" />
          <path d="M -2.6 -46.8 Q -3.2 -52 -2 -58" stroke={shade("#7FB069", -0.2)} strokeWidth="1.3" fill="none" strokeLinecap="round" />
          <path d="M 2.6 -46.8 Q 3.2 -52 2 -58" stroke={shade("#7FB069", -0.2)} strokeWidth="1.3" fill="none" strokeLinecap="round" />
          <Blush dx={5.2} y={-50.5} r={2.1} opacity={0.4} />
          <Eyes dx={3.4} y={-54.2} r={2.9} sleeping={sleeping} />
          <Smile y={-50.4} w={2.5} />
        </g>
      )}
      {stage >= 3 && (
        <g>
          {Array.from({ length: 12 }, (_, i) => {
            const a = (i * 30 * Math.PI) / 180;
            const px = 15.8 * Math.cos(a);
            const py = petalY + 15.8 * Math.sin(a);
            return (
              <ellipse
                key={i}
                cx={px}
                cy={py}
                rx={6.6}
                ry={3.5}
                fill="#FFC800"
                transform={`rotate(${i * 30} ${px} ${py})`}
              />
            );
          })}
          <circle cx={0} cy={petalY} r={10.5} fill="#8A5A2B" />
          <circle cx={0} cy={petalY} r={10.5} fill="none" stroke={shade("#8A5A2B", -0.2)} strokeWidth="1.4" />
          <Blush dx={7.2} y={petalY + 4.4} r={2.7} opacity={0.4} />
          <Eyes dx={4.4} y={petalY - 1} r={3.9} sleeping={sleeping} />
          <Smile y={petalY + 4.4} w={3.2} />
        </g>
      )}
    </g>
  );
}

/** КЛЕВЕРЧИК: листья-сердечки, на цветении — четыре листа на удачу и белые цветки. */
function CloverArt({ stage, sleeping }: { stage: number; sleeping: boolean }) {
  return (
    <g>
      <g stroke={shade(LEAF, -0.1)} strokeWidth="1.6" strokeLinecap="round" fill="none">
        {stage === 1 && <path d="M 0 -17 Q -0.5 -21 -1 -25" />}
        {stage >= 2 && (
          <>
            <path d="M 0 -17 Q -5 -22 -9 -26" />
            <path d="M 0 -17 Q 5 -22 9 -26" />
            <path d="M 0 -17 Q -0.5 -26 0 -32" />
          </>
        )}
        {stage >= 3 && <path d="M 0 -17 Q 2 -26 5.5 -39" />}
      </g>
      {stage === 1 && (
        <g>
          <HeartLeaf x={-1} y={-24.5} rot={-8} s={1.15} />
          <Eyes dx={2.7} y={-30.5} r={2.2} sleeping={sleeping} />
          <Smile y={-28} w={1.9} />
        </g>
      )}
      {stage === 2 && (
        <g>
          <HeartLeaf x={-9.5} y={-25.5} rot={-32} s={1.05} />
          <HeartLeaf x={9.5} y={-25.5} rot={32} s={1.05} />
          <HeartLeaf x={0} y={-31.5} rot={0} s={1.15} />
          <Blush dx={5} y={-29.5} r={2} opacity={0.4} />
          <Eyes dx={3} y={-31.5} r={2.6} sleeping={sleeping} />
          <Smile y={-29} w={2.2} />
        </g>
      )}
      {stage >= 3 && (
        <g>
          <HeartLeaf x={-10.5} y={-26.5} rot={-36} s={1.3} />
          <HeartLeaf x={10.5} y={-26.5} rot={36} s={1.3} />
          <HeartLeaf x={-5.5} y={-38.5} rot={-10} s={1.25} />
          <HeartLeaf x={6} y={-38.5} rot={10} s={1.25} />
          {/* белые цветки удачи */}
          <g fill="#FFFFFF">
            <circle cx={-14} cy={-20} r={1.7} />
            <circle cx={-16.4} cy={-19} r={1.7} />
            <circle cx={-15.2} cy={-17.6} r={1.7} />
            <circle cx={14.5} cy={-21.5} r={1.7} />
            <circle cx={16.9} cy={-20.5} r={1.7} />
            <circle cx={15.7} cy={-19.1} r={1.7} />
          </g>
          <circle cx={-15.2} cy={-18.9} r={1.1} fill="#FFC800" />
          <circle cx={15.7} cy={-20.4} r={1.1} fill="#FFC800" />
          <Blush dx={5.6} y={-31} r={2.2} opacity={0.4} />
          <Eyes dx={3.4} y={-33} r={3} sleeping={sleeping} />
          <Smile y={-30.4} w={2.5} />
        </g>
      )}
    </g>
  );
}

/** БОНСАЙЧИК: изогнутый ствол, облака листвы, мох на земле. */
function BonsaiArt({ stage, sleeping }: { stage: number; sleeping: boolean }) {
  const foliage = bodyColor("bonsai");
  const cloudDark = shade(foliage, -0.12);
  return (
    <g>
      {stage === 1 && (
        <g>
          <path d="M 0 -17 L 0 -26" stroke={TRUNK} strokeWidth="4" strokeLinecap="round" fill="none" />
          <ellipse cx={0} cy={-31.5} rx={9} ry={7} fill={foliage} />
          <Blush dx={5.5} y={-29.5} r={1.9} opacity={0.4} />
          <Eyes dx={3.4} y={-32.2} r={2.7} sleeping={sleeping} />
          <Smile y={-29.6} w={2.3} />
        </g>
      )}
      {stage === 2 && (
        <g>
          <path d="M 0 -17 C 0 -22 -3.5 -25 -3 -30" stroke={TRUNK} strokeWidth="5" strokeLinecap="round" fill="none" />
          <path d="M -1 -26 Q 4 -27.5 6.5 -29.5" stroke={TRUNK} strokeWidth="3.4" strokeLinecap="round" fill="none" />
          <ellipse cx={-4.5} cy={-35.5} rx={8.5} ry={6.5} fill={foliage} />
          <ellipse cx={7} cy={-32} rx={6.5} ry={5} fill={cloudDark} />
          <Blush dx={0.8} y={-33.5} r={1.9} opacity={0.4} />
          <Eyes dx={-1.2} y={-36.2} r={2.7} sleeping={sleeping} />
          <Smile y={-33.6} w={2.3} />
        </g>
      )}
      {stage >= 3 && (
        <g>
          <path d="M 0 -17 C 1 -24 -4.5 -28 -2.5 -36" stroke={TRUNK} strokeWidth="6.5" strokeLinecap="round" fill="none" />
          <path d="M -2 -31 Q -8 -32.5 -10.5 -35" stroke={TRUNK} strokeWidth="3.5" strokeLinecap="round" fill="none" />
          <path d="M -2.5 -35 Q 4 -37.5 7 -39" stroke={TRUNK} strokeWidth="3.5" strokeLinecap="round" fill="none" />
          <ellipse cx={-11} cy={-38.5} rx={7.5} ry={5.5} fill={cloudDark} />
          <ellipse cx={10} cy={-41} rx={7} ry={5.2} fill={cloudDark} />
          <ellipse cx={0} cy={-46.5} rx={12} ry={9} fill={foliage} />
          {/* мох на земле */}
          <g fill={LEAF} opacity="0.85">
            <circle cx={-6} cy={-17.5} r={1.7} />
            <circle cx={7} cy={-18} r={1.5} />
            <circle cx={2} cy={-16.8} r={1.3} />
          </g>
          <Blush dx={7} y={-44} r={2.4} opacity={0.4} />
          <Eyes dx={4.2} y={-47} r={3.4} sleeping={sleeping} />
          <Smile y={-44.2} w={2.9} />
        </g>
      )}
    </g>
  );
}

/** ПАПОРОТИК: улитка-завиток → арки ваи́й с листочками, лицо у основания. */
function FernArt({ stage, sleeping }: { stage: number; sleeping: boolean }) {
  const frond = bodyColor("fern");
  const tick = shade(frond, -0.12);
  return (
    <g>
      {stage === 1 && (
        <g stroke={frond} strokeWidth="2.6" strokeLinecap="round" fill="none">
          <path d="M 0 -17 C 0 -24 -4.5 -27 -4.5 -23.5 C -4.5 -20.5 -1.2 -21 -0.8 -24" />
          <path d="M 1 -17 Q 3.5 -22 3 -26" strokeWidth="2" />
        </g>
      )}
      {stage === 2 && (
        <g stroke={frond} strokeWidth="2.8" strokeLinecap="round" fill="none">
          <path d="M 0 -17 C -5 -23 -10 -26 -15.5 -26.5" />
          <path d="M 0 -17 C 5 -23 10 -26 15.5 -26.5" />
          <path d="M 0 -17 C -0.5 -25 -1 -30 0.5 -34" strokeWidth="2.4" />
        </g>
      )}
      {stage >= 3 && (
        <g stroke={frond} strokeWidth="3" strokeLinecap="round" fill="none">
          <path d="M 0 -17 C -6 -24 -12 -28 -19 -28.5" />
          <path d="M 0 -17 C 6 -24 12 -28 19 -28.5" />
          <path d="M 0 -17 C -4 -27 -6 -34 -5.5 -40" strokeWidth="2.6" />
          <path d="M 0 -17 C 4 -27 6 -34 5.5 -40" strokeWidth="2.6" />
          <path d="M 0 -17 C 0 -26 0.5 -33 -0.5 -38" strokeWidth="2.4" />
        </g>
      )}
      {/* листочки на ваи́ях */}
      <g stroke={tick} strokeWidth="1.5" strokeLinecap="round">
        {stage === 2 && (
          <>
            <path d="M -6 -22.5 L -5.4 -26.6" />
            <path d="M -10.5 -25 L -9.4 -28.9" />
            <path d="M 6 -22.5 L 5.4 -26.6" />
            <path d="M 10.5 -25 L 9.4 -28.9" />
            <path d="M -1.5 -27 L -4 -29.4" />
            <path d="M 1.5 -27 L 4 -29.4" />
          </>
        )}
        {stage >= 3 && (
          <>
            <path d="M -7 -22.5 L -6.3 -27" />
            <path d="M -12 -26 L -10.7 -30.6" />
            <path d="M -16.5 -27.6 L -15.3 -32.2" />
            <path d="M 7 -22.5 L 6.3 -27" />
            <path d="M 12 -26 L 10.7 -30.6" />
            <path d="M 16.5 -27.6 L 15.3 -32.2" />
            <path d="M -5 -33 L -8 -35" />
            <path d="M 5 -33 L 8 -35" />
            <path d="M -5.5 -38 L -8.5 -39.8" />
            <path d="M 5.5 -38 L 8.5 -39.8" />
          </>
        )}
      </g>
      <Blush dx={4.6} y={-19.8} r={1.9} opacity={0.4} />
      <Eyes dx={3.1} y={-22} r={2.4} sleeping={sleeping} />
      <Smile y={-19.9} w={1.9} />
    </g>
  );
}

/** ТЮЛЬПАНЧИК: листья, бутон с чашелистиками → раскрытый цветок с лицом. */
function TulipArt({ stage, sleeping }: { stage: number; sleeping: boolean }) {
  const petal = bodyColor("tulip");
  const petalDark = shade(petal, -0.16);
  const stemTop = stage === 1 ? -24 : stage === 2 ? -40 : -46;
  return (
    <g>
      <path d={`M 0 -17 Q 1.5 ${(stemTop - 17) / 2} 0 ${stemTop}`} stroke="#57B85C" strokeWidth={stage === 1 ? 2.6 : 3.6} strokeLinecap="round" fill="none" />
      {/* длинные листья */}
      <path d="M 0 -18 Q -8 -24 -7.5 -40 Q -2.5 -30 0.5 -22 Z" fill={LEAF} />
      <path d="M 0 -18 Q 8 -24 7.5 -40 Q 2.5 -30 -0.5 -22 Z" fill={shade(LEAF, -0.08)} />
      {stage === 1 && (
        <g>
          <Eyes dx={2.5} y={-25.5} r={2} sleeping={sleeping} />
          <Smile y={-23.4} w={1.7} />
        </g>
      )}
      {stage === 2 && (
        <g>
          <path d="M -6 -38.5 L 0 -41.5 L 6 -38.5 Q 0 -35.5 -6 -38.5 Z" fill={shade(LEAF, -0.05)} />
          <ellipse cx={0} cy={-46} rx={6.5} ry={8} fill={petal} />
          <path d="M -2.6 -39.5 Q -3.4 -46 -2.2 -52.4" stroke={petalDark} strokeWidth="1.3" fill="none" strokeLinecap="round" />
          <path d="M 2.6 -39.5 Q 3.4 -46 2.2 -52.4" stroke={petalDark} strokeWidth="1.3" fill="none" strokeLinecap="round" />
          <Blush dx={4.8} y={-43.5} r={1.9} opacity={0.4} />
          <Eyes dx={3.2} y={-46.8} r={2.6} sleeping={sleeping} />
          <Smile y={-43.9} w={2.2} />
        </g>
      )}
      {stage >= 3 && (
        <g>
          {/* раскрытый тюльпан: чашечка + боковые лепестки */}
          <path
            d="M -9.5 -54 C -9.5 -62.5 -5 -66.5 0 -62.5 C 5 -66.5 9.5 -62.5 9.5 -54 C 9.5 -47.5 5 -44 0 -44 C -5 -44 -9.5 -47.5 -9.5 -54 Z"
            fill={petal}
          />
          <path d="M -3 -62.4 C -6 -58 -6.4 -50.5 -5.2 -45.2" stroke={petalDark} strokeWidth="1.7" fill="none" strokeLinecap="round" />
          <path d="M 3 -62.4 C 6 -58 6.4 -50.5 5.2 -45.2" stroke={petalDark} strokeWidth="1.7" fill="none" strokeLinecap="round" />
          <Blush dx={6.4} y={-50.5} r={2.4} opacity={0.4} />
          <Eyes dx={4.1} y={-53.8} r={3.1} sleeping={sleeping} />
          <Smile y={-50.8} w={2.6} />
        </g>
      )}
    </g>
  );
}

const PLANT_SCALE = 1.35; // растения меньше зверят — рисуем крупнее, чтобы горшок читался

function Creature({
  s,
  type,
  stage,
  sleeping,
}: {
  s: number;
  type: PetType;
  stage: number;
  sleeping: boolean;
}) {
  return (
    <g>
      {/* Мягкая тень на траве */}
      <ellipse cx={0} cy={0.5} rx={26 * s} ry={4.6 * s} fill="#3E6B22" opacity="0.16" />
      <g transform={`scale(${s * (isPlant(type) ? PLANT_SCALE : 1)})`}>
        {type === "fox" && <FoxArt sleeping={sleeping} />}
        {type === "cat" && <CatArt sleeping={sleeping} />}
        {type === "owl" && <OwlArt sleeping={sleeping} />}
        {type === "dragon" && <DragonArt sleeping={sleeping} />}
        {type === "duck" && <DuckArt sleeping={sleeping} />}
        {type === "bunny" && <BunnyArt sleeping={sleeping} />}
        {type === "penguin" && <PenguinArt sleeping={sleeping} />}
        {type === "hedgehog" && <HedgehogArt sleeping={sleeping} />}
        {type === "panda" && <PandaArt sleeping={sleeping} />}
        {type === "bear" && <BearArt sleeping={sleeping} />}
        {isPlant(type) && <PlantArt type={type} stage={stage} sleeping={sleeping} />}
      </g>
    </g>
  );
}

/** Роутер растений: горшок стоит на земле, «крона» плавно качается. */
function PlantArt({
  type,
  stage,
  sleeping,
}: {
  type: PetType;
  stage: number;
  sleeping: boolean;
}) {
  return (
    <g>
      <Pot />
      <g className={sleeping ? undefined : "ttg-sway"}>
        {type === "cactus" && <CactusArt stage={stage} sleeping={sleeping} />}
        {type === "sunflower" && <SunflowerArt stage={stage} sleeping={sleeping} />}
        {type === "clover" && <CloverArt stage={stage} sleeping={sleeping} />}
        {type === "bonsai" && <BonsaiArt stage={stage} sleeping={sleeping} />}
        {type === "fern" && <FernArt stage={stage} sleeping={sleeping} />}
        {type === "tulip" && <TulipArt stage={stage} sleeping={sleeping} />}
      </g>
    </g>
  );
}

function PetFigure({
  pet,
  index,
  total,
  sleeping,
}: {
  pet: Pet;
  index: number;
  total: number;
  sleeping: boolean;
}) {
  const t = total === 1 ? 0.5 : 0.18 + (0.64 * index) / (total - 1);
  const x = 400 * t;
  const stage = petStage(pet);
  const s = 0.55 + stage * 0.22;
  const isLast = index === total - 1;

  return (
    <g transform={`translate(${x} ${GROUND_Y})`}>
      {/* Анимация покачивания — отдельным слоем, чтобы не перебивать позицию */}
      <g
        className={sleeping ? "ttg-bob-sleep" : "ttg-bob"}
        style={{ animationDelay: `${-index * 0.7}s` }}
      >
        {stage === 0 ? (
          isPlant(pet.type) ? (
            <g transform="scale(1.3)">
              <SeedArt progress={stageProgress(pet)} />
            </g>
          ) : (
            <Egg spot={bodyColor(pet.type)} progress={stageProgress(pet)} />
          )
        ) : (
          <Creature s={s} type={pet.type} stage={stage} sleeping={sleeping} />
        )}
        {/* zzz над спящим активным питомцем */}
        {sleeping && isLast && (
          <g
            className="ttg-zzz"
            fill="#6B7B8C"
            fontWeight="800"
            fontFamily="inherit"
          >
            <text x={34 * s} y={-58 * s} fontSize={11 * s} opacity="0.9">z</text>
            <text x={43 * s} y={-68 * s} fontSize={14 * s} opacity="0.7">z</text>
            <text x={52 * s} y={-78 * s} fontSize={17 * s} opacity="0.5">Z</text>
          </g>
        )}
      </g>
    </g>
  );
}

export function PetScene({
  pets,
  sleeping,
}: {
  pets: Pet[];
  sleeping: boolean;
}) {
  return (
    <svg
      viewBox="0 0 400 240"
      preserveAspectRatio="xMidYMid slice"
      className="h-full w-full"
      role="img"
      aria-label="Сцена с питомцем"
    >
      <defs>
        <linearGradient id="ttg-sky" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor="#A6E4FF" />
          <stop offset="1" stopColor="#EAF9E0" />
        </linearGradient>
      </defs>

      <rect x="0" y="0" width="400" height="240" fill="url(#ttg-sky)" />

      {/* Солнце с гало */}
      <circle cx="64" cy="33.6" r="34" fill="#FFC800" opacity="0.25" />
      <circle cx="64" cy="33.6" r="22" fill="#FFC800" />

      <Cloud cx={220} cy={33.6} r={18} dur={34} delay={-8} />
      <Cloud cx={312} cy={57.6} r={14} dur={26} delay={-3} />

      {/* Лужайка */}
      <path
        d="M 0 205.6 Q 0 177.6 28 177.6 L 372 177.6 Q 400 177.6 400 205.6 L 400 240 L 0 240 Z"
        fill="#90D26D"
      />
      <circle cx="60" cy="199.2" r="22" fill="#7FC45C" />
      <circle cx="344" cy="194.4" r="18" fill="#7FC45C" />

      {/* Цветочки */}
      {[
        { x: 32, y: 211.2, c: "#FF8FB1" },
        { x: 120, y: 201.6, c: "#FFD166" },
        { x: 280, y: 216, c: "#EF476F" },
        { x: 372, y: 206.4, c: "#FFD166" },
      ].map((f, i) => (
        <g key={i}>
          <circle cx={f.x} cy={f.y} r="4" fill={f.c} />
          <circle cx={f.x} cy={f.y} r="1.6" fill="#FFFFFF" />
        </g>
      ))}

      {pets.map((p, i) => (
        <PetFigure
          key={p.id}
          pet={p}
          index={i}
          total={pets.length}
          sleeping={sleeping}
        />
      ))}
    </svg>
  );
}
