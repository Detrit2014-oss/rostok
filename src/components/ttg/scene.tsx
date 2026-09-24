"use client";

// Порт lib/widgets/pet_canvas.dart (v1.8.0): небо, солнце, облака, лужайка,
// пруд для водных питомцев, погода (дождь/снег/туман/гроза) и 30 персонажей,
// нарисованных полностью процедурно (SVG) — ни одной картинки.

import type { CSSProperties } from "react";

import {
  bellyColor,
  bodyColor,
  isAquatic,
  isPlant,
  Pet,
  petStage,
  speciesStyle,
  stageProgress,
} from "@/lib/ttg/types";
import type { PetType } from "@/lib/ttg/types";

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

/** Настоящие лапы с пальцами (v1.8.0 — вместо «палок»). */
function Legs({ bw, legH, body, belly }: { bw: number; legH: number; body: string; belly: string }) {
  const legW = bw * 0.15;
  return (
    <g>
      {[-0.3, 0.3].map((sx) => (
        <g key={sx}>
          <rect
            x={sx * bw - legW / 2}
            y={-legH * 1.55}
            width={legW}
            height={legH * 1.55}
            rx={legW * 0.45}
            fill={body}
          />
          <ellipse
            cx={sx * bw}
            cy={-2}
            rx={legW * 0.95}
            ry={legW * 0.575}
            fill={body}
            opacity="0.82"
          />
          {[-1, 0, 1].map((t) => (
            <circle
              key={t}
              cx={sx * bw + t * legW * 0.5}
              cy={-2 + legW * 0.18}
              r={legW * 0.16}
              fill={belly}
            />
          ))}
        </g>
      ))}
    </g>
  );
}

function Tail({
  bw,
  bh,
  kind,
  body,
}: {
  bw: number;
  bh: number;
  kind: string;
  body: string;
}) {
  if (kind === "bushy") {
    return (
      <path
        d={`M ${bw * 0.44} ${-bh / 2 + bh * 0.22} Q ${bw * 0.95} ${-bh / 2 + bh * 0.05} ${bw * 0.78} ${-bh / 2 - bh * 0.5} Q ${bw * 0.62} ${-bh / 2 - bh * 0.05} ${bw * 0.44} ${-bh / 2 + bh * 0.22} Z`}
        fill={body}
      />
    );
  }
  if (kind === "thin") {
    return (
      <path
        d={`M ${bw * 0.46} ${-bh / 2 + bh * 0.2} Q ${bw * 0.78} ${-bh / 2 + bh * 0.28} ${bw * 0.72} ${-bh / 2 - bh * 0.12}`}
        stroke={body}
        strokeWidth={5 * (bw / 64)}
        strokeLinecap="round"
        fill="none"
      />
    );
  }
  if (kind === "curl") {
    return (
      <circle
        cx={bw * 0.55}
        cy={-bh / 2 + bh * 0.12}
        r={6.5 * (bw / 64)}
        stroke={body}
        strokeWidth={5.5 * (bw / 64)}
        fill="none"
      />
    );
  }
  if (kind === "puff") {
    return (
      <ellipse
        cx={bw * 0.55}
        cy={-bh / 2 + bh * 0.05}
        rx={bw * 0.13}
        ry={bh * 0.17}
        fill={body}
      />
    );
  }
  return null;
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

/** Зверь/птица/водный житель — собирается из таблицы видов. */
function Creature({
  s,
  type,
  sleeping,
}: {
  s: number;
  type: PetType;
  sleeping: boolean;
}) {
  const st = speciesStyle(type);
  const lying = sleeping; // v1.8.0: спим только ЛЁЖА.
  const bw = 64 * s;
  const bh = (lying ? 54 * 0.74 : 54) * s;
  const body = st.body;
  const belly = bellyColor(type);
  const bodyCy = -bh / 2 + (lying ? 2 : 0);
  const earY = bodyCy - bh * 0.42;
  const eyeY = st.muzzle === "topEyes" ? bodyCy - bh * 0.48 : bodyCy - bh * 0.05;
  const eyeDX = st.muzzle === "topEyes" ? bw * 0.2 : bw * 0.17;
  const mouthY = bodyCy + bh * 0.08;
  const ear = st.ear ?? "none";
  const tail = st.tail ?? "none";
  const muzzle = st.muzzle ?? "smile";
  const extra = st.extra ?? "none";

  return (
    <g transform={lying ? "scale(1 0.86)" : undefined}>
      {/* ── За телом: хвост и настоящие лапы ─────────────────────────── */}
      <Tail bw={bw} bh={bh} kind={tail} body={body} />
      {!lying && <Legs bw={bw} legH={bh * 0.3} body={body} belly={belly} />}

      {/* Крылья дракончика (подросток и взрослый) */}
      {extra === "wings" && s >= 0.55 + 2 * 0.22 && (
        <g fill={body} opacity="0.75">
          <path
            d={`M ${-bw * 0.3} ${bodyCy - bh * 0.1} Q ${-bw * 0.9} ${bodyCy - bh * 0.9} ${-bw * 0.2} ${bodyCy - bh * 0.55} Z`}
          />
          <path
            d={`M ${bw * 0.3} ${bodyCy - bh * 0.1} Q ${bw * 0.9} ${bodyCy - bh * 0.9} ${bw * 0.2} ${bodyCy - bh * 0.55} Z`}
          />
        </g>
      )}

      {/* Клешни крабика — за телом */}
      {extra === "claws" && (
        <g>
          {[-0.62, 0.62].map((sx) => (
            <g key={sx}>
              <circle cx={sx * bw} cy={bodyCy - bh * 0.1} r={8.5 * s} fill={body} />
              <path
                d={`M ${sx * bw - 8.5 * s} ${bodyCy - bh * 0.1} A ${8.5 * s} ${8.5 * s} 0 0 1 ${sx * bw + 8.5 * s} ${bodyCy - bh * 0.1} Z`}
                fill={belly}
                opacity={sx > 0 ? 1 : 0}
              />
              <circle cx={sx * bw} cy={bodyCy - bh * 0.1} r={4.2 * s} fill={belly} opacity="0.6" />
            </g>
          ))}
        </g>
      )}

      {/* Тело и животик */}
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

      {/* Колючки ёжика */}
      {extra === "spikes" && (
        <g fill={SPIKE}>
          {[-2.45, -2.0, -1.57, -1.14, -0.7].map((a) => {
            const tipX = bw * 0.5 * 1.42 * Math.cos(a);
            const tipY = bodyCy + bh * 0.5 * 1.42 * Math.sin(a);
            const b1X = bw * 0.5 * Math.cos(a + 0.16);
            const b1Y = bodyCy + bh * 0.5 * Math.sin(a + 0.16);
            const b2X = bw * 0.5 * Math.cos(a - 0.16);
            const b2Y = bodyCy + bh * 0.5 * Math.sin(a - 0.16);
            return <polygon key={a} points={`${b1X},${b1Y} ${tipX},${tipY} ${b2X},${b2Y}`} />;
          })}
        </g>
      )}

      {/* Радужная грива и рог единорога */}
      {extra === "mane" && (
        <g>
          {["#EF476F", "#FF9F45", "#FFD166", "#62C46A", "#1CB0F6"].map((c, i) => {
            const a = -2.2 + i * 0.28;
            return (
              <circle
                key={c}
                cx={-bw * 0.42 * Math.cos(a)}
                cy={bodyCy - bh * 0.5 - bh * 0.12 * Math.sin(a)}
                r={5.5 * s}
                fill={c}
              />
            );
          })}
          <path
            d={`M ${-4 * s} ${bodyCy - bh * 0.52} L ${4 * s} ${bodyCy - bh * 0.52} L 0 ${bodyCy - bh * 0.86} Z`}
            fill="#FFD166"
          />
        </g>
      )}

      {/* Пятнышки лисёнка */}
      {extra === "spots" && (
        <g fill="#FFFFFF" opacity="0.35">
          <circle cx={-bw * 0.26} cy={bodyCy - bh * 0.18} r={3.4 * s} />
          <circle cx={bw * 0.1} cy={bodyCy - bh * 0.26} r={2.6 * s} />
        </g>
      )}

      {/* ── Уши ─────────────────────────────────────────────────────── */}
      {(ear === "triangle") && (
        <g fill={body}>
          <path
            d={`M ${-bw * 0.32} ${earY + bh * 0.1} L ${-bw * 0.18} ${earY - bh * 0.22} L ${-bw * 0.05} ${earY + bh * 0.05} Z`}
          />
          <path
            d={`M ${bw * 0.32} ${earY + bh * 0.1} L ${bw * 0.18} ${earY - bh * 0.22} L ${bw * 0.05} ${earY + bh * 0.05} Z`}
          />
        </g>
      )}
      {ear === "long" &&
        [-0.16, 0.16].map((sx) => (
          <g key={sx}>
            <rect
              x={sx * bw - bw * 0.085}
              y={bodyCy - bh * 0.62 - bh * 0.31}
              width={bw * 0.17}
              height={bh * 0.62}
              rx={bw * 0.085}
              fill={body}
            />
            <rect
              x={sx * bw - bw * 0.04}
              y={bodyCy - bh * 0.56 - bh * 0.21}
              width={bw * 0.08}
              height={bh * 0.42}
              rx={bw * 0.04}
              fill="#F5B8C4"
            />
          </g>
        ))}
      {ear === "round" && (
        <g>
          <circle cx={-bw * 0.3} cy={earY - bh * 0.06} r={8 * s} fill={body} />
          <circle cx={bw * 0.3} cy={earY - bh * 0.06} r={8 * s} fill={body} />
          <circle cx={-bw * 0.3} cy={earY - bh * 0.06} r={4 * s} fill={belly} />
          <circle cx={bw * 0.3} cy={earY - bh * 0.06} r={4 * s} fill={belly} />
        </g>
      )}
      {ear === "pom" && (
        <g fill={body}>
          <circle cx={-bw * 0.27} cy={earY - bh * 0.06} r={7.5 * s} />
          <circle cx={bw * 0.27} cy={earY - bh * 0.06} r={7.5 * s} />
        </g>
      )}
      {ear === "tuft" && (
        <g fill={body}>
          <circle cx={-bw * 0.22} cy={earY - bh * 0.02} r={6 * s} />
          <circle cx={bw * 0.22} cy={earY - bh * 0.02} r={6 * s} />
        </g>
      )}
      {ear === "horns" && (
        <g fill="#F6E7C1">
          <circle cx={-bw * 0.14} cy={earY - bh * 0.06} r={4 * s} />
          <circle cx={bw * 0.14} cy={earY - bh * 0.06} r={4 * s} />
        </g>
      )}
      {ear === "crest" && (
        <g fill={body}>
          <circle cx={-bw * 0.07} cy={bodyCy - bh * 0.52} r={2.6 * s} />
          <circle cx={0} cy={bodyCy - bh * 0.58} r={2.8 * s} />
          <circle cx={bw * 0.07} cy={bodyCy - bh * 0.52} r={2.6 * s} />
        </g>
      )}
      {/* Рожки оленёнка */}
      {type === "deer" && (
        <path
          d={`M ${-bw * 0.16} ${earY - bh * 0.16} L ${-bw * 0.24} ${earY - bh * 0.52} M ${-bw * 0.205} ${earY - bh * 0.36} L ${-bw * 0.27} ${earY - bh * 0.44} M ${bw * 0.16} ${earY - bh * 0.16} L ${bw * 0.24} ${earY - bh * 0.52} M ${bw * 0.205} ${earY - bh * 0.36} L ${bw * 0.27} ${earY - bh * 0.44}`}
          stroke={SPIKE}
          strokeWidth={3.6 * s}
          strokeLinecap="round"
          fill="none"
        />
      )}

      {/* Румянец */}
      <g fill="#FF8FA3" opacity="0.55">
        <circle cx={-bw * 0.28} cy={bodyCy + bh * 0.05} r={4.5 * s} />
        <circle cx={bw * 0.28} cy={bodyCy + bh * 0.05} r={4.5 * s} />
      </g>

      {/* Очки панды и маска енота — при открытых глазах */}
      {extra === "patches" && !lying && (
        <g fill={DARK}>
          <ellipse cx={-eyeDX} cy={eyeY} rx={bw * 0.15} ry={bh * 0.17} />
          <ellipse cx={eyeDX} cy={eyeY} rx={bw * 0.15} ry={bh * 0.17} />
        </g>
      )}
      {extra === "mask" && !lying && (
        <g fill="#5A5F66">
          <ellipse cx={-eyeDX} cy={eyeY} rx={bw * 0.17} ry={bh * 0.15} />
          <ellipse cx={eyeDX} cy={eyeY} rx={bw * 0.17} ry={bh * 0.15} />
        </g>
      )}

      {/* Глаза: спим ЛЁЖА с закрытыми глазами, иначе моргаем */}
      {lying ? (
        <g stroke="#4A3B2A" strokeWidth="2.4" strokeLinecap="round">
          <line x1={-eyeDX} y1={eyeY} x2={-eyeDX + 7 * s} y2={eyeY} />
          <line x1={eyeDX - 7 * s} y1={eyeY} x2={eyeDX} y2={eyeY} />
        </g>
      ) : (
        <g
          className="ttg-blink"
          style={{ transformBox: "fill-box", transformOrigin: "center" }}
        >
          <circle cx={-eyeDX} cy={eyeY} r={6.5 * s} fill="#FFFFFF" />
          <circle cx={eyeDX} cy={eyeY} r={6.5 * s} fill="#FFFFFF" />
          <circle cx={-eyeDX + 1.5} cy={eyeY + 1} r={3.2 * s} fill="#33261A" />
          <circle cx={eyeDX + 1.5} cy={eyeY + 1} r={3.2 * s} fill="#33261A" />
          <circle cx={-eyeDX + 2.5} cy={eyeY - 1.5} r={1.1 * s} fill="#FFFFFF" />
          <circle cx={eyeDX + 2.5} cy={eyeY - 1.5} r={1.1 * s} fill="#FFFFFF" />
        </g>
      )}

      {/* Клювы, мордочки, улыбки */}
      {muzzle === "beak" && (
        <path
          d={`M ${-4 * s} ${bodyCy + bh * 0.06} L ${4 * s} ${bodyCy + bh * 0.06} L 0 ${bodyCy + bh * 0.06 + 7 * s} Z`}
          fill="#FFB703"
        />
      )}
      {muzzle === "duckBeak" && (
        <rect
          x={-bw * 0.18}
          y={bodyCy + bh * 0.1 - bh * 0.08}
          width={bw * 0.36}
          height={bh * 0.16}
          rx={4 * s}
          fill={BEAK}
        />
      )}
      {muzzle === "bearMuzzle" && (
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
      {muzzle === "snout" && (
        <g>
          <ellipse cx={0} cy={bodyCy + bh * 0.14} rx={bw * 0.13} ry={bh * 0.1} fill="#E88AA0" />
          <circle cx={-3.2 * s} cy={bodyCy + bh * 0.14} r={1.7 * s} fill={DARK} />
          <circle cx={3.2 * s} cy={bodyCy + bh * 0.14} r={1.7 * s} fill={DARK} />
        </g>
      )}
      {muzzle === "buckteeth" && (
        <g>
          <path
            d={`M ${-7 * s} ${mouthY} Q 0 ${mouthY + 6 * s} ${7 * s} ${mouthY}`}
            stroke="#4A3B2A"
            strokeWidth="2.2"
            strokeLinecap="round"
            fill="none"
          />
          <rect x={-4 * s} y={bodyCy + bh * 0.13} width={3.4 * s} height={4.6 * s} rx={1.6} fill="#FFFFFF" />
          <rect x={0.8 * s} y={bodyCy + bh * 0.13} width={3.4 * s} height={4.6 * s} rx={1.6} fill="#FFFFFF" />
        </g>
      )}
      {muzzle === "whaleMouth" && (
        <path
          d={`M ${-bw * 0.25} ${bodyCy + bh * 0.05} Q 0 ${bodyCy + bh * 0.3} ${bw * 0.25} ${bodyCy + bh * 0.05}`}
          stroke="#3E6E8E"
          strokeWidth={3 * s}
          strokeLinecap="round"
          fill="none"
        />
      )}
      {muzzle === "topEyes" && (
        <g>
          <circle cx={-eyeDX} cy={eyeY - 2} r={3.6 * s} fill="#33261A" />
          <circle cx={eyeDX} cy={eyeY - 2} r={3.6 * s} fill="#33261A" />
          <path
            d={`M ${-bw * 0.2} ${bodyCy + bh * 0.12} Q 0 ${bodyCy + bh * 0.27} ${bw * 0.2} ${bodyCy + bh * 0.12}`}
            stroke="#4A3B2A"
            strokeWidth={2.4 * s}
            strokeLinecap="round"
            fill="none"
          />
        </g>
      )}
      {muzzle === "smile" && (
        <path
          d={`M ${-7 * s} ${mouthY} Q 0 ${mouthY + 6 * s} ${7 * s} ${mouthY}`}
          stroke="#4A3B2A"
          strokeWidth="2.2"
          strokeLinecap="round"
          fill="none"
        />
      )}

      {/* Усики тюленя */}
      {type === "seal" && (
        <g stroke="#7A8896" strokeWidth={1.6} strokeLinecap="round">
          {[-1, 1].map((sx) => (
            <g key={sx}>
              <line x1={sx * bw * 0.1} y1={bodyCy + bh * 0.1} x2={sx * bw * 0.3} y2={bodyCy + bh * 0.06} />
              <line x1={sx * bw * 0.1} y1={bodyCy + bh * 0.12} x2={sx * bw * 0.3} y2={bodyCy + bh * 0.14} />
            </g>
          ))}
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

  // Водные питомцы живут в пруду по центру; остальные — на лужайке.
  const x = pondActive && aquatic ? 200 : 400 * (total === 1 ? 0.5 : 0.18 + (0.64 * index) / Math.max(1, total - 1));
  const y = aquatic ? GROUND_Y + 24 : GROUND_Y;

  return (
    <g transform={`translate(${x} ${y})`}>
      <g
        className={aquatic ? "ttg-bob-sleep" : sleeping ? "ttg-bob-sleep" : "ttg-bob"}
        style={{ animationDelay: `${-index * 0.7}s` }}
      >
        {stage === 0 ? (
          <Egg spot={bodyColor(pet.type)} progress={stageProgress(pet)} />
        ) : isPlant(pet.type) ? (
          <Plant s={s} type={pet.type} sleeping={sleeping} />
        ) : (
          <Creature s={s} type={pet.type} sleeping={sleeping} />
        )}
        {sleeping && isLast && !isPlant(pet.type) && (
          <g className="ttg-zzz" fill="#6B7B8C" fontWeight="800" fontFamily="inherit">
            <text x={0.55 * 64 * s} y={-54 * s * 0.6} fontSize={11 * s} opacity="0.9">z</text>
            <text x={0.55 * 64 * s + 9 * s} y={-54 * s * 0.6 - 10 * s} fontSize={14 * s} opacity="0.7">z</text>
            <text x={0.55 * 64 * s + 18 * s} y={-54 * s * 0.6 - 20 * s} fontSize={17 * s} opacity="0.5">Z</text>
          </g>
        )}
      </g>
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
