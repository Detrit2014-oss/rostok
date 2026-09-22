"use client";

// Порт lib/widgets/pet_canvas.dart: небо, солнце, облака, лужайка
// и питомцы, нарисованные полностью процедурно (SVG) — ни одной картинки.

import { bellyColor, bodyColor, Pet, petStage } from "@/lib/ttg/types";
import type { PetType } from "@/lib/ttg/types";

const GROUND_Y = 182.4; // 0.76 * 240

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

function Egg({ s, spot }: { s: number; spot: string }) {
  const w = 34 * s;
  const h = 44 * s;
  return (
    <g>
      <ellipse cx={0} cy={-h / 2} rx={w / 2} ry={h / 2} fill="#FFF6E3" />
      <ellipse cx={0} cy={-h / 2} rx={(w / 2) - w * 0.12} ry={(h / 2) - w * 0.12} fill="#FFFBF0" />
      <circle cx={-w * 0.18} cy={-h * 0.55} r={3.5 * s} fill={spot} opacity="0.65" />
      <circle cx={w * 0.15} cy={-h * 0.35} r={2.6 * s} fill={spot} opacity="0.65" />
      <circle cx={-w * 0.05} cy={-h * 0.75} r={2.0 * s} fill={spot} opacity="0.65" />
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

      {/* Ушки */}
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

      {/* Тело и животик */}
      <ellipse cx={0} cy={bodyCy} rx={bw / 2} ry={bh / 2} fill={body} />
      <ellipse
        cx={0}
        cy={bodyCy + bh * 0.18}
        rx={bw * 0.31}
        ry={bh * 0.25}
        fill={belly}
      />

      {/* Румянец */}
      <g fill="#FF8FA3" opacity="0.55">
        <circle cx={-bw * 0.28} cy={bodyCy + bh * 0.05} r={4.5 * s} />
        <circle cx={bw * 0.28} cy={bodyCy + bh * 0.05} r={4.5 * s} />
      </g>

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

      {/* Клюв совёнка / улыбка остальных */}
      {type === "owl" ? (
        <path
          d={`M ${-4 * s} ${bodyCy + bh * 0.06} L ${4 * s} ${bodyCy + bh * 0.06} L 0 ${bodyCy + bh * 0.06 + 7 * s} Z`}
          fill="#FFB703"
        />
      ) : (
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
          <Egg s={s} spot={bodyColor(pet.type)} />
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
