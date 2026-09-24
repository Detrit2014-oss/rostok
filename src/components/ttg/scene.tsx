"use client";

// Порт lib/widgets/pet_canvas.dart (v2.1.0 «Настоящие звери»): небо, солнце,
// облака, лужайка, грядка растений, пруд справа, погода (дождь/снег/туман/
// гроза) — процедурные. Питомцы — РЕАЛИСТИЧНЫЕ ИЛЛЮСТРАЦИИ-СПРАЙТЫ
// (public/sprites/<вид>.webp), оживлённые повадками: зверь гуляет по полосам
// глубины, принюхивается, щиплет траву, сидит; птицы клюют; зайчик прыгает;
// водные жители патрулируют пруд; спящие звери ЛЕЖАТ (поза сна).
// Аксессуары гардероба рисуются по якорям спрайта.

import { useEffect, useRef, useState } from "react";
import type { CSSProperties } from "react";

import {
  GEOM,
  SPRITE_META,
  anchorsFor,
  bodyColor,
  HOP_PETS,
  isAquatic,
  isPlant,
  laneScales,
  laneYs,
  Pet,
  petStage,
  spriteAsset,
  spriteAspect,
  spriteStageScale,
  stageProgress,
} from "@/lib/ttg/types";
import type { PetType } from "@/lib/ttg/types";

const VB_W = 400;
const VB_H = 240;
const GROUND_Y = VB_H * GEOM.groundYF; // 177.6
const CRACK = "#C9A96E";
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

/** Семечко на грядке (растения, стадия 0). */
function SeedBed({ progress }: { progress: number }) {
  const s = 1;
  return (
    <g>
      <ellipse cx={0} cy={-6 * s} rx={26 * s} ry={9 * s} fill={SOIL} />
      <ellipse cx={0} cy={-9 * s} rx={22 * s} ry={6 * s} fill="#96683F" />
      <g transform={`translate(2 ${-12 * s}) rotate(-35)`} className="ttg-egg" style={{ ["--wobble" as string]: "1deg" }}>
        <ellipse cx={0} cy={0} rx={4.5 * s} ry={6.5 * s} fill="#C89B62" />
        <ellipse cx={-1.6 * s} cy={-2.4 * s} rx={1.7 * s} ry={2.5 * s} fill="#E5C793" />
      </g>
      {progress > 0.4 && (
        <path
          d={`M ${-14 * s} ${-4 * s} L ${-8 * s} ${-8 * s} L ${-11 * s} ${-13 * s}`}
          stroke="#5E3D22" strokeWidth={2} strokeLinecap="round" fill="none"
        />
      )}
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
      {progress > 0.85 && (
        <g>
          <circle cx={-16 * s} cy={-26 * s} r={2.2 * s} fill="#FFD166" />
          <circle cx={-16 * s} cy={-26 * s} r={0.9 * s} fill="#FFFFFF" />
        </g>
      )}
    </g>
  );
}

// ── Повадки настоящих зверей — порт _petBehavior из Dart ──────────────
const STROLL_PERIOD = 21; // цикл «прогулка + пауза», с
const PAUSE_AT = 13.5; // начало паузы внутри цикла
const PAUSE_LEN = 3.8; // длительность паузы, с
const CROSS_SEC = 8.2; // полпути через лужайку, с

interface PetBehavior {
  x: number;
  facing: number;
  kind: "walk" | "sniff" | "graze" | "sit" | "peck" | "look";
  headPitch: number;
  stride: number;
  poseEase: number;
}

const GRAZERS: PetType[] = ["deer", "unicorn", "bunny", "squirrel", "pig", "koala", "panda", "dragon", "hedgehog"];
const PERCHERS: PetType[] = ["fox", "cat", "dog", "raccoon", "bear"];
const PECKERS: PetType[] = ["owl", "duck", "chick", "penguin"];

function strHash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  }
  return h;
}

function pbHash(a: number, b: number): number {
  let h = (Math.imul(a, 374761393) + Math.imul(b, 668265263)) & 0x7fffffff;
  h = Math.imul(h ^ (h >>> 13), 1274126177) & 0x7fffffff;
  return ((h ^ (h >>> 16)) & 0x7fffffff) / 0x7fffffff;
}

function petBehavior(pet: Pet, tSec: number): PetBehavior {
  const seed = strHash(pet.id) & 0x7fffffff;
  const off = (seed % 1900) / 100;
  const total = tSec + off;
  const local = total % STROLL_PERIOD;
  const cycle = Math.floor(total / STROLL_PERIOD);

  const pauseDone =
    Math.floor(total / STROLL_PERIOD) * PAUSE_LEN +
    (local >= PAUSE_AT ? Math.min(local - PAUSE_AT, PAUSE_LEN) : 0);
  const walkT = tSec - pauseDone;

  const tri = ((walkT + off) / CROSS_SEC) % 2;
  const x = tri < 1 ? tri : 2 - tri;
  const facing = tri < 1 ? 1 : -1;
  const stride = ((walkT + off) * 2 * Math.PI) / 0.8;

  if (local < PAUSE_AT || local >= PAUSE_AT + PAUSE_LEN) {
    return { x, facing, kind: "walk", headPitch: 0.05 + Math.sin(stride * 2) * 0.03, stride, poseEase: 0 };
  }

  const r = pbHash(seed, cycle);
  let kind: PetBehavior["kind"];
  if (PECKERS.includes(pet.type)) {
    kind = r < 0.62 ? "peck" : "look";
  } else if (PERCHERS.includes(pet.type)) {
    kind = r < 0.4 ? "sniff" : r < 0.78 ? "sit" : "look";
  } else if (GRAZERS.includes(pet.type)) {
    kind = r < 0.55 ? "graze" : r < 0.85 ? "sniff" : "look";
  } else {
    kind = r < 0.5 ? "sniff" : "look";
  }

  const tin = Math.min(1, Math.max(0, (local - PAUSE_AT) / 0.7));
  const tout = Math.min(1, Math.max(0, (PAUSE_AT + PAUSE_LEN - local) / 0.7));
  const e = Math.min(tin, tout);
  const ease = e * e * (3 - 2 * e);

  let target: number;
  switch (kind) {
    case "graze":
      target = 1.0 + Math.sin(tSec * 8.5) * 0.06;
      break;
    case "sniff":
      target = 0.62 + Math.sin(tSec * 7.0) * 0.07;
      break;
    case "peck": {
      const pp = (((local - PAUSE_AT) / PAUSE_LEN) * 3) % 1;
      target = Math.sin(pp * Math.PI) * 0.85;
      break;
    }
    default:
      target = 0.1 + Math.sin(tSec * 1.6) * 0.12;
  }
  return { x, facing, kind, headPitch: target * ease, stride, poseEase: ease };
}

/** rAF-крючок: пересчитывает повадки ~24 раза в секунду (SSR-safe). */
function useBehavior(pet: Pet, active: boolean): PetBehavior | null {
  const [bhv, setBhv] = useState<PetBehavior | null>(null);
  const petRef = useRef(pet);
  useEffect(() => {
    petRef.current = pet;
  }, [pet]);
  useEffect(() => {
    if (!active) return; // на паузе цикл не нужен
    const t0 = performance.now();
    let raf = 0;
    let last = -1;
    const loop = (now: number) => {
      const tSec = (now - t0) / 1000;
      const frame = Math.floor(tSec * 24);
      if (frame !== last) {
        last = frame;
        setBhv(petBehavior(petRef.current, tSec));
      }
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [active, pet.id]);
  // Пока повадки неактивны (сон/яйцо) — фигура их не использует.
  return active ? bhv : null;
}

// ── Спрайт питомца + аксессуары ────────────────────────────────────────

interface SpriteLayout {
  /** Точка опоры (контакт с землёй) в координатах сцены. */
  gx: number;
  gy: number;
  /** Масштаб глубины (полосы лужайки). */
  depth: number;
  facing: number;
  /** Наклон в РАДИАНКАХ (как в Dart canvas.rotate). */
  tiltRad: number;
  /** Подъём над землёй (прыжки, качка). */
  lift: number;
}

function SpritePet({
  pet,
  sleeping,
  layout,
}: {
  pet: Pet;
  sleeping: boolean;
  layout: SpriteLayout;
}) {
  const stage = petStage(pet);
  const meta = SPRITE_META[pet.type] ?? { h: 0.16, sleep: true };
  const aspect = spriteAspect(pet.type);
  const boxH = VB_H * meta.h * spriteStageScale(stage) * layout.depth;
  const boxW = boxH * aspect;
  const useSleep = sleeping && meta.sleep;
  const src = spriteAsset(pet.type, useSleep);
  const anchors = anchorsFor(pet.type);

  return (
    <g
      transform={`translate(${layout.gx} ${layout.gy + layout.lift}) rotate(${(layout.tiltRad * 180) / Math.PI}) scale(${layout.facing} 1)`}
    >
      <image
        href={src}
        x={-boxW / 2}
        y={-boxH}
        width={boxW}
        height={boxH}
        preserveAspectRatio="none"
        style={{ filter: sleeping && !meta.sleep ? "brightness(0.88)" : undefined }}
      />
      {!useSleep && <Accessories pet={pet} boxW={boxW} boxH={boxH} anchors={anchors} />}
    </g>
  );
}

/** Аксессуары гардероба по якорям (u = 1% ширины спрайта). */
function Accessories({
  pet,
  boxW,
  boxH,
  anchors,
}: {
  pet: Pet;
  boxW: number;
  boxH: number;
  anchors: ReturnType<typeof anchorsFor>;
}) {
  const u = boxW / 100;
  const pt = (p: [number, number]) => ({ x: p[0] * boxW - boxW / 2, y: p[1] * boxH - boxH });
  const hat = pt(anchors.hat);
  const neck = pt(anchors.neck);
  const eye = pt(anchors.eye);
  return (
    <g>
      {pet.hat === "cap" && (
        <g>
          <path d={`M ${hat.x - 14 * u} ${hat.y} Q ${hat.x} ${hat.y - 22 * u} ${hat.x + 14 * u} ${hat.y} Z`} fill="#EF476F" />
          <rect x={hat.x + 6 * u} y={hat.y - 2 * u} width={14 * u} height={4 * u} rx={3} fill="#D63860" />
          <circle cx={hat.x} cy={hat.y - 12 * u} r={2.2 * u} fill="#FFFFFF" />
        </g>
      )}
      {pet.hat === "beanie" && (
        <g>
          <path d={`M ${hat.x - 14 * u} ${hat.y} Q ${hat.x} ${hat.y - 20 * u} ${hat.x + 14 * u} ${hat.y} Z`} fill="#B892E0" />
          <rect x={hat.x - 14 * u} y={hat.y - 2 * u} width={28 * u} height={4.4 * u} rx={2} fill="#9A77C9" />
          <circle cx={hat.x} cy={hat.y - 20 * u} r={3.4 * u} fill="#F7F1EA" />
        </g>
      )}
      {pet.hat === "crown" && (
        <g>
          <path
            d={`M ${hat.x - 11 * u} ${hat.y} L ${hat.x - 11 * u} ${hat.y - 10 * u} L ${hat.x - 5.5 * u} ${hat.y - 5 * u} L ${hat.x} ${hat.y - 12 * u} L ${hat.x + 5.5 * u} ${hat.y - 5 * u} L ${hat.x + 11 * u} ${hat.y - 10 * u} L ${hat.x + 11 * u} ${hat.y} Z`}
            fill="#FFC800"
          />
          <circle cx={hat.x} cy={hat.y - 3 * u} r={1.8 * u} fill="#EF476F" />
        </g>
      )}
      {pet.hat === "flowerPin" &&
        [0, 1, 2, 3, 4].map((i) => {
          const a = (i * 2 * Math.PI) / 5 - Math.PI / 2;
          return <circle key={i} cx={hat.x + Math.cos(a) * 3.4 * u} cy={hat.y + Math.sin(a) * 3.4 * u} r={2.4 * u} fill="#FF8FB1" />;
        })}
      {pet.hat === "flowerPin" && <circle cx={hat.x} cy={hat.y} r={2.2 * u} fill="#FFD166" />}

      {pet.neck === "scarf" && (
        <g>
          <rect x={neck.x - 13 * u} y={neck.y - 3.5 * u} width={26 * u} height={7 * u} rx={3.5 * u} fill="#EF6461" />
          <rect x={neck.x - 12 * u} y={neck.y} width={7 * u} height={15 * u} rx={3 * u} fill="#D63860" />
        </g>
      )}
      {pet.neck === "bow" && (
        <g>
          <path d={`M ${neck.x} ${neck.y} L ${neck.x - 12 * u} ${neck.y - 7 * u} Q ${neck.x - 15 * u} ${neck.y} ${neck.x - 12 * u} ${neck.y + 7 * u} Z`} fill="#FF6FA5" />
          <path d={`M ${neck.x} ${neck.y} L ${neck.x + 12 * u} ${neck.y - 7 * u} Q ${neck.x + 15 * u} ${neck.y} ${neck.x + 12 * u} ${neck.y + 7 * u} Z`} fill="#FF6FA5" />
          <circle cx={neck.x} cy={neck.y} r={2.6 * u} fill="#E85D8A" />
        </g>
      )}
      {pet.neck === "bandana" && (
        <g>
          <path d={`M ${neck.x - 13 * u} ${neck.y - 3 * u} L ${neck.x + 13 * u} ${neck.y - 3 * u} L ${neck.x} ${neck.y + 11 * u} Z`} fill="#3E7BFA" />
          <rect x={neck.x - 13 * u} y={neck.y - 5.5 * u} width={26 * u} height={5 * u} rx={2.5 * u} fill="#2F63D6" />
        </g>
      )}
      {pet.neck === "bell" && (
        <g>
          <rect x={neck.x - 12 * u} y={neck.y - 1.8 * u} width={24 * u} height={3.6 * u} rx={2 * u} fill="#D63860" />
          <circle cx={neck.x} cy={neck.y + 5 * u} r={4.6 * u} fill="#FFC800" />
          <circle cx={neck.x} cy={neck.y + 5 * u} r={2.1 * u} fill="#E09E00" />
          <circle cx={neck.x} cy={neck.y + 3.4 * u} r={1.1 * u} fill="#FFFFFF" />
        </g>
      )}
      {pet.face === "glasses" && (
        <g stroke="#3A3A3A" strokeWidth={1.8 * u} fill="none">
          <circle cx={eye.x} cy={eye.y} r={5.2 * u} />
          <line x1={eye.x + 5.2 * u} y1={eye.y} x2={eye.x + 11 * u} y2={eye.y - 1.5 * u} />
        </g>
      )}
      {pet.face === "shades" && (
        <g>
          <rect x={eye.x - 5.5 * u} y={eye.y - 4 * u} width={11 * u} height={8 * u} rx={3 * u} fill="#23262B" />
          <line x1={eye.x + 5.5 * u} y1={eye.y - 1 * u} x2={eye.x + 11 * u} y2={eye.y - 2.5 * u} stroke="#23262B" strokeWidth={1.8 * u} />
        </g>
      )}
    </g>
  );
}

/** zzz над спящим питомцем. */
function Zzz({ x, y, s }: { x: number; y: number; s: number }) {
  return (
    <g className="ttg-zzz" fill="#6B7B8C" fontWeight="800" fontFamily="inherit">
      <text x={x} y={y} fontSize={11 * s} opacity="0.9">z</text>
      <text x={x + 9 * s} y={y - 10 * s} fontSize={14 * s} opacity="0.7">z</text>
      <text x={x + 18 * s} y={y - 20 * s} fontSize={17 * s} opacity="0.5">Z</text>
    </g>
  );
}

// ── Фигура питомца в сцене ─────────────────────────────────────────────

function PlantFigure({
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
  const stage = petStage(pet);
  const x0 = VB_W * GEOM.bedX0F;
  const x1 = VB_W * GEOM.bedX1F;
  const slotX = x0 + (x1 - x0) * (total === 1 ? 0.5 : index / (total - 1));
  const baseY = VB_H * GEOM.bedYF - 2;
  if (stage === 0) {
    return (
      <g transform={`translate(${slotX} ${baseY})`}>
        <SeedBed progress={stageProgress(pet)} />
        {sleeping && <Zzz x={22} y={-26} s={1} />}
      </g>
    );
  }
  const meta = SPRITE_META[pet.type] ?? { h: 0.14, sleep: false };
  const boxH = VB_H * meta.h * spriteStageScale(stage);
  const boxW = boxH * spriteAspect(pet.type);
  return (
    <g transform={`translate(${slotX - boxW / 2} ${baseY})`}>
      <g
        className="ttg-sway"
        style={{
          animationDuration: `${3.4 + (index % 3) * 0.8}s`,
          animationDelay: `${-index * 1.1}s`,
          transformBox: "fill-box",
          transformOrigin: "50% 100%",
        }}
      >
        <SpritePet
          pet={pet}
          sleeping={sleeping}
          layout={{ gx: boxW / 2, gy: 0, depth: 1, facing: 1, tiltRad: 0, lift: 0 }}
        />
      </g>
      {sleeping && <Zzz x={boxW * 0.42} y={-boxH * 0.95} s={1} />}
    </g>
  );
}

function WaterFigure({
  pet,
  sleeping,
  active,
}: {
  pet: Pet;
  sleeping: boolean;
  active: boolean;
}) {
  // Патрулирование пруда — детерминировано, как в Dart (sin/cos от tSec).
  const [tick, setTick] = useState(0);
  useEffect(() => {
    if (!active) return;
    const t0 = performance.now();
    let raf = 0;
    const loop = (now: number) => {
      setTick(Math.floor(((now - t0) / 1000) * 24));
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, [active]);

  const stage = petStage(pet);
  const seed = strHash(pet.id) & 0x7fffffff;
  const off = (seed % 1000) / 100;
  const tSec = tick / 24;
  const cx = VB_W * GEOM.pondCXF;
  const cy = VB_H * GEOM.pondCYF;
  const rw = VB_W * GEOM.pondRWF;
  const rh = VB_H * GEOM.pondRHF;

  const swimT = tSec * (pet.type === "crab" ? 0.14 : 0.22) + off;
  const dx = Math.sin(swimT) * rw * 0.45;
  const dy = Math.sin(tSec * 1.2 + off * 2) * rh * 0.1;
  const goingRight = Math.cos(swimT) > 0;
  const baseY =
    pet.type === "crab" ? cy + rh * 0.42 + dy : cy - rh * 0.22 + dy;

  const meta = SPRITE_META[pet.type] ?? { h: 0.12, sleep: true };
  let boxH = VB_H * meta.h * spriteStageScale(stage);
  let boxW = boxH * spriteAspect(pet.type);
  if (boxW > rw * 1.25) {
    boxW = rw * 1.25;
    boxH = boxW / spriteAspect(pet.type);
  }

  return (
    <g>
      <SpritePet
        pet={pet}
        sleeping={sleeping}
        layout={{
          gx: cx + dx,
          gy: baseY,
          depth: 1,
          facing: goingRight ? 1 : -1,
          tiltRad: Math.sin(tSec * 1.1 + off) * 0.03,
          lift: 0,
        }}
      />
      {/* Фонтанчик у кита каждые ~7 с */}
      {pet.type === "whale" && !sleeping && (
        <g className="ttg-fountain" transform={`translate(${cx + dx - boxW * 0.28 * (goingRight ? 1 : -1)} ${baseY - boxH * 0.9})`}>
          <line x1={0} y1={0} x2={0} y2={-9} stroke="#BFE6F7" strokeWidth="2.4" strokeLinecap="round" opacity="0.85" />
          {[0, 1, 2, 3].map((i) => (
            <circle key={i} cx={-3 + i * 2.2} cy={-12 - (i % 2) * 4} r={1.6} fill="#9FD4EF" opacity="0.8" />
          ))}
        </g>
      )}
      {sleeping && <Zzz x={cx + dx + boxW * 0.4} y={baseY - boxH} s={1} />}
    </g>
  );
}

function LandFigure({
  pet,
  index,
  total,
  sleeping,
  eggIndex,
}: {
  pet: Pet;
  index: number;
  total: number;
  sleeping: boolean;
  eggIndex: number;
}) {
  const stage = petStage(pet);
  const ys = laneYs(total);
  const scales = laneScales(total);
  const laneY = VB_H * ys[index];
  const depth = scales[index];
  const isEgg = stage === 0;

  // Хук вызывается безусловно (правила хуков), даже для яйца/сна.
  const bhv = useBehavior(pet, !sleeping && !isEgg);

  // Яйцо стоит слева на своей полосе и покачивается.
  if (isEgg) {
    return (
      <g transform={`translate(${VB_W * (0.12 + 0.09 * eggIndex)} ${laneY})`}>
        <Egg spot={bodyColor(pet.type)} progress={stageProgress(pet)} />
      </g>
    );
  }

  const hasSleep = SPRITE_META[pet.type]?.sleep ?? true;
  void hasSleep;

  if (sleeping) {
    const spotX = VB_W * (total === 1 ? 0.5 : 0.14 + (0.72 * index) / Math.max(1, total - 1));
    const meta = SPRITE_META[pet.type] ?? { h: 0.16, sleep: true };
    const boxH = VB_H * meta.h * spriteStageScale(stage) * depth;
    const boxW = boxH * spriteAspect(pet.type);
    return (
      <g>
        <ellipse cx={spotX} cy={laneY + 2} rx={boxW * 0.31} ry={boxW * 0.05} fill="#2E7D32" opacity="0.14" />
        <SpritePet
          pet={pet}
          sleeping
          layout={{ gx: spotX, gy: laneY, depth, facing: 1, tiltRad: 0, lift: 0 }}
        />
        <Zzz x={spotX + boxW * 0.44} y={laneY - boxH * 0.92} s={depth} />
      </g>
    );
  }

  // Повадки: наклон (рад, как в Dart) и подпрыгивание по типу позы.
  let tiltRad = 0;
  let lift = 0;
  if (HOP_PETS.includes(pet.type)) {
    const hopPhase = ((performance.now() / 1000) * 2 * Math.PI) / 0.85;
    const hopAmp = bhv && bhv.kind === "walk" ? 1 : 0;
    lift = -Math.abs(Math.sin(hopPhase)) * 0.28 * hopAmp;
    tiltRad = Math.sin(hopPhase + 0.6) * 0.1 * hopAmp;
  } else if (bhv?.kind === "walk") {
    tiltRad = Math.sin(bhv.stride) * 0.035;
    lift = -Math.abs(Math.sin(bhv.stride * 2)) * 2;
  } else if (bhv) {
    switch (bhv.kind) {
      case "graze":
        tiltRad = 0.14 + Math.sin(performance.now() / 1000 * 8.5) * 0.03;
        break;
      case "sniff":
        tiltRad = 0.07 + Math.sin(performance.now() / 1000 * 7.0) * 0.02;
        break;
      case "peck":
        tiltRad = 0.24 + Math.sin(performance.now() / 1000 * 9.0) * 0.05;
        break;
      case "look":
        tiltRad = -0.02 + Math.sin(performance.now() / 1000 * 1.6) * 0.025;
        break;
      default:
        tiltRad = Math.sin(performance.now() / 1000 * 1.2 + index) * 0.012;
    }
  }

  const bhvX = bhv?.x ?? 0.5;
  const gx = VB_W * (0.13 + 0.74 * bhvX);
  const meta = SPRITE_META[pet.type] ?? { h: 0.16, sleep: true };
  const boxH = VB_H * meta.h * spriteStageScale(stage) * depth;
  const boxW = boxH * spriteAspect(pet.type);

  return (
    <g>
      <ellipse cx={gx} cy={laneY + 2} rx={boxW * 0.31} ry={boxW * 0.05} fill="#2E7D32" opacity="0.18" />
      <SpritePet
        pet={pet}
        sleeping={false}
        layout={{
          gx,
          gy: laneY,
          depth,
          facing: bhv?.facing ?? 1,
          tiltRad,
          lift: lift * boxH,
        }}
      />
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
  const hasBed = pets.some((p) => isPlant(p.type));
  const dimSky = weather === "cloudy" || weather === "rain" || weather === "thunder";
  const frameColor =
    frame === "gold" ? "#FFC800" : frame === "neon" ? "#1CB0F6" : frame === "flower" ? "#FF8FB1" : null;

  const plants = pets.filter((p) => isPlant(p.type));
  const water = pets.filter((p) => isAquatic(p.type));
  const land = pets.filter((p) => !isAquatic(p.type) && !isPlant(p.type));
  let eggCounter = 0;

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

  const pondCX = VB_W * GEOM.pondCXF;
  const pondCY = VB_H * GEOM.pondCYF;
  const pondRW = VB_W * GEOM.pondRWF;
  const pondRH = VB_H * GEOM.pondRHF;

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
        { x: 144, y: 201.6, c: "#FFD166" },
        { x: 288, y: 216, c: "#EF476F" },
        { x: 380, y: 206.4, c: "#FFD166" },
      ].map((f, i) => (
        <g key={i}>
          <circle cx={f.x} cy={f.y} r="4" fill={f.c} />
          <circle cx={f.x} cy={f.y} r="1.6" fill="#FFFFFF" />
        </g>
      ))}

      {/* Трава пучками — качается на ветру */}
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

      {/* Грядка растений слева сзади */}
      {hasBed && (
        <g>
          <rect
            x={VB_W * GEOM.bedX0F - 4}
            y={VB_H * GEOM.bedYF - 13.2 - 4}
            width={(VB_W * GEOM.bedX1F - VB_W * GEOM.bedX0F) + 8}
            height={13.2 + 6 + 8}
            rx={12}
            fill="#A9744F"
          />
          <rect
            x={VB_W * GEOM.bedX0F}
            y={VB_H * GEOM.bedYF - 13.2}
            width={VB_W * GEOM.bedX1F - VB_W * GEOM.bedX0F}
            height={13.2 + 6}
            rx={10}
            fill={SOIL}
          />
          <rect
            x={VB_W * GEOM.bedX0F + 4}
            y={VB_H * GEOM.bedYF - 13.2 + 4}
            width={VB_W * GEOM.bedX1F - VB_W * GEOM.bedX0F - 8}
            height={13.2 + 6 - 8}
            rx={8}
            fill="#96683F"
          />
        </g>
      )}

      {/* Растения на грядке */}
      {plants.map((p, i) => (
        <PlantFigure key={p.id} pet={p} index={i} total={plants.length} sleeping={sleeping} />
      ))}

      {/* Пруд для водных питомцев (справа сзади) */}
      {hasPond && (
        <g>
          <ellipse cx={pondCX} cy={pondCY} rx={pondRW * 1.08} ry={pondRH * 1.08} fill="#E8D8A8" />
          <ellipse cx={pondCX} cy={pondCY} rx={pondRW} ry={pondRH} fill="#6EC1E4" />
          <path d={`M ${pondCX - 30} ${pondCY - 6} Q ${pondCX - 15} ${pondCY - 11} ${pondCX} ${pondCY - 6}`} stroke="#FFFFFF" strokeWidth="2" fill="none" opacity="0.5" strokeLinecap="round" />
          <path d={`M ${pondCX + 15} ${pondCY + 7} Q ${pondCX + 30} ${pondCY + 2} ${pondCX + 45} ${pondCY + 7}`} stroke="#FFFFFF" strokeWidth="2" fill="none" opacity="0.5" strokeLinecap="round" />
        </g>
      )}

      {/* Водные питомцы в пруду */}
      {water.map((p) => (
        <WaterFigure key={p.id} pet={p} sleeping={sleeping} active={!sleeping} />
      ))}

      {/* Передняя кромка воды — тела «погружены» */}
      {hasPond && (
        <g>
          <ellipse cx={pondCX} cy={pondCY} rx={pondRW} ry={pondRH} fill="#6EC1E4" opacity="0.45" />
          <ellipse
            cx={pondCX}
            cy={pondCY + 7.6}
            rx={pondRW * 0.5}
            ry={pondRH * 0.4}
            stroke="#FFFFFF"
            strokeWidth="2"
            fill="none"
            opacity="0.5"
          />
        </g>
      )}

      {/* Сухопутные питомцы по полосам глубины */}
      {land.map((p, i) => {
        const stage = petStage(p);
        const eggIndex = stage === 0 ? eggCounter++ : -1;
        return (
          <LandFigure
            key={p.id}
            pet={p}
            index={i}
            total={land.length}
            sleeping={sleeping}
            eggIndex={eggIndex}
          />
        );
      })}

      <WeatherLayers weather={weather} />

      {/* Бабочки порхают над лужайкой */}
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

      {/* Декоративная рамка из магазина */}
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
