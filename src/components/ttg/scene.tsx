"use client";

// Порт lib/widgets/pet_canvas.dart: небо, солнце, облака, лужайка
// и питомцы, нарисованные полностью процедурно (SVG) — ни одной картинки.

import type { CSSProperties } from "react";

import { bellyColor, bodyColor, Pet, petStage, stageProgress } from "@/lib/ttg/types";
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

function Creature({
  s,
  type,
  sleeping,
}: {
  s: number;
  type: PetType;
  sleeping: boolean;
}) {
  const bw = 64 * s;
  const bh = 54 * s;
  const body = bodyColor(type);
  const belly = bellyColor(type);
  const bodyCy = -bh / 2;
  const earY = -bh * 0.92;
  const eyeY = bodyCy - bh * 0.05; // bodyC.dy - bh*0.05
  const eyeDX = bw * 0.17;
  const mouthY = bodyCy + bh * 0.08;

  return (
    <g>
      {/* ── За телом: лапки, уши-лопушки, ласты, крылья ────────────── */}
      {(type === "duck" || type === "penguin") && (
        <g fill={BEAK}>
          <ellipse cx={-bw * 0.18} cy={-1.5} rx={bw * 0.12} ry={bh * 0.05} />
          <ellipse cx={bw * 0.18} cy={-1.5} rx={bw * 0.12} ry={bh * 0.05} />
        </g>
      )}

      {/* Длинные уши зайчика — из-за головы, с розовой серединкой */}
      {type === "bunny" && (
        <g>
          <rect
            x={-bw * 0.16 - bw * 0.085}
            y={bodyCy - bh * 0.62 - bh * 0.31}
            width={bw * 0.17}
            height={bh * 0.62}
            rx={bw * 0.085}
            fill={body}
          />
          <rect
            x={bw * 0.16 - bw * 0.085}
            y={bodyCy - bh * 0.62 - bh * 0.31}
            width={bw * 0.17}
            height={bh * 0.62}
            rx={bw * 0.085}
            fill={body}
          />
          <rect
            x={-bw * 0.16 - bw * 0.04}
            y={bodyCy - bh * 0.56 - bh * 0.21}
            width={bw * 0.08}
            height={bh * 0.42}
            rx={bw * 0.04}
            fill="#F5B8C4"
          />
          <rect
            x={bw * 0.16 - bw * 0.04}
            y={bodyCy - bh * 0.56 - bh * 0.21}
            width={bw * 0.08}
            height={bh * 0.42}
            rx={bw * 0.04}
            fill="#F5B8C4"
          />
        </g>
      )}

      {/* Крылья дракончика (подросток и взрослый) */}
      {type === "dragon" && s >= 0.55 + 2 * 0.22 && (
        <g fill={body} opacity="0.75">
          <path
            d={`M ${-bw * 0.3} ${bodyCy - bh * 0.1} Q ${-bw * 0.9} ${bodyCy - bh * 0.9} ${-bw * 0.2} ${bodyCy - bh * 0.55} Z`}
          />
          <path
            d={`M ${bw * 0.3} ${bodyCy - bh * 0.1} Q ${bw * 0.9} ${bodyCy - bh * 0.9} ${bw * 0.2} ${bodyCy - bh * 0.55} Z`}
          />
        </g>
      )}

      {/* Ласты пингвинёнка — по бокам */}
      {type === "penguin" && (
        <g fill={body} opacity="0.85">
          <ellipse cx={-bw * 0.52} cy={bodyCy + bh * 0.02} rx={bw * 0.1} ry={bh * 0.26} />
          <ellipse cx={bw * 0.52} cy={bodyCy + bh * 0.02} rx={bw * 0.1} ry={bh * 0.26} />
        </g>
      )}

      {/* Тело и животик */}
      <ellipse cx={0} cy={bodyCy} rx={bw / 2} ry={bh / 2} fill={body} />
      <ellipse
        cx={0}
        cy={bodyCy + bh * 0.18}
        rx={bw * 0.31}
        ry={bh * 0.25}
        fill={belly}
      />

      {/* ── Поверх тела: уши, хохолки, колючки ─────────────────── */}
      {(type === "fox" || type === "cat") && (
        <g fill={body}>
          <path
            d={`M ${-bw * 0.32} ${earY + bh * 0.1} L ${-bw * 0.18} ${earY - bh * 0.22} L ${-bw * 0.05} ${earY + bh * 0.05} Z`}
          />
          <path
            d={`M ${bw * 0.32} ${earY + bh * 0.1} L ${bw * 0.18} ${earY - bh * 0.22} L ${bw * 0.05} ${earY + bh * 0.05} Z`}
          />
        </g>
      )}
      {type === "owl" && (
        <g fill={body}>
          <circle cx={-bw * 0.22} cy={earY - bh * 0.02} r={6 * s} />
          <circle cx={bw * 0.22} cy={earY - bh * 0.02} r={6 * s} />
        </g>
      )}
      {type === "dragon" && (
        <g fill="#F6E7C1">
          <circle cx={-bw * 0.14} cy={earY - bh * 0.06} r={4 * s} />
          <circle cx={bw * 0.14} cy={earY - bh * 0.06} r={4 * s} />
        </g>
      )}
      {/* Хохолок утёнка из трёх перьев */}
      {type === "duck" && (
        <g fill={body}>
          <circle cx={-bw * 0.07} cy={bodyCy - bh * 0.52} r={2.6 * s} />
          <circle cx={0} cy={bodyCy - bh * 0.58} r={2.8 * s} />
          <circle cx={bw * 0.07} cy={bodyCy - bh * 0.52} r={2.6 * s} />
        </g>
      )}
      {/* Веер колючек ёжика по верхней дуге тела */}
      {type === "hedgehog" && (
        <g fill={SPIKE}>
          {[-2.45, -2.0, -1.57, -1.14, -0.7].map((a) => {
            const tipX = bw * 0.5 * 1.42 * Math.cos(a);
            const tipY = bodyCy + bh * 0.5 * 1.42 * Math.sin(a);
            const b1X = bw * 0.5 * Math.cos(a + 0.16);
            const b1Y = bodyCy + bh * 0.5 * Math.sin(a + 0.16);
            const b2X = bw * 0.5 * Math.cos(a - 0.16);
            const b2Y = bodyCy + bh * 0.5 * Math.sin(a - 0.16);
            return (
              <polygon
                key={a}
                points={`${b1X},${b1Y} ${tipX},${tipY} ${b2X},${b2Y}`}
              />
            );
          })}
        </g>
      )}
      {/* Чёрные ушки-помпоны панды */}
      {type === "panda" && (
        <g fill={DARK}>
          <circle cx={-bw * 0.27} cy={earY - bh * 0.06} r={7.5 * s} />
          <circle cx={bw * 0.27} cy={earY - bh * 0.06} r={7.5 * s} />
        </g>
      )}
      {/* Круглые ушки медвежонка со светлой серединкой */}
      {type === "bear" && (
        <g>
          <circle cx={-bw * 0.3} cy={earY - bh * 0.06} r={8 * s} fill={body} />
          <circle cx={bw * 0.3} cy={earY - bh * 0.06} r={8 * s} fill={body} />
          <circle cx={-bw * 0.3} cy={earY - bh * 0.06} r={4 * s} fill={belly} />
          <circle cx={bw * 0.3} cy={earY - bh * 0.06} r={4 * s} fill={belly} />
        </g>
      )}

      {/* Румянец */}
      <g fill="#FF8FA3" opacity="0.55">
        <circle cx={-bw * 0.28} cy={bodyCy + bh * 0.05} r={4.5 * s} />
        <circle cx={bw * 0.28} cy={bodyCy + bh * 0.05} r={4.5 * s} />
      </g>

      {/* Пятна вокруг глаз панды — только при открытых глазах */}
      {type === "panda" && !sleeping && (
        <g fill={DARK}>
          <ellipse cx={-eyeDX} cy={eyeY} rx={bw * 0.15} ry={bh * 0.17} />
          <ellipse cx={eyeDX} cy={eyeY} rx={bw * 0.15} ry={bh * 0.17} />
        </g>
      )}

      {/* Глаза: спят во время сессии, иначе моргают */}
      {sleeping ? (
        <g stroke="#4A3B2A" strokeWidth="2.4" strokeLinecap="round">
          <line x1={-eyeDX} y1={eyeY} x2={-eyeDX + 7 * s} y2={eyeY} />
          <line x1={eyeDX - 7 * s} y1={eyeY} x2={eyeDX} y2={eyeY} />
        </g>
      ) : (
        <g
          className="ttg-blink"
          style={{
            transformBox: "fill-box",
            transformOrigin: "center",
          }}
        >
          <circle cx={-eyeDX} cy={eyeY} r={6.5 * s} fill="#FFFFFF" />
          <circle cx={eyeDX} cy={eyeY} r={6.5 * s} fill="#FFFFFF" />
          <circle cx={-eyeDX + 1.5} cy={eyeY + 1} r={3.2 * s} fill="#33261A" />
          <circle cx={eyeDX + 1.5} cy={eyeY + 1} r={3.2 * s} fill="#33261A" />
          <circle cx={-eyeDX + 2.5} cy={eyeY - 1.5} r={1.1 * s} fill="#FFFFFF" />
          <circle cx={eyeDX + 2.5} cy={eyeY - 1.5} r={1.1 * s} fill="#FFFFFF" />
        </g>
      )}

      {/* Клювы, мордочка, улыбка */}
      {(type === "owl" || type === "penguin") && (
        <path
          d={`M ${-(type === "penguin" ? 5.5 : 4) * s} ${bodyCy + bh * 0.06} L ${(type === "penguin" ? 5.5 : 4) * s} ${bodyCy + bh * 0.06} L 0 ${bodyCy + bh * 0.06 + 7 * s} Z`}
          fill={type === "penguin" ? BEAK : "#FFB703"}
        />
      )}
      {type === "duck" && (
        <rect
          x={-bw * 0.18}
          y={bodyCy + bh * 0.1 - bh * 0.08}
          width={bw * 0.36}
          height={bh * 0.16}
          rx={4 * s}
          fill={BEAK}
        />
      )}
      {type === "bear" && (
        <g>
          <ellipse cx={0} cy={bodyCy + bh * 0.16} rx={bw * 0.2} ry={bh * 0.15} fill={belly} />
          <circle cx={0} cy={bodyCy + bh * 0.1} r={3.2 * s} fill={DARK} />
          <path
            d={`M ${-6 * s} ${bodyCy + bh * 0.2} Q 0 ${bodyCy + bh * 0.26} ${6 * s} ${bodyCy + bh * 0.2}`}
            stroke={DARK}
            strokeWidth="2.2"
            strokeLinecap="round"
            fill="none"
          />
        </g>
      )}
      {type !== "owl" &&
        type !== "penguin" &&
        type !== "duck" &&
        type !== "bear" && (
          <path
            d={`M ${-7 * s} ${mouthY} Q 0 ${mouthY + 6 * s} ${7 * s} ${mouthY}`}
            stroke="#4A3B2A"
            strokeWidth="2.2"
            strokeLinecap="round"
            fill="none"
          />
        )}
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
          <Egg spot={bodyColor(pet.type)} progress={stageProgress(pet)} />
        ) : (
          <Creature s={s} type={pet.type} sleeping={sleeping} />
        )}
        {/* zzz над спящим активным питомцем */}
        {sleeping && isLast && (
          <g
            className="ttg-zzz"
            fill="#6B7B8C"
            fontWeight="800"
            fontFamily="inherit"
          >
            <text x={0.55 * 64 * s} y={-54 * s * 0.6} fontSize={11 * s} opacity="0.9">z</text>
            <text x={0.55 * 64 * s + 9 * s} y={-54 * s * 0.6 - 10 * s} fontSize={14 * s} opacity="0.7">z</text>
            <text x={0.55 * 64 * s + 18 * s} y={-54 * s * 0.6 - 20 * s} fontSize={17 * s} opacity="0.5">Z</text>
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
