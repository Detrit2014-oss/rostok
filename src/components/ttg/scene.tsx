"use client";

// Порт lib/widgets/pet_canvas.dart (v2.0.0): небо, солнце, облака, лужайка,
// пруд для водных питомцев, погода (дождь/снег/туман/гроза) и 30 персонажей,
// нарисованных полностью процедурно (SVG) — ни одной картинки.
// v2.0.0 «Настоящие звери»: анатомия в профиль (силуэт с грудью/крупом,
// лапы с коленом, один глаз, видовы морды) и НАСТОЯЩИЕ ПОВАДКИ — зверь
// гуляет, останавливается принюхаться, пощипать траву, сесть или поклевать.
// Бабочки порхают, трава качается.

import { useEffect, useRef, useState } from "react";
import type { CSSProperties } from "react";

import {
  bellyColor,
  bodyColor,
  isAquatic,
  isPlant,
  Pet,
  petStage,
  skinnedBellyColor,
  skinnedBodyColor,
  skinnedShadeColor,
  speciesStyle,
  stageProgress,
} from "@/lib/ttg/types";
import type { PetType, SpeciesStyle } from "@/lib/ttg/types";

const GROUND_Y = 182.4; // 0.76 * 240
const BEAK = "#FF9500";
const DARK = "#3A3A3A";
const SPIKE = "#8B5E34";
const CRACK = "#C9A96E";
const POT = "#CB7B4E";
const POT_DARK = "#A85F38";
const SOIL = "#7A4E2D";
const STEM = "#5FA052";

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

/** Большое яйцо: растёт с прогрессом, покачивается, трескается. */
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

/** Растение в горшочке (6 видов). */
function Plant({ s, type, sleeping }: { s: number; type: PetType; sleeping: boolean }) {
  const body = bodyColor(type);
  const topY = -30 * s;
  return (
    <g>
      {/* Горшочек */}
      <path
        d={`M ${-15 * s} ${-26 * s} L ${15 * s} ${-26 * s} L ${11 * s} 0 L ${-11 * s} 0 Z`}
        fill={POT}
      />
      <rect x={-16 * s} y={-29 * s} width={32 * s} height={5 * s} fill={POT_DARK} />
      <rect x={-12.5 * s} y={-26 * s} width={25 * s} height={4 * s} fill={SOIL} />

      {type === "cactus" && (
        <g>
          <rect x={-7 * s} y={topY - 29 * s} width={14 * s} height={30 * s} rx={7 * s} fill={body} />
          <rect x={-19 * s} y={topY - 22 * s} width={8 * s} height={14 * s} rx={4 * s} fill={body} />
          <rect x={11 * s} y={topY - 26 * s} width={8 * s} height={16 * s} rx={4 * s} fill={body} />
          {Array.from({ length: 6 }, (_, i) => (
            <circle
              key={i}
              cx={(((i * 13) % 12) - 6) * s}
              cy={topY - 6 * s - i * 4.4 * s}
              r={1.1 * s}
              fill="#FFFFFF"
              opacity="0.85"
            />
          ))}
          {s >= 0.55 + 2 * 0.22 && (
            <g>
              <circle cx={0} cy={topY - 30 * s} r={4 * s} fill="#FF8FB1" />
              <circle cx={0} cy={topY - 30 * s} r={1.6 * s} fill="#FFFFFF" />
            </g>
          )}
        </g>
      )}

      {type === "bonsai" && (
        <g>
          <path
            d={`M 0 ${-26 * s} Q ${6 * s} ${topY + 12 * s} ${-3 * s} ${topY + 2 * s}`}
            stroke={SPIKE}
            strokeWidth={4.6 * s}
            strokeLinecap="round"
            fill="none"
          />
          <circle cx={-4 * s} cy={topY - 4 * s} r={9 * s} fill={body} />
          <circle cx={6 * s} cy={topY - 8 * s} r={7.4 * s} fill={body} opacity="0.9" />
          <circle cx={0} cy={topY - 13 * s} r={6 * s} fill={body} opacity="0.8" />
        </g>
      )}

      {type === "succulent" && (
        <g>
          {Array.from({ length: 6 }, (_, i) => {
            const a = -Math.PI + (i * Math.PI) / 5;
            return (
              <g key={i} transform={`translate(0 ${topY - 3 * s}) rotate(${((a + Math.PI / 2) * 180) / Math.PI})`}>
                <ellipse
                  cx={0}
                  cy={-6.2 * s}
                  rx={2.7 * s}
                  ry={5.5 * s}
                  fill={i % 2 === 0 ? body : `color-mix(in srgb, ${body} 82%, white)`}
                />
              </g>
            );
          })}
          <circle cx={0} cy={topY - 3 * s} r={4.2 * s} fill="#D8E8C8" />
        </g>
      )}

      {type === "sunflower" && (
        <g>
          <rect x={-1.8 * s} y={topY} width={3.6 * s} height={14 * s} fill={STEM} />
          <ellipse cx={-7 * s} cy={topY + 7 * s} rx={4.5 * s} ry={2.2 * s} fill={STEM} />
          <ellipse cx={7 * s} cy={topY + 10 * s} rx={4.5 * s} ry={2.2 * s} fill={STEM} />
          {Array.from({ length: 8 }, (_, i) => {
            const a = (i * Math.PI) / 4;
            return (
              <ellipse
                key={i}
                cx={Math.cos(a) * 9 * s}
                cy={topY - 6 * s + Math.sin(a) * 9 * s}
                rx={4 * s}
                ry={2.5 * s}
                fill={body}
                transform={`rotate(${(a * 180) / Math.PI} ${Math.cos(a) * 9 * s} ${topY - 6 * s + Math.sin(a) * 9 * s})`}
              />
            );
          })}
          <circle cx={0} cy={topY - 6 * s} r={6.4 * s} fill={SOIL} />
          {s >= 0.55 + 0.22 && (
            <g fill="#FFFFFF">
              <circle cx={-2.4 * s} cy={topY - 7 * s} r={1.3 * s} />
              <circle cx={2.4 * s} cy={topY - 7 * s} r={1.3 * s} />
            </g>
          )}
        </g>
      )}

      {type === "clover" && (
        <g>
          {[-7, 0, 7].map((sx) => (
            <g key={sx} transform={`translate(${sx * s} ${topY - 2 * s}) rotate(${sx * 2})`}>
              <circle cx={0} cy={-3.4 * s} r={4.6 * s} fill={body} />
              <circle cx={0} cy={3.4 * s} r={4.6 * s} fill={body} opacity="0.85" />
            </g>
          ))}
          {s >= 0.55 + 2 * 0.22 && (
            <circle cx={0} cy={topY - 14 * s} r={2.6 * s} fill="#FFD166" />
          )}
        </g>
      )}

      {type === "sprout" && (
        <g>
          <rect x={-1.6 * s} y={topY + 4 * s} width={3.2 * s} height={12 * s} fill={STEM} />
          <path
            d={`M 0 ${topY + 5 * s} Q ${-13 * s} ${topY + 2 * s} ${-11 * s} ${topY - 7 * s} Q ${-3 * s} ${topY - 4 * s} 0 ${topY + 5 * s} Z`}
            fill={body}
          />
          <path
            d={`M 0 ${topY + 5 * s} Q ${13 * s} ${topY + 2 * s} ${11 * s} ${topY - 7 * s} Q ${3 * s} ${topY - 4 * s} 0 ${topY + 5 * s} Z`}
            fill={body}
            opacity="0.88"
          />
        </g>
      )}

      {sleeping && (
        <g className="ttg-zzz" fill="#6B7B8C" fontWeight="800">
          <text x={18 * s} y={-44 * s} fontSize={11 * s} opacity="0.9">z</text>
          <text x={27 * s} y={-54 * s} fontSize={14 * s} opacity="0.7">z</text>
          <text x={36 * s} y={-64 * s} fontSize={17 * s} opacity="0.5">Z</text>
        </g>
      )}
    </g>
  );
}

// ── v2.0.0: настоящие звери ───────────────────────────────────────
// Звери ходят по лужайке с повадками: силуэт с грудью/крупом, лапы с
// коленом, один глаз, видовы морды; паузы — принюхивание/пастьба/сидя/клюёт.
// Гардероб (шапки/шарфы/очки/окрасы) рисуется прямо на питомце.

interface AnimalProps {
  s: number;
  type: PetType;
  sleeping: boolean;
  pet: Pet;
}

/** Ходьба по лужайке: треугольная волна + разворот в концах. */

// ── Повадки настоящих зверей (v2.0.0) — порт _petBehavior из Dart ──────
const STROLL_PERIOD = 21; // цикл «прогулка + пауза», с
const PAUSE_AT = 13.5; // начало паузы внутри цикла
const PAUSE_LEN = 3.8; // длительность паузы, с
const CROSS_SEC = 8.2; // полпути через лужайку, с

interface PetBehavior {
  x: number; // позиция на лужайке 0..1
  facing: number; // 1 вправо / -1 влево
  kind: "walk" | "sniff" | "graze" | "sit" | "peck" | "look";
  headPitch: number; // наклон головы вниз, рад
  stride: number; // фаза шага, рад (на паузе замирает)
  poseEase: number; // 0..1 плавный вход в позу
}

const GRAZERS: PetType[] = ["deer", "unicorn", "bunny", "squirrel", "pig", "koala", "panda", "dragon", "hedgehog"];
const PERCHERS: PetType[] = ["fox", "cat", "dog", "raccoon", "bear"];
const PECKERS: PetType[] = ["owl", "duck", "chick", "penguin"];

function strHash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = ((h << 5) - h + s.charCodeAt(i)) & 0x7fffffff;
  return h >>> 0;
}

function pbHash(a: number, b: number): number {
  let h = (a * 374761393 + b * 668265263) % 2147483647;
  if (h < 0) h += 2147483647;
  h = ((h ^ (h >> 13)) * 1274126177) % 2147483647;
  if (h < 0) h += 2147483647;
  return (((h ^ (h >> 16)) >>> 0) % 2147483647) / 2147483647;
}

function petBehavior(pet: Pet, tSec: number): PetBehavior {
  const seed = strHash(pet.id);
  const off = (seed % 1900) / 100; // у каждого зверя своё расписание
  const total = tSec + off;
  const local = total % STROLL_PERIOD;
  const cycle = Math.floor(total / STROLL_PERIOD);

  // «Чистое» время шага: паузы не двигают зверя и не качают лапы.
  const pauseDone = cycle * PAUSE_LEN + (local >= PAUSE_AT ? Math.min(local - PAUSE_AT, PAUSE_LEN) : 0);
  const walkT = tSec - pauseDone;
  const tri = ((walkT + off) / CROSS_SEC) % 2;
  const x = tri < 1 ? tri : 2 - tri;
  const facing = tri < 1 ? 1 : -1;
  const stride = ((walkT + off) * 2 * Math.PI) / 0.8;

  if (local < PAUSE_AT || local >= PAUSE_AT + PAUSE_LEN) {
    return { x, facing, kind: "walk", headPitch: 0.05 + Math.sin(stride * 2) * 0.03, stride, poseEase: 0 };
  }

  // Пауза: что делает зверь — стабильно на весь цикл.
  const r = pbHash(seed, cycle);
  let kind: PetBehavior["kind"];
  if (PECKERS.includes(pet.type)) kind = r < 0.62 ? "peck" : "look";
  else if (PERCHERS.includes(pet.type)) kind = r < 0.4 ? "sniff" : r < 0.78 ? "sit" : "look";
  else if (GRAZERS.includes(pet.type)) kind = r < 0.55 ? "graze" : r < 0.85 ? "sniff" : "look";
  else kind = r < 0.5 ? "sniff" : "look";

  const tin = Math.min(1, Math.max(0, (local - PAUSE_AT) / 0.7));
  const tout = Math.min(1, Math.max(0, (PAUSE_AT + PAUSE_LEN - local) / 0.7));
  const smooth = Math.min(tin, tout) ** 2 * (3 - 2 * Math.min(tin, tout));

  let target: number;
  if (kind === "graze") target = 1.0 + Math.sin(tSec * 8.5) * 0.06;
  else if (kind === "sniff") target = 0.62 + Math.sin(tSec * 7) * 0.07;
  else if (kind === "peck") {
    const pp = (((local - PAUSE_AT) / PAUSE_LEN) * 3) % 1;
    target = Math.abs(Math.sin(pp * Math.PI)) * 0.85;
  } else target = 0.1 + Math.sin(tSec * 1.6) * 0.12;

  return { x, facing, kind, headPitch: target * smooth, stride, poseEase: smooth };
}

/** rAF-движок повадок: ~24 к/с, SSR-безопасно (до монтирования — пауза). */
function useBehavior(pet: Pet, active: boolean): PetBehavior | null {
  const [bhv, setBhv] = useState<PetBehavior | null>(null);
  const petRef = useRef(pet);
  useEffect(() => {
    petRef.current = pet;
  }, [pet]);
  useEffect(() => {
    if (!active) return;
    let raf = 0;
    let last = 0;
    const t0 = performance.now();
    const tick = (now: number) => {
      raf = requestAnimationFrame(tick);
      if (now - last < 42) return;
      last = now;
      setBhv(petBehavior(petRef.current, (now - t0) / 1000));
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [active, pet.id]);
  return active ? bhv : null;
}

/** Лапа с коленом: бедро, голень и лапка с пальцами (углы из повадок). */
function LegV2({
  hx, hy, len, w, color, swing, rear,
}: {
  hx: number; hy: number; len: number; w: number;
  color: string; swing: number; rear?: boolean;
}) {
  const knee = Math.max(0, -Math.sin(swing)) * 0.5;
  return (
    <g transform={`translate(${hx} ${hy}) rotate(${(swing * 180) / Math.PI})`}>
      <ellipse cx={0} cy={len * 0.06} rx={w * (rear ? 1.05 : 0.85)} ry={len * 0.275} fill={color} />
      <rect x={-w / 2} y={0} width={w} height={len * 0.58} rx={w * 0.45} fill={color} />
      <g transform={`translate(0 ${len * 0.54}) rotate(${(knee * 180) / Math.PI})`}>
        <rect x={-w * 0.42} y={0} width={w * 0.84} height={len * 0.46} rx={w * 0.4} fill={color} />
        <ellipse cx={w * 0.1} cy={len * 0.44} rx={w * 0.775} ry={w * 0.475} fill={color} />
        {[-1, 0, 1].map((t) => (
          <circle key={t} cx={w * 0.1 + t * w * 0.42} cy={len * 0.44 + w * 0.12} r={w * 0.13} fill="#FFFFFF" opacity="0.28" />
        ))}
      </g>
    </g>
  );
}

/** Хвост четвероногого: пышный с белым кончиком, тонкий, колечком, помпон. */
function TailV2({
  ax, ay, bw, bh, kind, body, wag, wrap, s,
}: {
  ax: number; ay: number; bw: number; bh: number;
  kind: string; body: string; wag: boolean; wrap?: boolean; s: number;
}) {
  if (wrap) {
    // Сидит: хвост обёрнут вокруг крупа.
    const ring = {
      cx: ax + bw * 0.1, cy: ay + bh * 0.12,
      rx: bw * 0.22, ry: bh * 0.27,
    };
    return (
      <g>
        <ellipse cx={ring.cx} cy={ring.cy} rx={ring.rx} ry={ring.ry} stroke={body}
          strokeWidth={kind === "bushy" ? 10 * s : 5 * s} fill="none"
          strokeDasharray={`${ring.rx * 2.6} ${ring.rx * 6}`} transform={`rotate(24 ${ring.cx} ${ring.cy})`} strokeLinecap="round" />
        {kind === "bushy" && (
          <ellipse cx={ring.cx} cy={ring.cy} rx={ring.rx} ry={ring.ry} stroke="#FFFFFF" opacity="0.8"
            strokeWidth={10 * s} fill="none"
            strokeDasharray={`${ring.rx * 0.9} ${ring.rx * 6}`} transform={`rotate(24 ${ring.cx} ${ring.cy})`} strokeLinecap="round" />
        )}
      </g>
    );
  }
  let art: React.ReactNode = null;
  if (kind === "bushy") {
    art = (
      <g>
        <path
          d={`M 0 ${bh * 0.12} C ${-bw * 0.3} ${bh * 0.3} ${-bw * 0.55} ${bh * 0.22} ${-bw * 0.7} 0 C ${-bw * 0.8} ${-bh * 0.14} ${-bw * 0.72} ${-bh * 0.34} ${-bw * 0.56} ${-bh * 0.3} C ${-bw * 0.62} ${-bh * 0.18} ${-bw * 0.52} ${-bh * 0.02} ${-bw * 0.3} ${bh * 0.02} C ${-bw * 0.18} ${bh * 0.05} ${-bw * 0.08} ${bh * 0.1} 0 ${bh * 0.12} Z`}
          fill={body}
        />
        <path
          d={`M ${-bw * 0.7} 0 C ${-bw * 0.8} ${-bh * 0.14} ${-bw * 0.72} ${-bh * 0.34} ${-bw * 0.56} ${-bh * 0.3} C ${-bw * 0.6} ${-bh * 0.16} ${-bw * 0.58} ${-bh * 0.06} ${-bw * 0.52} ${bh * 0.02} C ${-bw * 0.58} ${bh * 0.04} ${-bw * 0.65} ${bh * 0.03} ${-bw * 0.7} 0 Z`}
          fill="#FFFFFF"
          opacity="0.85"
        />
      </g>
    );
  } else if (kind === "thin") {
    art = (
      <path
        d={`M 0 ${bh * 0.2} C ${-bw * 0.26} ${bh * 0.3} ${-bw * 0.36} ${bh * 0.02} ${-bw * 0.22} ${-bh * 0.34} Q ${-bw * 0.16} ${-bh * 0.46} ${-bw * 0.06} ${-bh * 0.4}`}
        stroke={body}
        strokeWidth={5 * s}
        strokeLinecap="round"
        fill="none"
      />
    );
  } else if (kind === "curl") {
    art = (
      <circle
        cx={-bw * 0.06}
        cy={0}
        r={6.5 * s}
        stroke={body}
        strokeWidth={5 * s}
        fill="none"
      />
    );
  } else if (kind === "puff") {
    art = <ellipse cx={-bw * 0.05} cy={0} rx={bw * 0.1} ry={bh * 0.15} fill="#FFFFFF" opacity="0.85" />;
  }
  if (!art) return null;
  return (
    <g transform={`translate(${ax} ${ay})`}>
      <g>
        {wag && (
          <animateTransform
            attributeName="transform" type="rotate"
            values="-8;8;-8" dur="0.62s" repeatCount="indefinite"
          />
        )}
        {art}
      </g>
    </g>
  );
}

/** Детали спины: иголки, крылья, пятна. */
function BackDetails({
  bodyCy, bw, bh, st, body, s, stage,
}: {
  bodyCy: number; bw: number; bh: number;
  st: SpeciesStyle; body: string; s: number; stage: number;
}) {
  const extra = st.extra ?? "none";
  if (extra === "spikes") {
    return (
      <g fill={SPIKE}>
        {[-2.6, -2.25, -1.9, -1.55, -1.2, -0.85].map((a) => {
          const tipX = bw * 0.5 * 1.3 * Math.cos(a);
          const tipY = bodyCy + bh * 0.5 * 1.5 * Math.sin(a);
          const b1X = bw * 0.5 * Math.cos(a + 0.14);
          const b1Y = bodyCy + bh * 0.5 * Math.sin(a + 0.14);
          const b2X = bw * 0.5 * Math.cos(a - 0.14);
          const b2Y = bodyCy + bh * 0.5 * Math.sin(a - 0.14);
          return <polygon key={a} points={`${b1X},${b1Y} ${tipX},${tipY} ${b2X},${b2Y}`} />;
        })}
      </g>
    );
  }
  if (extra === "wings" && stage >= 2) {
    return (
      <g fill={body} opacity="0.7">
        <path
          d={`M ${-bw * 0.05} ${bodyCy - bh * 0.3} Q ${-bw * 0.5} ${bodyCy - bh * 1.15} ${bw * 0.18} ${bodyCy - bh * 0.62} Z`}
        />
        <path
          d={`M ${bw * 0.16} ${bodyCy - bh * 0.3} Q ${bw * 0.55} ${bodyCy - bh * 1.0} ${bw * 0.3} ${bodyCy - bh * 0.55} Z`}
        />
      </g>
    );
  }
  if (extra === "spots") {
    return (
      <g fill="#FFFFFF" opacity="0.3">
        <circle cx={-bw * 0.22} cy={bodyCy - bh * 0.2} r={3.6 * s} />
        <circle cx={bw * 0.08} cy={bodyCy - bh * 0.28} r={2.8 * s} />
      </g>
    );
  }
  return null;
}

/** Грива единорога вдоль шеи. */
function Mane({
  bodyCy, headX, headY, s,
}: { bodyCy: number; headX: number; headY: number; s: number }) {
  const colors = ["#EF476F", "#FF9F45", "#FFD166", "#62C46A", "#1CB0F6"];
  return (
    <g>
      {colors.map((c, i) => {
        const t = i / (colors.length - 1);
        return (
          <circle
            key={c}
            cx={headX * t - 2 * s}
            cy={bodyCy + (headY - bodyCy) * t - 2 * s}
            r={5.5 * s}
            fill={c}
          />
        );
      })}
    </g>
  );
}

/** Уши на голове. */
function Ears({
  hx, hy, hr, st, body, belly, s,
}: {
  hx: number; hy: number; hr: number;
  st: SpeciesStyle; body: string; belly: string; s: number;
}) {
  const ear = st.ear ?? "none";
  if (ear === "triangle") {
    return (
      <g fill={body}>
        {[-0.55, 0.35].map((sx) => (
          <polygon
            key={sx}
            points={`${hx + hr * sx},${hy - hr * 0.55} ${hx + hr * (sx + 0.22)},${hy - hr * 1.45} ${hx + hr * (sx + 0.42)},${hy - hr * 0.5}`}
          />
        ))}
      </g>
    );
  }
  if (ear === "long") {
    return (
      <g>
        {[-0.5, 0.3].map((sx) => (
          <g key={sx}>
            <rect
              x={hx + hr * sx - hr * 0.22}
              y={hy - hr * 2.3}
              width={hr * 0.44}
              height={hr * 1.9}
              rx={hr * 0.22}
              fill={body}
            />
            <rect
              x={hx + hr * sx - hr * 0.1}
              y={hy - hr * 1.9}
              width={hr * 0.2}
              height={hr * 1.3}
              rx={hr * 0.1}
              fill="#F5B8C4"
            />
          </g>
        ))}
      </g>
    );
  }
  if (ear === "round") {
    return (
      <g>
        {[-0.55, 0.55].map((sx) => (
          <g key={sx}>
            <circle cx={hx + hr * sx} cy={hy - hr * 0.72} r={hr * 0.42} fill={body} />
            <circle cx={hx + hr * sx} cy={hy - hr * 0.72} r={hr * 0.2} fill={belly} />
          </g>
        ))}
      </g>
    );
  }
  if (ear === "pom") {
    return (
      <g fill={body}>
        {[-0.55, 0.55].map((sx) => (
          <circle key={sx} cx={hx + hr * sx} cy={hy - hr * 0.75} r={hr * 0.38} />
        ))}
      </g>
    );
  }
  if (ear === "tuft") {
    return (
      <g fill={body}>
        <circle cx={hx - hr * 0.2} cy={hy - hr * 0.95} r={hr * 0.17} />
        <circle cx={hx} cy={hy - hr * 0.95} r={hr * 0.22} />
        <circle cx={hx + hr * 0.2} cy={hy - hr * 0.95} r={hr * 0.17} />
      </g>
    );
  }
  if (ear === "horns") {
    return (
      <g fill="#F6E7C1">
        {[-0.4, 0.4].map((sx) => (
          <circle key={sx} cx={hx + hr * sx} cy={hy - hr * 0.8} r={hr * 0.18} />
        ))}
      </g>
    );
  }
  return null;
}

/** Детали головы: маска енота, пятна панды, рог единорога, рога оленя. */
function HeadDetails({
  hx, hy, hr, st, s,
}: { hx: number; hy: number; hr: number; st: SpeciesStyle; s: number }) {
  const extra = st.extra ?? "none";
  if (extra === "patches") {
    return (
      <g fill={DARK}>
        <ellipse cx={hx - hr * 0.36} cy={hy - hr * 0.05} rx={hr * 0.36} ry={hr * 0.41} />
        <ellipse cx={hx + hr * 0.36} cy={hy - hr * 0.05} rx={hr * 0.36} ry={hr * 0.41} />
      </g>
    );
  }
  if (extra === "mask") {
    return (
      <g fill="#5A5F66">
        <ellipse cx={hx - hr * 0.36} cy={hy - hr * 0.05} rx={hr * 0.4} ry={hr * 0.33} />
        <ellipse cx={hx + hr * 0.36} cy={hy - hr * 0.05} rx={hr * 0.4} ry={hr * 0.33} />
      </g>
    );
  }
  if (extra === "mane") {
    return (
      <polygon
        points={`${hx - 3.6 * s},${hy - hr * 0.85} ${hx + 3.6 * s},${hy - hr * 0.85} ${hx},${hy - hr * 1.75}`}
        fill="#FFD166"
      />
    );
  }
  if (extra === "antler") {
    return (
      <g stroke="#8B5E34" strokeWidth={3.4 * s} strokeLinecap="round" fill="none">
        {[-0.45, 0.45].map((sx) => (
          <path
            key={sx}
            d={`M ${hx + hr * sx} ${hy - hr * 0.7} L ${hx + hr * sx * 1.5} ${hy - hr * 1.7} M ${hx + hr * sx * 1.28} ${hy - hr * 1.25} L ${hx + hr * sx * 1.85} ${hy - hr * 1.45}`}
          />
        ))}
      </g>
    );
  }
  return null;
}

/** Морда в профиль: один глаз, нос, рот, усы (v2.0.0). */
function Face({
  hx, hy, hr, st, type, belly, s, sleeping, body,
}: {
  hx: number; hy: number; hr: number;
  st: SpeciesStyle; type: PetType; belly: string; s: number; sleeping: boolean; body: string;
}) {
  const muzzle = st.muzzle ?? "smile";
  const ex = hx + hr * 0.36;
  const ey = hy - hr * 0.08;
  const ink = "#3A3A3A";
  return (
    <g>
      {/* Один глаз — как у настоящего зверя в профиль */}
      {sleeping ? (
        <path
          d={`M ${ex - hr * 0.2} ${ey + hr * 0.06} Q ${ex} ${ey + hr * 0.18} ${ex + hr * 0.2} ${ey + hr * 0.06}`}
          stroke={ink} strokeWidth={2.4} strokeLinecap="round" fill="none"
        />
      ) : (
        <g className="ttg-blink">
          <circle cx={ex} cy={ey} r={hr * 0.27} fill="#FFFFFF" />
          <circle cx={ex + hr * 0.06} cy={ey + hr * 0.01} r={hr * 0.155} fill="#33261A" />
          <circle cx={ex + hr * 0.13} cy={ey - hr * 0.09} r={hr * 0.055} fill="#FFFFFF" />
        </g>
      )}
      {/* Румянец на щеке */}
      <circle cx={hx - hr * 0.3} cy={hy + hr * 0.36} r={hr * 0.16} fill="#FF8FA3" opacity="0.45" />

      {muzzle === "beak" && (
        <path
          d={`M ${hx + hr * 0.3} ${hy - hr * 0.02} L ${hx + hr * 0.3} ${hy + hr * 0.16} Q ${hx + hr * 0.55} ${hy + hr * 0.3} ${hx + hr * 1.02} ${hy + hr * 0.1} Z`}
          fill={BEAK}
        />
      )}
      {muzzle === "duckBeak" && (
        <g>
          <rect x={hx + hr * 0.12} y={hy - hr * 0.07} width={hr} height={hr * 0.42} rx={4 * s} fill={BEAK} />
          <line x1={hx + hr * 0.3} y1={hy + hr * 0.14} x2={hx + hr * 1.08} y2={hy + hr * 0.1} stroke={ink} strokeOpacity="0.6" strokeWidth={1.6} strokeLinecap="round" />
        </g>
      )}
      {muzzle === "bearMuzzle" && (
        <g>
          <ellipse cx={hx + hr * 0.4} cy={hy + hr * 0.28} rx={hr * 0.475} ry={hr * 0.33} fill={belly} />
          <circle cx={hx + hr * 0.62} cy={hy + hr * 0.06} r={hr * 0.125} fill={DARK} />
          <path d={`M ${hx + hr * 0.39} ${hy + hr * 0.36} A ${hr * 0.25} ${hr * 0.2} 0 0 0 ${hx + hr * 0.65} ${hy + hr * 0.36}`} stroke={ink} strokeWidth={2} strokeLinecap="round" fill="none" />
        </g>
      )}
      {muzzle === "buckteeth" && (
        <g>
          <path d={`M ${hx + hr * 0.11} ${hy + hr * 0.2} A ${hr * 0.31} ${hr * 0.23} 0 0 0 ${hx + hr * 0.73} ${hy + hr * 0.2}`} stroke={ink} strokeWidth={2} strokeLinecap="round" fill="none" />
          <rect x={hx + hr * 0.34} y={hy + hr * 0.26} width={hr * 0.17} height={hr * 0.26} rx={1.6} fill="#FFFFFF" />
          <rect x={hx + hr * 0.55} y={hy + hr * 0.24} width={hr * 0.17} height={hr * 0.26} rx={1.6} fill="#FFFFFF" />
        </g>
      )}
      {muzzle === "snout" && (
        <g>
          <ellipse cx={hx + hr * 0.66} cy={hy + hr * 0.14} rx={hr * 0.28} ry={hr * 0.25} fill="#E88AA0" />
          <circle cx={hx + hr * 0.58} cy={hy + hr * 0.14} r={hr * 0.065} fill={DARK} />
          <circle cx={hx + hr * 0.76} cy={hy + hr * 0.14} r={hr * 0.065} fill={DARK} />
        </g>
      )}
      {muzzle === "foxMuzzle" && (
        <g>
          {/* Острая мордочка: клин к носу + светлая щёчка */}
          <path
            d={`M ${hx + hr * 0.05} ${hy - hr * 0.3} Q ${hx + hr * 0.55} ${hy - hr * 0.18} ${hx + hr * 1.06} ${hy + hr * 0.1} Q ${hx + hr * 0.55} ${hy + hr * 0.42} ${hx + hr * 0.1} ${hy + hr * 0.34} Z`}
            fill={body}
          />
          <path
            d={`M ${hx + hr * 0.3} ${hy + hr * 0.08} Q ${hx + hr * 0.62} ${hy + hr * 0.12} ${hx + hr * 0.96} ${hy + hr * 0.14} Q ${hx + hr * 0.58} ${hy + hr * 0.34} ${hx + hr * 0.22} ${hy + hr * 0.3} Z`}
            fill="#FFFFFF" opacity="0.85"
          />
          <circle cx={hx + hr} cy={hy + hr * 0.06} r={hr * 0.085} fill={DARK} />
          <path d={`M ${hx + hr * 0.61} ${hy + hr * 0.16} A ${hr * 0.18} ${hr * 0.14} 0 0 0 ${hx + hr * 0.83} ${hy + hr * 0.2}`} stroke={ink} strokeWidth={2} strokeLinecap="round" fill="none" />
        </g>
      )}
      {muzzle === "catMuzzle" && (
        <g>
          <ellipse cx={hx + hr * 0.42} cy={hy + hr * 0.24} rx={hr * 0.36} ry={hr * 0.28} fill={belly} />
          <polygon points={`${hx + hr * 0.52},${hy + hr * 0.08} ${hx + hr * 0.66},${hy + hr * 0.08} ${hx + hr * 0.59},${hy + hr * 0.18}`} fill={DARK} />
          <path d={`M ${hx + hr * 0.32} ${hy + hr * 0.22} A ${hr * 0.15} ${hr * 0.12} 0 0 0 ${hx + hr * 0.62} ${hy + hr * 0.22}`} stroke={ink} strokeWidth={1.7} strokeLinecap="round" fill="none" />
          <path d={`M ${hx + hr * 0.56} ${hy + hr * 0.22} A ${hr * 0.15} ${hr * 0.12} 0 0 1 ${hx + hr * 0.86} ${hy + hr * 0.22}`} stroke={ink} strokeWidth={1.7} strokeLinecap="round" fill="none" />
          {[-0.04, 0.08, 0.2].map((dy) => (
            <line key={dy} x1={hx + hr * 0.55} y1={hy + hr * (0.12 + dy)} x2={hx + hr * 1.15} y2={hy + hr * dy * 1.5} stroke="#6E645A" strokeOpacity="0.75" strokeWidth={1.3} strokeLinecap="round" />
          ))}
        </g>
      )}
      {muzzle === "longMuzzle" && (
        <g>
          <rect x={hx + hr * 0.1} y={hy - hr * 0.16} width={hr * 1.14} height={hr * 0.52} rx={hr * 0.26} fill={body} />
          <circle cx={hx + hr * 1.16} cy={hy} r={hr * 0.1} fill={DARK} />
          <path d={`M ${hx + hr * 0.65} ${hy + hr * 0.14} A ${hr * 0.25} ${hr * 0.2} 0 0 0 ${hx + hr * 0.91} ${hy + hr * 0.2}`} stroke={ink} strokeWidth={2} strokeLinecap="round" fill="none" />
        </g>
      )}
      {muzzle === "smile" && (
        <g>
          <circle cx={hx + hr * 0.55} cy={hy + hr * 0.06} r={hr * 0.1} fill={DARK} />
          <path d={`M ${hx + hr * 0.17} ${hy + hr * 0.2} A ${hr * 0.28} ${hr * 0.2} 0 0 0 ${hx + hr * 0.73} ${hy + hr * 0.2}`} stroke={ink} strokeWidth={2} strokeLinecap="round" fill="none" />
        </g>
      )}
      {/* Усики тюленя */}
      {type === "seal" && (
        <g stroke="#7A8896" strokeWidth={1.6} strokeLinecap="round">
          <line x1={hx + hr * 0.4} y1={hy - hr * 0.04} x2={hx + hr * 1.05} y2={hy - hr * 0.1} />
          <line x1={hx + hr * 0.4} y1={hy + hr * 0.1} x2={hx + hr * 1.05} y2={hy + hr * 0.04} />
        </g>
      )}
    </g>
  );
}

/** Шапки (гардероб). */
function Hat({
  hx, hy, hr, pet, s,
}: { hx: number; hy: number; hr: number; pet: Pet; s: number }) {
  const hat = pet.hat ?? "none";
  if (hat === "cap") {
    return (
      <g>
        <path
          d={`M ${hx - hr * 1.05} ${hy - hr * 0.25} A ${hr * 1.05} ${hr * 1.05} 0 0 1 ${hx + hr * 1.05} ${hy - hr * 0.25} Z`}
          fill="#EF476F"
        />
        <rect x={hx + hr * 0.5} y={hy - hr * 0.42} width={hr * 0.9} height={hr * 0.24} rx={hr * 0.12} fill="#D63A5C" />
      </g>
    );
  }
  if (hat === "beanie") {
    return (
      <g>
        <path
          d={`M ${hx - hr * 1.1} ${hy - hr * 0.3} A ${hr * 1.1} ${hr * 1.15} 0 0 1 ${hx + hr * 1.1} ${hy - hr * 0.3} Z`}
          fill="#1CB0F6"
        />
        <rect x={hx - hr * 1.1} y={hy - hr * 0.5} width={hr * 2.2} height={hr * 0.34} rx={hr * 0.16} fill="#1899D6" />
        <circle cx={hx} cy={hy - hr * 1.5} r={hr * 0.24} fill="#FFFFFF" />
      </g>
    );
  }
  if (hat === "crown") {
    const baseY = hy - hr * 0.82;
    return (
      <g>
        <polygon
          points={`${hx - hr * 0.7},${baseY} ${hx - hr * 0.7},${baseY - hr * 0.5} ${hx - hr * 0.35},${baseY - hr * 0.2} ${hx},${baseY - hr * 0.62} ${hx + hr * 0.35},${baseY - hr * 0.2} ${hx + hr * 0.7},${baseY - hr * 0.5} ${hx + hr * 0.7},${baseY}`}
          fill="#FFC800"
        />
        <circle cx={hx} cy={baseY - hr * 0.16} r={hr * 0.1} fill="#EF476F" />
      </g>
    );
  }
  return null;
}

/** Шея: шарф/бантик (гардероб). */
function Neckwear({
  nx, ny, hr, pet,
}: { nx: number; ny: number; hr: number; pet: Pet }) {
  const neck = pet.neck ?? "none";
  if (neck === "scarf") {
    return (
      <g>
        <rect x={nx - hr} y={ny - hr * 0.25} width={hr * 2} height={hr * 0.5} rx={hr * 0.2} fill="#EF476F" />
        <rect x={nx - hr * 0.75} y={ny} width={hr * 0.5} height={hr * 0.95} rx={hr * 0.16} fill="#EF476F" />
        <line x1={nx - hr * 0.68} y1={ny + hr * 0.3} x2={nx - hr * 0.35} y2={ny + hr * 0.38} stroke="#FFFFFF" strokeWidth={2.2} strokeLinecap="round" />
        <line x1={nx - hr * 0.68} y1={ny + hr * 0.6} x2={nx - hr * 0.35} y2={ny + hr * 0.68} stroke="#FFFFFF" strokeWidth={2.2} strokeLinecap="round" />
      </g>
    );
  }
  if (neck === "bow") {
    return (
      <g fill="#FF6B6B">
        <polygon points={`${nx},${ny} ${nx - hr * 0.65},${ny - hr * 0.34} ${nx - hr * 0.65},${ny + hr * 0.34}`} />
        <polygon points={`${nx},${ny} ${nx + hr * 0.65},${ny - hr * 0.34} ${nx + hr * 0.65},${ny + hr * 0.34}`} />
        <circle cx={nx} cy={ny} r={hr * 0.16} fill="#E14C4C" />
      </g>
    );
  }
  return null;
}

/** Очки/тёмные очки (гардероб). */
function Glasses({
  hx, hy, hr, pet, hidden,
}: { hx: number; hy: number; hr: number; pet: Pet; hidden: boolean }) {
  if (hidden) return null;
  const face = pet.face ?? "none";
  const eyeDX = hr * 0.38;
  const eyeY = hy - hr * 0.06;
  if (face === "glasses") {
    return (
      <g stroke="#3A3A3A" strokeWidth={2.4} fill="none">
        <circle cx={hx - eyeDX} cy={eyeY} r={hr * 0.44} />
        <circle cx={hx + eyeDX} cy={eyeY} r={hr * 0.44} />
        <line x1={hx - eyeDX + hr * 0.44} y1={eyeY} x2={hx + eyeDX - hr * 0.44} y2={eyeY} />
      </g>
    );
  }
  if (face === "shades") {
    return (
      <g>
        <rect x={hx - eyeDX - hr * 0.42} y={eyeY - hr * 0.3} width={hr * 0.85} height={hr * 0.6} rx={hr * 0.14} fill="#2E3A55" />
        <rect x={hx + eyeDX - hr * 0.42} y={eyeY - hr * 0.3} width={hr * 0.85} height={hr * 0.6} rx={hr * 0.14} fill="#2E3A55" />
        <line x1={hx - eyeDX + hr * 0.42} y1={eyeY - hr * 0.1} x2={hx + eyeDX - hr * 0.42} y2={eyeY - hr * 0.1} stroke="#2E3A55" strokeWidth={2.6} />
      </g>
    );
  }
  return null;
}

/** Зверь/птица/прыгун/водный житель — диспетчер по телосложению. */
function Animal(props: AnimalProps & { bhv: PetBehavior | null }) {
  const st = speciesStyle(props.type);
  const body = skinnedBodyColor(props.type, props.pet.skin);
  const belly = skinnedBellyColor(props.type, props.pet.skin);
  const shade = skinnedShadeColor(props.type, props.pet.skin);
  const full = { ...props, st, body, belly, shade };
  switch (st.build ?? "quad") {
    case "bird":
      return <Bird {...full} />;
    case "hop":
      return <Hopper {...full} />;
    case "pond":
      return <PondCreature {...full} />;
    default:
      return <Quadruped {...full} />;
  }
}

/** Силуэт настоящего четвероногого: грудь, холка, круп, поджарый живот. */
function quadBodyPath(bw: number, bh: number): string {
  const bx = (f: number) => (f * bw).toFixed(2);
  const by = (f: number) => (f * bh).toFixed(2);
  return [
    `M ${bx(0.46)} ${by(0)}`,
    `C ${bx(0.5)} ${by(-0.22)} ${bx(0.42)} ${by(-0.4)} ${bx(0.18)} ${by(-0.48)}`,
    `C ${bx(0.06)} ${by(-0.52)} ${bx(-0.04)} ${by(-0.44)} ${bx(-0.14)} ${by(-0.47)}`,
    `C ${bx(-0.26)} ${by(-0.52)} ${bx(-0.4)} ${by(-0.5)} ${bx(-0.47)} ${by(-0.3)}`,
    `C ${bx(-0.52)} ${by(-0.12)} ${bx(-0.5)} ${by(0.12)} ${bx(-0.42)} ${by(0.28)}`,
    `C ${bx(-0.32)} ${by(0.44)} ${bx(-0.08)} ${by(0.47)} ${bx(0.12)} ${by(0.42)}`,
    `C ${bx(0.3)} ${by(0.38)} ${bx(0.42)} ${by(0.22)} ${bx(0.46)} ${by(0)}`,
    "Z",
  ].join(" ");
}

interface HeadGroupProps {
  pivotX: number; pivotY: number;
  neckAngle: number; reach: number; headTilt: number;
  hr: number; bh: number;
  st: SpeciesStyle; pet: Pet;
  body: string; belly: string; s: number; sleeping: boolean;
}

/** Шея и голова: угол шеи, вытянутость и наклон морды независимы —
 *  поэтому зверь умеет и бежать, и принюхиваться, и щипать траву. */
function HeadGroupV2({
  pivotX, pivotY, neckAngle, reach, headTilt, hr, bh, st, pet, body, belly, s, sleeping,
}: HeadGroupProps) {
  const dx = Math.sin(neckAngle);
  const dy = -Math.cos(neckAngle);
  const hx = pivotX + dx * reach;
  const hy = pivotY + dy * reach;
  const rot = ((neckAngle * 0.5 + headTilt) * 180) / Math.PI;
  const midX = pivotX + dx * reach * 0.52 + bh * 0.12;
  const midY = pivotY + dy * reach * 0.52;
  return (
    <g>
      {reach > hr * 0.2 && (
        <path
          d={`M ${pivotX - bh * 0.1} ${pivotY + bh * 0.04} Q ${midX} ${midY} ${hx - hr * 0.15} ${hy + hr * 0.05}`}
          stroke={body} strokeWidth={bh * 0.3} strokeLinecap="round" fill="none"
        />
      )}
      <g transform={`translate(${hx} ${hy}) rotate(${rot})`}>
        <circle r={hr} fill={body} />
        <Ears hx={0} hy={0} hr={hr} st={st} body={body} belly={belly} s={s} />
        <HeadDetails hx={0} hy={0} hr={hr} st={st} s={s} />
        <Face hx={0} hy={0} hr={hr} st={st} type={pet.type} belly={belly} s={s} sleeping={sleeping} body={body} />
        <Hat hx={0} hy={0} hr={hr} pet={pet} s={s} />
        <Glasses hx={0} hy={0} hr={hr} pet={pet} hidden={sleeping} />
      </g>
      {(pet.neck === "scarf" || pet.neck === "bow") && (
        <Neckwear nx={pivotX + dx * reach * 0.22} ny={pivotY + dy * reach * 0.22 + bh * 0.1} hr={hr} pet={pet} />
      )}
    </g>
  );
}

/** Четвероногий ходок: настоящее тело, шея, голова, повадки (v2.0.0). */
function Quadruped({ s, type, st, body, belly, shade, sleeping, pet, bhv }: AnimalProps & { st: SpeciesStyle; body: string; belly: string; shade: string; bhv: PetBehavior | null }) {
  const bw = 78 * s * (st.bodyLen ?? 1);
  const bh = 46 * s;
  const legH = 26 * s * (st.legLen ?? 1);
  const hr = 15.5 * s * (st.headScale ?? 1);
  const kind = sleeping ? "sleep" : (bhv?.kind ?? "walk");
  const ease = sleeping ? 0 : (bhv?.poseEase ?? 0);
  const legW = 9.5 * s;

  const headGroup = (p: { pivotX: number; pivotY: number; neckAngle: number; reach: number; headTilt: number; eyesClosed: boolean }) => (
    <HeadGroupV2
      pivotX={p.pivotX} pivotY={p.pivotY}
      neckAngle={p.neckAngle} reach={p.reach} headTilt={p.headTilt}
      hr={hr} bh={bh} st={st} pet={pet} body={body} belly={belly} s={s} sleeping={p.eyesClosed}
    />
  );

  if (kind === "sleep") {
    // Лёжа: распластанное тело, морда на земле, глаза закрыты.
    const bodyCy = -bh * 0.34;
    return (
      <g>
        <TailV2 ax={-bw * 0.46} ay={bodyCy} bw={bw} bh={bh} kind={st.tail ?? "none"} body={body} wag={false} s={s} />
        <path d={quadBodyPath(bw, bh * 0.76)} transform={`translate(0 ${bodyCy})`} fill={body} />
        <ellipse cx={-bw * 0.02} cy={bodyCy + bh * 0.12} rx={bw * 0.275} ry={bh * 0.15} fill={belly} />
        <BackDetails bodyCy={bodyCy} bw={bw} bh={bh} st={st} body={body} s={s} stage={3} />
        {headGroup({ pivotX: bw * 0.32, pivotY: bodyCy - bh * 0.14, neckAngle: 0.62, reach: bh * 0.54, headTilt: 0.58, eyesClosed: true })}
      </g>
    );
  }

  if (kind === "sit") {
    // Сидит: круп на земле, грудь вверх, передние лапы прямые.
    const haunchX = -bw * 0.14;
    const haunchY = -bh * 0.4;
    const tilt = -0.66;
    const ct = Math.cos(tilt), stl = Math.sin(tilt);
    const chestX = haunchX + bw * 0.42 * ct - -bh * 0.04 * stl;
    const chestY = haunchY + bw * 0.42 * stl + -bh * 0.04 * ct;
    return (
      <g>
        <TailV2 ax={-bw * 0.36} ay={-bh * 0.16} bw={bw} bh={bh} kind={st.tail ?? "none"} body={body} wag={false} wrap s={s} />
        <ellipse cx={haunchX} cy={haunchY} rx={bw * 0.27} ry={bh * 0.46} fill={body} />
        <ellipse cx={haunchX + bw * 0.12} cy={haunchY + bh * 0.2} rx={bw * 0.15} ry={bh * 0.17} fill={belly} />
        <ellipse cx={-bw * 0.04} cy={-4 * s} rx={bw * 0.13} ry={4.25 * s} fill={shade} />
        <g transform={`translate(${haunchX} ${haunchY}) rotate(${(tilt * 180) / Math.PI})`}>
          <ellipse cx={bw * 0.2} cy={-bh * 0.02} rx={bw * 0.29} ry={bh * 0.39} fill={body} />
          <ellipse cx={bw * 0.16} cy={bh * 0.14} rx={bw * 0.17} ry={bh * 0.14} fill={belly} />
        </g>
        <BackDetails bodyCy={haunchY - bh * 0.34} bw={bw * 0.6} bh={bh * 0.8} st={st} body={body} s={s} stage={Math.round((s - 0.55) / 0.22)} />
        {/* Плечевой круг — прячет верх лап в груди */}
        <circle cx={chestX} cy={chestY + bh * 0.04} r={bh * 0.16} fill={body} />
        {[-5.5 * s, 5.5 * s].map((dx, i) => (
          <g key={dx}>
            <rect x={chestX + dx - 4.8 * s} y={chestY + bh * 0.02} width={9.6 * s} height={Math.max(4, -(chestY + bh * 0.02) - 1)} rx={4.8 * s} fill={i === 0 ? shade : body} />
            <ellipse cx={chestX + dx + 3.2 * s} cy={-2.6 * s} rx={6.5 * s} ry={3.25 * s} fill={i === 0 ? shade : body} />
          </g>
        ))}
        {headGroup({ pivotX: chestX + bw * 0.03, pivotY: chestY - bh * 0.24, neckAngle: 0.42, reach: bh * 0.55, headTilt: 0.06, eyesClosed: false })}
      </g>
    );
  }

  // Походка / принюхивание / пастьба.
  const stride = bhv?.stride ?? 0;
  const bob = Math.sin(stride * 2) * 1.7 * s * (bhv ? 1 - bhv.poseEase * 0.8 : 1);
  const bodyCy = -legH - bh * 0.5 + bob;
  const amp = 0.4;
  const walkNeck = 0.1 + Math.sin(stride * 2) * 0.03;
  let neckAngle = walkNeck;
  let reachM = 1;
  let headTilt = 0.03 + Math.sin(stride * 2 + 1) * 0.02;
  if (ease > 0) {
    let tAng = 0.9, tReach = 0.95, tTilt = 0.35;
    if (kind === "graze") {
      tAng = 1.95;
      tReach = 1.06;
      tTilt = 0.6 + Math.sin(Date.now() / 1000 * 9) * 0.05;
    } else if (kind === "sniff") {
      tAng = 0.92 + Math.sin(Date.now() / 1000 * 7) * 0.05;
      tReach = 0.96;
      tTilt = 0.36;
    } else if (kind === "look") {
      tAng = -0.1 + Math.sin(Date.now() / 1000 * 1.5) * 0.07;
      tReach = 1;
      tTilt = -0.04;
    }
    neckAngle = walkNeck + (tAng - walkNeck) * ease;
    reachM = 1 + (tReach - 1) * ease;
    headTilt = headTilt + (tTilt - headTilt) * ease;
  }
  const neckLen = bh * (0.22 + (st.neck ?? 0.3) * 0.55);
  const pivotX = bw * 0.3;
  const pivotY = bodyCy - bh * 0.06;

  return (
    <g>
      {/* Лапы: диагональная походка (дальняя пара темнее) */}
      <LegV2 hx={bw * 0.3} hy={bodyCy + bh * 0.42} len={legH} w={legW} color={shade} swing={Math.sin(stride + Math.PI) * amp} />
      <LegV2 hx={-bw * 0.28} hy={bodyCy + bh * 0.4} len={legH} w={legW * 1.21} color={shade} swing={Math.sin(stride + Math.PI) * amp} rear />
      <LegV2 hx={bw * 0.3} hy={bodyCy + bh * 0.42} len={legH} w={legW} color={body} swing={Math.sin(stride) * amp} />
      <LegV2 hx={-bw * 0.28} hy={bodyCy + bh * 0.4} len={legH} w={legW * 1.21} color={body} swing={Math.sin(stride) * amp} rear />
      {/* Хвост виляет на ходу */}
      <TailV2 ax={-bw * 0.44} ay={bodyCy - bh * 0.06} bw={bw} bh={bh} kind={st.tail ?? "none"} body={body} wag s={s} />
      {/* Тело настоящего зверя */}
      <path d={quadBodyPath(bw, bh)} transform={`translate(0 ${bodyCy})`} fill={body} />
      {/* Бедро — объём задней половины */}
      <ellipse cx={-bw * 0.27} cy={bodyCy + bh * 0.02} rx={bw * 0.2} ry={bh * 0.4} fill={shade} opacity={0.55} />
      {/* Животик */}
      <ellipse cx={bw * 0.04} cy={bodyCy + bh * 0.3} rx={bw * 0.31} ry={bh * 0.17} fill={belly} />
      <BackDetails bodyCy={bodyCy} bw={bw} bh={bh} st={st} body={body} s={s} stage={Math.round((s - 0.55) / 0.22)} />
      {/* Грива единорога вдоль шеи */}
      {st.extra === "mane" && (
        <Mane bodyCy={pivotY} headX={pivotX + Math.sin(neckAngle) * neckLen * reachM} headY={pivotY - Math.cos(neckAngle) * neckLen * reachM} s={s} />
      )}
      {headGroup({
        pivotX, pivotY,
        neckAngle, reach: neckLen * reachM, headTilt,
        eyesClosed: false,
      })}
    </g>
  );
}

/** Птица: две лапки с коленчиком, грушевидное тело, клюв (v2.0.0). */
function Bird({ s, type, st, body, belly, shade, sleeping, pet, bhv }: AnimalProps & { st: SpeciesStyle; body: string; belly: string; shade: string; bhv: PetBehavior | null }) {
  const bw = 40 * s;
  const bh = 56 * s * (st.bodyLen ?? 1);
  const legH = 16 * s;
  const hr = 14.5 * s * (st.headScale ?? 1);
  const kind = sleeping ? "sleep" : (bhv?.kind ?? "walk");
  const stride = bhv?.stride ?? 0;
  const sit = kind === "sleep" ? legH * 0.35 : legH;
  const bodyCy = -sit - bh * 0.44;

  const walkTilt = kind === "walk" ? Math.sin(stride) * 3 : 0;

  // Голова с наклоном: на паузе птица клюёт зёрнышки.
  const pitch = bhv?.headPitch ?? 0;
  const pivotX = bw * 0.1;
  const pivotY = bodyCy - bh * 0.44;
  const neckLen = bh * 0.26;
  const headX = pivotX + Math.sin(pitch * 1.35) * neckLen;
  const headY = pivotY - Math.cos(pitch * 1.35) * neckLen;
  const headRot = (pitch * 0.9 * 180) / Math.PI;

  return (
    <g>
      <g transform={walkTilt ? `rotate(${walkTilt} 0 0)` : undefined}>
        {/* Лапки с коленчиком */}
        {[-1, 1].map((d) => {
          const swing = kind === "sleep" ? 0 : Math.sin(stride + (d > 0 ? 0 : Math.PI)) * 0.32;
          return (
            <g key={d} transform={`translate(${d * bw * 0.14} ${-sit}) rotate(${(swing * 180) / Math.PI})`}>
              <line x1={0} y1={0} x2={0} y2={sit * 0.62} stroke={kind === "sleep" ? shade : "#E8A13D"} strokeWidth={4.2 * s} strokeLinecap="round" />
              <line x1={0} y1={sit * 0.62} x2={2 * s} y2={sit} stroke={kind === "sleep" ? shade : "#E8A13D"} strokeWidth={4.2 * s} strokeLinecap="round" />
              <line x1={2 * s} y1={sit} x2={6.5 * s} y2={sit + 0.5} stroke={kind === "sleep" ? shade : "#E8A13D"} strokeWidth={4.2 * s} strokeLinecap="round" />
              <line x1={2 * s} y1={sit} x2={-1.5 * s} y2={sit + 0.5} stroke={kind === "sleep" ? shade : "#E8A13D"} strokeWidth={4.2 * s} strokeLinecap="round" />
            </g>
          );
        })}
        {/* Хвост-веер из перьев */}
        <polygon
          points={`${-bw * 0.26},${bodyCy + bh * 0.22} ${-bw * 0.86},${bodyCy + bh * 0.3} ${-bw * 0.8},${bodyCy + bh * 0.42} ${-bw * 0.7},${bodyCy + bh * 0.36} ${-bw * 0.66},${bodyCy + bh * 0.5} ${-bw * 0.28},${bodyCy + bh * 0.44}`}
          fill={shade}
        />
        {/* Тело-груша */}
        <path
          d={`M ${bw * 0.4} ${bodyCy - bh * 0.1} C ${bw * 0.44} ${bodyCy - bh * 0.4} ${bw * 0.1} ${bodyCy - bh * 0.52} ${-bw * 0.1} ${bodyCy - bh * 0.44} C ${-bw * 0.4} ${bodyCy - bh * 0.3} ${-bw * 0.44} ${bodyCy + bh * 0.16} ${-bw * 0.26} ${bodyCy + bh * 0.36} C ${-bw * 0.1} ${bodyCy + bh * 0.52} ${bw * 0.2} ${bodyCy + bh * 0.48} ${bw * 0.34} ${bodyCy + bh * 0.24} Z`}
          fill={body}
        />
        <ellipse cx={bw * 0.1} cy={bodyCy + bh * 0.14} rx={bw * 0.27} ry={bh * 0.22} fill={belly} />
        {/* Крылышко с пёрышками */}
        <ellipse cx={-bw * 0.14} cy={bodyCy - bh * 0.02} rx={bw * 0.23} ry={bh * 0.21} fill={shade} />
        <line x1={-bw * 0.1} y1={bodyCy + bh * 0.02} x2={-bw * 0.3} y2={bodyCy + bh * 0.16} stroke={shade} strokeWidth={1.6} strokeLinecap="round" />
        <line x1={-bw * 0.08} y1={bodyCy + bh * 0.12} x2={-bw * 0.26} y2={bodyCy + bh * 0.26} stroke={shade} strokeWidth={1.6} strokeLinecap="round" />
      </g>
      {/* Голова */}
      <g transform={`translate(${headX} ${headY}) rotate(${headRot})`}>
        <circle r={hr} fill={body} />
        <Ears hx={0} hy={0} hr={hr} st={st} body={body} belly={belly} s={s} />
        <HeadDetails hx={0} hy={0} hr={hr} st={st} s={s} />
        <Face hx={0} hy={0} hr={hr} st={st} type={type} belly={belly} s={s} sleeping={kind === "sleep"} body={body} />
        <Hat hx={0} hy={0} hr={hr} pet={pet} s={s} />
        <Glasses hx={0} hy={0} hr={hr} pet={pet} hidden={kind === "sleep"} />
      </g>
      {(pet.neck === "scarf" || pet.neck === "bow") && (
        <Neckwear nx={bw * 0.06} ny={bodyCy - bh * 0.4} hr={hr} pet={pet} />
      )}
    </g>
  );
}

/** Прыгуны: настоящий зайчик и лягушонок (v2.0.0). */
function Hopper({ s, type, st, body, belly, shade, sleeping, pet, bhv }: AnimalProps & { st: SpeciesStyle; body: string; belly: string; shade: string; bhv: PetBehavior | null }) {
  const bw = 58 * s * (st.bodyLen ?? 1);
  const bh = 46 * s;
  const bodyCy = -bh * 0.48 - 4 * s;
  const isFrog = (st.muzzle ?? "smile") === "topEyes";

  if (isFrog) {
    // Лягушонок: глаза-фонарики на макушке.
    return (
      <g>
        {!sleeping && (
          <animateTransform
            attributeName="transform" type="translate"
            values="0 0;0 -24;0 0;0 0"
            keyTimes="0;0.2;0.4;1"
            calcMode="spline"
            keySplines="0.3 0 0.4 1;0.6 0 0.8 0.6;0 0 1 1"
            dur="2.4s"
            repeatCount="indefinite"
          />
        )}
        <ellipse cx={-bw * 0.24} cy={-6 * s} rx={bw * 0.17} ry={bh * 0.12} fill={shade} />
        <ellipse cx={-bw * 0.3} cy={-bh * 0.2} rx={bw * 0.21} ry={bh * 0.15} fill={shade} />
        <ellipse cx={bw * 0.34} cy={-3 * s} rx={bw * 0.08} ry={bh * 0.07} fill={body} />
        <ellipse cx={0} cy={bodyCy} rx={bw / 2} ry={bh / 2} fill={body} />
        <ellipse cx={bw * 0.06} cy={bodyCy + bh * 0.18} rx={bw * 0.26} ry={bh * 0.22} fill={belly} />
        {[-0.22, 0.22].map((sx) => (
          <g key={sx}>
            <circle cx={bw * sx} cy={bodyCy - bh * 0.5} r={bh * 0.42 * 0.42} fill={body} />
            {sleeping ? (
              <line
                x1={bw * sx - bh * 0.08} y1={bodyCy - bh * 0.51}
                x2={bw * sx + bh * 0.08} y2={bodyCy - bh * 0.51}
                stroke="#33261A" strokeWidth={2} strokeLinecap="round"
              />
            ) : (
              <g className="ttg-blink">
                <circle cx={bw * sx} cy={bodyCy - bh * 0.5 - 2 * s} r={bh * 0.42 * 0.3} fill="#FFFFFF" />
                <circle cx={bw * sx} cy={bodyCy - bh * 0.5 - 1 * s} r={bh * 0.42 * 0.14} fill="#33261A" />
              </g>
            )}
          </g>
        ))}
        <path
          d={`M ${-bw * 0.24} ${bodyCy + bh * 0.08} A ${bw * 0.26} ${bh * 0.18} 0 0 0 ${bw * 0.28} ${bodyCy + bh * 0.08}`}
          stroke="#4A3B2A" strokeWidth={2.4} strokeLinecap="round" fill="none"
        />
        <Hat hx={0} hy={bodyCy - bh * 0.86} hr={bh * 0.42} pet={pet} s={s} />
        <Glasses hx={0} hy={bodyCy} hr={bh * 0.42} pet={pet} hidden={sleeping} />
      </g>
    );
  }

  // Настоящий зайчик: на паузе опускает голову к траве.
  const ease = sleeping ? 0 : (bhv?.poseEase ?? 0);
  const kind = bhv?.kind ?? "walk";
  const drop = kind === "graze" || kind === "sniff" ? ease * bh * 0.22 : 0;
  const hr = bh * 0.34;
  const headX = bw * 0.4;
  const headY = bodyCy - bh * 0.4 + drop;

  return (
    <g>
      {!sleeping && (
        <animateTransform
          attributeName="transform" type="translate"
          values="0 0;0 -26;0 0;0 0"
          keyTimes="0;0.19;0.38;1"
          calcMode="spline"
          keySplines="0.3 0 0.4 1;0.6 0 0.8 0.6;0 0 1 1"
          dur="2.35s"
          repeatCount="indefinite"
        />
      )}
      {/* Пушистый хвостик */}
      <circle cx={-bw * 0.4} cy={bodyCy + bh * 0.1} r={7 * s} fill="#FFFFFF" opacity="0.9" />
      {/* Заднее бедро и ступня */}
      <ellipse cx={-bw * 0.14} cy={bodyCy + bh * 0.16} rx={bw * 0.18} ry={bh * 0.22} fill={shade} />
      <ellipse cx={bw * 0.02} cy={-6 * s} rx={bw * 0.17} ry={4.25 * s} fill={shade} />
      {/* Передние лапки */}
      <ellipse cx={bw * 0.3} cy={-5 * s} rx={bw * 0.075} ry={3.75 * s} fill={body} />
      {/* Тело-капля: круп выше, грудь вперёд */}
      <path
        d={`M ${bw * 0.42} ${bodyCy - bh * 0.02} C ${bw * 0.46} ${bodyCy - bh * 0.34} ${bw * 0.16} ${bodyCy - bh * 0.55} ${-bw * 0.08} ${bodyCy - bh * 0.5} C ${-bw * 0.36} ${bodyCy - bh * 0.44} ${-bw * 0.48} ${bodyCy - bh * 0.1} ${-bw * 0.44} ${bodyCy + bh * 0.14} C ${-bw * 0.38} ${bodyCy + bh * 0.4} ${bw * 0.1} ${bodyCy + bh * 0.46} ${bw * 0.28} ${bodyCy + bh * 0.24} Z`}
        fill={body}
      />
      <ellipse cx={bw * 0.02} cy={bodyCy + bh * 0.2} rx={bw * 0.25} ry={bh * 0.15} fill={belly} />
      {/* Голова */}
      <circle cx={headX} cy={headY} r={hr} fill={body} />
      <Ears hx={headX} hy={headY} hr={hr} st={st} body={body} belly={belly} s={s} />
      <HeadDetails hx={headX} hy={headY} hr={hr} st={st} s={s} />
      <Face hx={headX} hy={headY} hr={hr} st={st} type={type} belly={belly} s={s} sleeping={sleeping} body={body} />
      <Hat hx={headX} hy={headY} hr={hr} pet={pet} s={s} />
      <Glasses hx={headX} hy={headY} hr={hr} pet={pet} hidden={sleeping} />
      {(pet.neck === "scarf" || pet.neck === "bow") && (
        <Neckwear nx={headX - bh * 0.26} ny={headY + bh * 0.34} hr={hr} pet={pet} />
      )}
    </g>
  );
}

/** Водные жители пруда (кит, тюлень, черепашка, осьминожка, крабик). */
function PondCreature({ s, type, st, body, belly, sleeping, pet }: AnimalProps & { st: SpeciesStyle; body: string; belly: string }) {
  const bw = 64 * s;
  const bh = 44 * s;
  const bodyCy = -bh / 2;
  const extra = st.extra ?? "none";
  const eyesClosed = sleeping;

  return (
    <g>
      {/* Хвост-плавник кита */}
      {type === "whale" && (
        <polygon
          points={`${-bw * 0.46},${bodyCy} ${-bw * 0.75},${bodyCy - bh * 0.3} ${-bw * 0.6},${bodyCy} ${-bw * 0.75},${bodyCy + bh * 0.3}`}
          fill={body}
        />
      )}
      <ellipse cx={0} cy={bodyCy} rx={bw / 2} ry={bh / 2} fill={body} />
      <ellipse cx={0} cy={bodyCy + bh * 0.18} rx={bw * 0.31} ry={bh * 0.25} fill={belly} />
      {/* Панцирь черепашки */}
      {extra === "shell" && (
        <g>
          <ellipse cx={0} cy={bodyCy - bh * 0.08} rx={bw * 0.47} ry={bh * 0.39} fill="#6B9B4E" />
          <ellipse cx={0} cy={bodyCy - bh * 0.08} rx={bw * 0.275} ry={bh * 0.22} fill="#8FBF6A" />
        </g>
      )}
      {/* Ножки осьминожки */}
      {extra === "tentacles" &&
        [-2, -1, 0, 1, 2].map((i) => (
          <circle key={i} cx={bw * 0.17 * i} cy={bodyCy + bh * 0.52} r={5.2 * s} fill={body} />
        ))}
      {/* Клешни крабика */}
      {extra === "claws" &&
        [-0.62, 0.62].map((sx) => (
          <g key={sx}>
            <circle cx={sx * bw} cy={bodyCy - bh * 0.1} r={8.5 * s} fill={body} />
            <path
              d={`M ${sx * bw - 8.5 * s} ${bodyCy - bh * 0.1} A ${8.5 * s} ${8.5 * s} 0 0 1 ${sx * bw + 8.5 * s} ${bodyCy - bh * 0.1} Z`}
              fill={belly}
              opacity={sx > 0 ? 1 : 0}
            />
          </g>
        ))}
      {/* Фонтанчик кита */}
      {type === "whale" && (
        <g stroke="#9FD4EF" strokeWidth={2.4} strokeLinecap="round">
          <line x1={0} y1={bodyCy - bh * 0.62} x2={0} y2={bodyCy - bh * 0.62 - 9} />
          <line x1={0} y1={bodyCy - bh * 0.62} x2={-5} y2={bodyCy - bh * 0.62 - 8} />
          <line x1={0} y1={bodyCy - bh * 0.62} x2={5} y2={bodyCy - bh * 0.62 - 8} />
        </g>
      )}
      {/* Глаза и улыбка */}
      {eyesClosed ? (
        <g stroke="#4A3B2A" strokeWidth={2.4} strokeLinecap="round">
          <line x1={-bw * 0.17} y1={bodyCy - bh * 0.05} x2={-bw * 0.17 + 7 * s} y2={bodyCy - bh * 0.05} />
          <line x1={bw * 0.17 - 7 * s} y1={bodyCy - bh * 0.05} x2={bw * 0.17} y2={bodyCy - bh * 0.05} />
        </g>
      ) : (
        <g className="ttg-blink">
          {[-1, 1].map((d) => (
            <g key={d}>
              <circle cx={d * bw * 0.17} cy={bodyCy - bh * 0.05} r={6.5 * s} fill="#FFFFFF" />
              <circle cx={d * bw * 0.17 + 1.5} cy={bodyCy - bh * 0.05 + 1} r={3.2 * s} fill="#33261A" />
            </g>
          ))}
        </g>
      )}
      {type === "whale" ? (
        <path
          d={`M ${-bw * 0.25} ${bodyCy + bh * 0.05} A ${bw * 0.25} ${bh * 0.25} 0 0 0 ${bw * 0.25} ${bodyCy + bh * 0.05}`}
          stroke="#3E6E8E" strokeWidth={3} strokeLinecap="round" fill="none"
        />
      ) : (
        <path
          d={`M ${-7 * s} ${bodyCy + bh * 0.08} A ${7 * s} ${5 * s} 0 0 0 ${7 * s} ${bodyCy + bh * 0.08}`}
          stroke="#4A3B2A" strokeWidth={2.2} strokeLinecap="round" fill="none"
        />
      )}
      <Hat hx={0} hy={bodyCy - bh * 0.62} hr={bw * 0.3} pet={pet} s={s} />
      <Glasses hx={0} hy={bodyCy - bh * 0.05} hr={bw * 0.42} pet={pet} hidden={eyesClosed} />
    </g>
  );
}

/** Грядка с семечком (растения, стадия 0) — растения растут, а не вылупляются. */
function SeedBed({ s, progress }: { s: number; progress: number }) {
  return (
    <g>
      {/* Холмик земли */}
      <ellipse cx={0} cy={-6 * s} rx={26 * s} ry={9 * s} fill={SOIL} />
      <ellipse cx={0} cy={-9 * s} rx={22 * s} ry={6 * s} fill="#96683F" />
      {/* Семечко */}
      <g transform={`translate(2 ${-12 * s}) rotate(-35)`} className="ttg-egg" style={{ ["--wobble" as string]: "1deg" }}>
        <ellipse cx={0} cy={0} rx={4.5 * s} ry={6.5 * s} fill="#C89B62" />
        <ellipse cx={-1.6 * s} cy={-2.4 * s} rx={1.7 * s} ry={2.5 * s} fill="#E5C793" />
      </g>
      {/* Трещинка */}
      {progress > 0.4 && (
        <path
          d={`M ${-14 * s} ${-4 * s} L ${-8 * s} ${-8 * s} L ${-11 * s} ${-13 * s}`}
          stroke="#5E3D22" strokeWidth={2} strokeLinecap="round" fill="none"
        />
      )}
      {/* Проклюнувшийся росточек */}
      {progress > 0.62 && (
        <g>
          {(() => {
            const h = 8 * s + 8 * s * ((progress - 0.62) / 0.38);
            return (
              <g>
                <rect x={-1.3 * s} y={-12 * s - h} width={2.6 * s} height={h} fill={STEM} />
                <ellipse cx={-5 * s} cy={-12 * s - h + 1} rx={4 * s} ry={1.8 * s} fill="#7FC45C" />
                <ellipse cx={5 * s} cy={-12 * s - h + 3} rx={4 * s} ry={1.8 * s} fill="#7FC45C" opacity="0.85" />
              </g>
            );
          })()}
        </g>
      )}
      {/* Блеск */}
      {progress > 0.85 && (
        <g>
          <circle cx={-16 * s} cy={-26 * s} r={2.2 * s} fill="#FFD166" />
          <circle cx={-16 * s} cy={-26 * s} r={0.9 * s} fill="#FFFFFF" />
        </g>
      )}
    </g>
  );
}

function PetFigure({
  pet,
  index,
  total,
  sleeping,
  pondActive,
}: {
  pet: Pet;
  index: number;
  total: number;
  sleeping: boolean;
  pondActive: boolean;
}) {
  const stage = petStage(pet);
  const s = 0.55 + stage * 0.22;
  const isLast = index === total - 1;
  const aquatic = isAquatic(pet.type);
  const plant = isPlant(pet.type);
  const walkable = stage > 0 && !plant && !aquatic;

  // v2.0.0: движок повадок — гуляет, принюхивается, щиплет траву, сидит.
  const bhv = useBehavior(pet, walkable && !sleeping);

  // Водные питомцы живут в пруду по центру; остальные — на лужайке.
  const x = pondActive && aquatic ? 200 : walkable && !sleeping ? 400 * (0.16 + 0.68 * (bhv?.x ?? 0.5)) : 400 * (total === 1 ? 0.5 : 0.18 + (0.64 * index) / Math.max(1, total - 1));
  const y = aquatic ? GROUND_Y + 24 : GROUND_Y;

  // Искусство питомца (общее для сна и ходьбы).
  const art =
    stage === 0 ? (
      plant ? (
        <SeedBed s={s} progress={stageProgress(pet)} />
      ) : (
        <Egg spot={bodyColor(pet.type)} progress={stageProgress(pet)} />
      )
    ) : plant ? (
      <Plant s={s} type={pet.type} sleeping={sleeping} />
    ) : (
      <Animal s={s} type={pet.type} sleeping={sleeping} pet={pet} bhv={bhv} />
    );

  return (
    <g transform={`translate(${x} ${y})`}>
      {aquatic ? (
        <g className="ttg-bob-sleep" style={{ animationDelay: `${-index * 0.7}s` }}>
          {art}
        </g>
      ) : walkable && !sleeping ? (
        /* v2.0.0: зверь идёт в свою сторону (разворот по повадкам). */
        <g transform={`scale(${bhv?.facing ?? 1} 1)`}>
          <ellipse cx={0} cy={3} rx={38 * s} ry={5.5 * s} fill="#000000" opacity="0.08" />
          {art}
        </g>
      ) : (
        <g className="ttg-bob-sleep" style={{ animationDelay: `${-index * 0.7}s` }}>
          {stage > 0 && !plant && (
            <ellipse cx={0} cy={3} rx={38 * s} ry={5.5 * s} fill="#000000" opacity="0.08" />
          )}
          {art}
        </g>
      )}
      {sleeping && isLast && !plant && (
        <g className="ttg-zzz" fill="#6B7B8C" fontWeight="800" fontFamily="inherit">
          <text x={26 * s} y={-62 * s} fontSize={11 * s} opacity="0.9">z</text>
          <text x={35 * s} y={-72 * s} fontSize={14 * s} opacity="0.7">z</text>
          <text x={44 * s} y={-82 * s} fontSize={17 * s} opacity="0.5">Z</text>
        </g>
      )}
    </g>
  );
}

/** Погодные слои (v1.7.0): туман, дождь, снег, гроза. */
function WeatherLayers({ weather }: { weather?: string | null }) {
  if (!weather) return null;
  if (weather === "fog") {
    return (
      <g>
        {[0, 1, 2].map((i) => (
          <rect
            key={i}
            x={-20}
            y={108 + i * 38}
            width={440}
            height={18}
            rx={9}
            fill="#FFFFFF"
            opacity={0.38 - i * 0.07}
            className="ttg-fog-drift"
            style={{ animationDuration: `${9 + i * 3}s`, animationDelay: `${-i * 2}s` }}
          />
        ))}
      </g>
    );
  }
  if (weather === "rain") {
    return (
      <g className="ttg-rain" stroke="#9FD4EF" strokeWidth="2.2" strokeLinecap="round" opacity="0.75">
        {Array.from({ length: 34 }, (_, i) => {
          const fx = ((i * 97) % 100) / 100;
          return <line key={i} x1={fx * 400} y1={-30 + ((i * 53) % 240)} x2={fx * 400 - 5} y2={-14 + ((i * 53) % 240)} />;
        })}
      </g>
    );
  }
  if (weather === "snow") {
    return (
      <g className="ttg-snow" fill="#FFFFFF" opacity="0.9">
        {Array.from({ length: 26 }, (_, i) => (
          <circle key={i} cx={(((i * 61) % 100) / 100) * 400} cy={((i * 37) % 240) - 10} r={2.4 + (i % 3)} />
        ))}
      </g>
    );
  }
  if (weather === "thunder") {
    return (
      <g className="ttg-lightning-flash">
        <rect x={0} y={0} width={400} height={240} fill="#2E3A55" opacity="0.22" />
        <path
          d="M 272 14 L 246 72 L 278 76 L 252 149"
          stroke="#FFE45C"
          strokeWidth="4.5"
          strokeLinecap="round"
          strokeLinejoin="round"
          fill="none"
        />
      </g>
    );
  }
  return null;
}

export function PetScene({
  pets,
  sleeping,
  weather,
  frame = "none",
}: {
  pets: Pet[];
  sleeping: boolean;
  weather?: string | null;
  frame?: string;
}) {
  const hasPond = pets.some((p) => isAquatic(p.type));
  const dimSky = weather === "cloudy" || weather === "rain" || weather === "thunder";
  const frameColor =
    frame === "gold" ? "#FFC800" : frame === "neon" ? "#1CB0F6" : frame === "flower" ? "#FF8FB1" : null;

  const landPets = pets.filter((p) => !isAquatic(p.type));
  const waterPets = pets.filter((p) => isAquatic(p.type));

  const skyColors: [string, string] =
    weather === "thunder"
      ? ["#6B7B95", "#B9C6A8"]
      : weather === "rain"
        ? ["#8FB8CF", "#CBE3C8"]
        : weather === "cloudy"
          ? ["#AFC6D6", "#E2EFD8"]
          : weather === "snow"
            ? ["#BAD8EE", "#EFF7EF"]
            : ["#A6E4FF", "#EAF9E0"];

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
          <stop offset="0" stopColor={skyColors[0]} />
          <stop offset="1" stopColor={skyColors[1]} />
        </linearGradient>
      </defs>

      <rect x="0" y="0" width="400" height="240" fill="url(#ttg-sky)" />

      {!dimSky && (
        <g>
          <circle cx="64" cy="33.6" r="34" fill="#FFC800" opacity="0.25" />
          <circle cx="64" cy="33.6" r="22" fill="#FFC800" />
        </g>
      )}

      <Cloud cx={220} cy={33.6} r={18} dur={34} delay={-8} />
      <Cloud cx={312} cy={57.6} r={14} dur={26} delay={-3} />
      {(weather === "partly" || weather === "cloudy" || weather === "rain") && (
        <>
          <Cloud cx={128} cy={24} r={15} dur={30} delay={-5} />
          <Cloud cx={368} cy={21.6} r={12} dur={22} delay={-1} />
        </>
      )}

      {/* Лужайка */}
      <path
        d="M 0 205.6 Q 0 177.6 28 177.6 L 372 177.6 Q 400 177.6 400 205.6 L 400 240 L 0 240 Z"
        fill="#90D26D"
      />
      <circle cx="48" cy="199.2" r="22" fill="#7FC45C" />
      <circle cx="352" cy="194.4" r="18" fill="#7FC45C" />

      {/* Цветочки */}
      {[
        { x: 24, y: 211.2, c: "#FF8FB1" },
        { x: 112, y: 201.6, c: "#FFD166" },
        { x: 288, y: 216, c: "#EF476F" },
        { x: 380, y: 206.4, c: "#FFD166" },
      ].map((f, i) => (
        <g key={i}>
          <circle cx={f.x} cy={f.y} r="4" fill={f.c} />
          <circle cx={f.x} cy={f.y} r="1.6" fill="#FFFFFF" />
        </g>
      ))}

      {/* Трава пучками — качается на ветру (v2.0.0) */}
      {[
        { x: 22, y: 209, h: 15 },
        { x: 74, y: 200, h: 19 },
        { x: 142, y: 212, h: 13 },
        { x: 206, y: 222, h: 18 },
        { x: 262, y: 205, h: 15 },
        { x: 326, y: 214, h: 19 },
        { x: 386, y: 200, h: 13 },
      ].map((g, i) => (
        <g
          key={i}
          className="ttg-sway"
          style={{
            animationDuration: `${3.2 + (i % 3) * 0.7}s`,
            animationDelay: `${-i * 0.9}s`,
            transformBox: "fill-box",
            transformOrigin: "50% 100%",
          }}
        >
          <path
            d={[-5, -1.5, 2.5, 6]
              .map(
                (dx) =>
                  `M ${g.x + dx} ${g.y} Q ${g.x + dx} ${g.y - g.h * 0.6} ${g.x + dx + dx * 0.35} ${g.y - g.h}`,
              )
              .join(" ")}
            stroke={i % 2 ? "#6FBC5E" : "#5FA852"}
            strokeWidth="2.2"
            fill="none"
            strokeLinecap="round"
          />
        </g>
      ))}

      {/* Пруд для водных питомцев (v1.8.0) */}
      {hasPond && (
        <g>
          <ellipse cx="200" cy="198.4" rx={400 * 0.3 * 1.08} ry={240 * 0.115 * 1.08} fill="#E8D8A8" />
          <ellipse cx="200" cy="198.4" rx={400 * 0.3} ry={240 * 0.115} fill="#6EC1E4" />
          <path d="M 170 191 Q 185 186 200 191" stroke="#FFFFFF" strokeWidth="2" fill="none" opacity="0.5" strokeLinecap="round" />
          <path d="M 215 205 Q 230 200 245 205" stroke="#FFFFFF" strokeWidth="2" fill="none" opacity="0.5" strokeLinecap="round" />
        </g>
      )}

      {/* Сухопутные питомцы */}
      {landPets.map((p, i) => (
        <PetFigure
          key={p.id}
          pet={p}
          index={i}
          total={landPets.length}
          sleeping={sleeping}
          pondActive={false}
        />
      ))}

      {/* Водные питомцы в пруду */}
      {waterPets.map((p, i) => (
        <PetFigure
          key={p.id}
          pet={p}
          index={landPets.length + i}
          total={pets.length}
          sleeping={sleeping}
          pondActive
        />
      ))}

      {/* Передняя кромка воды — тела «погружены» */}
      {hasPond && (
        <g>
          <ellipse cx="200" cy="198.4" rx={400 * 0.3} ry={240 * 0.115} fill="#6EC1E4" opacity="0.45" />
          <ellipse
            cx="200"
            cy="206"
            rx={400 * 0.3 * 0.5}
            ry={240 * 0.115 * 0.4}
            stroke="#FFFFFF"
            strokeWidth="2"
            fill="none"
            opacity="0.5"
          />
        </g>
      )}

      <WeatherLayers weather={weather} />

      {/* Бабочки порхают над лужайкой (v2.0.0) */}
      {!sleeping && weather !== "thunder" && weather !== "rain" && (
        <>
          <g className="ttg-fly" style={{ animationDuration: "17s" }}>
            <g className="ttg-fly-bob" style={{ animationDuration: "3.1s" }}>
              <g transform="translate(0 82)">
                <g className="ttg-flap" style={{ animationDuration: "0.42s" }}>
                  <ellipse cx={-4} cy={-1.6} rx={3.6} ry={2.5} fill="#FF9F45" />
                  <ellipse cx={4} cy={-1.6} rx={3.6} ry={2.5} fill="#FF9F45" />
                  <ellipse cx={-3} cy={2} rx={2.2} ry={1.6} fill="#FFD166" />
                  <ellipse cx={3} cy={2} rx={2.2} ry={1.6} fill="#FFD166" />
                </g>
                <line x1={0} y1={-2.6} x2={0} y2={3.4} stroke="#5A4632" strokeWidth={1.6} strokeLinecap="round" />
              </g>
            </g>
          </g>
          <g className="ttg-fly" style={{ animationDuration: "23s", animationDelay: "-9s" }}>
            <g className="ttg-fly-bob" style={{ animationDuration: "2.6s", animationDelay: "-1.2s" }}>
              <g transform="translate(0 96)">
                <g className="ttg-flap" style={{ animationDuration: "0.5s", animationDelay: "-0.2s" }}>
                  <ellipse cx={-4.6} cy={-1.8} rx={4.1} ry={2.9} fill="#B892E0" />
                  <ellipse cx={4.6} cy={-1.8} rx={4.1} ry={2.9} fill="#B892E0" />
                  <ellipse cx={-3.4} cy={2.2} rx={2.5} ry={1.8} fill="#8FBFF2" />
                  <ellipse cx={3.4} cy={2.2} rx={2.5} ry={1.8} fill="#8FBFF2" />
                </g>
                <line x1={0} y1={-3} x2={0} y2={3.8} stroke="#5A4632" strokeWidth={1.6} strokeLinecap="round" />
              </g>
            </g>
          </g>
        </>
      )}

      {/* Декоративная рамка из магазина (v1.5.0) */}
      {frameColor && (
        <g>
          <rect x="7" y="7" width="386" height="226" rx="24" stroke={frameColor} strokeWidth="5.5" fill="none" />
          {[
            [17, 17],
            [383, 17],
            [17, 223],
            [383, 223],
          ].map(([x, y], i) => (
            <circle key={i} cx={x} cy={y} r={4.5} fill={frameColor} opacity="0.85" />
          ))}
        </g>
      )}
    </svg>
  );
}
