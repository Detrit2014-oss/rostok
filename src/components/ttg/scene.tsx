"use client";

// Порт lib/widgets/pet_canvas.dart (v1.9.0): небо, солнце, облака, лужайка,
// пруд для водных питомцев, погода (дождь/снег/туман/гроза) и 30 персонажей,
// нарисованных полностью процедурно (SVG) — ни одной картинки.
// v1.9.0: звери ходят по лужайке как настоящие (голова на шее, 4 лапы с
// походкой), растения всходят из семечка, гардероб рисуется на питомце.

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

// ── v1.9.0: реалистичные животные ──────────────────────────────────────
// Звери ходят по лужайке: голова на шее, тело на четырёх лапах с
// чередующейся походкой (SMIL), птицы семенят на двух, прыгуны скачут.
// Гардероб (шапки/шарфы/очки/окрасы) рисуется прямо на питомце.

const WALK_DUR = 0.72; // длительность шага, с
const PACE_DUR = 13; // цикл «туда-обратно» по лужайке, с

interface AnimalProps {
  s: number;
  type: PetType;
  sleeping: boolean;
  pet: Pet;
}

/** Ходьба по лужайке: треугольная волна + разворот в концах. */
function Pace({ children, delay }: { children: React.ReactNode; delay: number }) {
  return (
    <g>
      <animateTransform
        attributeName="transform"
        type="translate"
        values="-46 0; 46 0; -46 0"
        keyTimes="0;0.5;1"
        calcMode="linear"
        dur={`${PACE_DUR}s`}
        begin={`${-delay}s`}
        repeatCount="indefinite"
      />
      <g>
        <animateTransform
          attributeName="transform"
          type="scale"
          values="1 1;1 1;-1 1;-1 1;1 1"
          keyTimes="0;0.4999;0.5;0.9999;1"
          calcMode="linear"
          dur={`${PACE_DUR}s`}
          begin={`${-delay}s`}
          repeatCount="indefinite"
        />
        {children}
      </g>
    </g>
  );
}

/** Лапа с походкой (вращение вокруг бедра). */
function LegQ({
  hx, hy, len, w, color, phase, sleeping,
}: {
  hx: number; hy: number; len: number; w: number;
  color: string; phase: number; sleeping: boolean;
}) {
  return (
    <g transform={`translate(${hx} ${hy})`}>
      <g>
        {!sleeping && (
          <animateTransform
            attributeName="transform" type="rotate"
            values="-14;14;-14" keyTimes="0;0.5;1" calcMode="linear"
            dur={`${WALK_DUR}s`} begin={`${-phase}s`} repeatCount="indefinite"
          />
        )}
        <rect x={-w / 2} y={-2} width={w} height={len + 2} rx={w * 0.5} fill={color} />
        <ellipse cx={0} cy={len} rx={w * 0.78} ry={w * 0.48} fill={color} />
        {[-1, 0, 1].map((t) => (
          <circle key={t} cx={t * w * 0.42} cy={len + w * 0.12} r={w * 0.14} fill="#FFFFFF" opacity="0.3" />
        ))}
      </g>
    </g>
  );
}

/** Хвост четвероногого: пышный с белым кончиком, тонкий, колечком, помпон. */
function TailQ({
  ax, ay, bw, bh, kind, body, wag,
}: {
  ax: number; ay: number; bw: number; bh: number;
  kind: string; body: string; wag: boolean;
}) {
  let art: React.ReactNode = null;
  if (kind === "bushy") {
    art = (
      <g>
        <path
          d={`M 0 ${bh * 0.18} Q ${-bw * 0.42} ${bh * 0.1} ${-bw * 0.34} ${-bh * 0.42} Q ${-bw * 0.12} ${-bh * 0.12} 0 ${bh * 0.18} Z`}
          fill={body}
        />
        <path
          d={`M ${-bw * 0.315} ${-bh * 0.3} Q ${-bw * 0.36} ${-bh * 0.42} ${-bw * 0.34} ${-bh * 0.42} Q ${-bw * 0.2} ${-bh * 0.24} ${-bw * 0.16} ${-bh * 0.14} Q ${-bw * 0.26} ${-bh * 0.16} ${-bw * 0.315} ${-bh * 0.3} Z`}
          fill="#FFFFFF"
          opacity="0.85"
        />
      </g>
    );
  } else if (kind === "thin") {
    art = (
      <path
        d={`M 0 ${bh * 0.2} Q ${-bw * 0.3} ${bh * 0.26} ${-bw * 0.3} ${-bh * 0.2}`}
        stroke={body}
        strokeWidth={5 * (bw / 78)}
        strokeLinecap="round"
        fill="none"
      />
    );
  } else if (kind === "curl") {
    art = (
      <circle
        cx={-bw * 0.06}
        cy={0}
        r={6.5 * (bw / 78)}
        stroke={body}
        strokeWidth={5 * (bw / 78)}
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
            values="-9;9;-9" dur="0.5s" repeatCount="indefinite"
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

/** Морда: глаза, румянец, нос/клюв/зубки. */
function Face({
  hx, hy, hr, st, type, belly, s, sleeping,
}: {
  hx: number; hy: number; hr: number;
  st: SpeciesStyle; type: PetType; belly: string; s: number; sleeping: boolean;
}) {
  const muzzle = st.muzzle ?? "smile";
  const eyeDX = hr * 0.38;
  const eyeY = hy - hr * 0.06;
  const ink = "#4A3B2A";
  return (
    <g>
      {/* Глаза (мигают CSS-классом, когда не спим) */}
      {sleeping ? (
        <g stroke={ink} strokeWidth={2.3} strokeLinecap="round">
          <line x1={hx - eyeDX - hr * 0.2} y1={eyeY} x2={hx - eyeDX + hr * 0.2} y2={eyeY} />
          <line x1={hx + eyeDX - hr * 0.2} y1={eyeY} x2={hx + eyeDX + hr * 0.2} y2={eyeY} />
        </g>
      ) : (
        <g className="ttg-blink">
          {[-1, 1].map((d) => (
            <g key={d}>
              <circle cx={hx + d * eyeDX} cy={eyeY} r={hr * 0.3} fill="#FFFFFF" />
              <circle cx={hx + d * eyeDX + hr * 0.08} cy={eyeY + hr * 0.05} r={hr * 0.15} fill="#33261A" />
              <circle cx={hx + d * eyeDX + hr * 0.14} cy={eyeY - hr * 0.08} r={hr * 0.05} fill="#FFFFFF" />
            </g>
          ))}
        </g>
      )}
      {/* Румянец */}
      <g fill="#FF8FA3" opacity="0.5">
        <circle cx={hx - hr * 0.72} cy={hy + hr * 0.3} r={hr * 0.2} />
        <circle cx={hx + hr * 0.05} cy={hy + hr * 0.42} r={hr * 0.18} />
      </g>
      {/* Морда */}
      {muzzle === "beak" && (
        <polygon
          points={`${hx + hr * 0.35},${hy} ${hx + hr * 0.35},${hy + hr * 0.12} ${hx + hr * 0.95},${hy + hr * 0.06}`}
          fill={BEAK}
        />
      )}
      {muzzle === "duckBeak" && (
        <rect
          x={hx + hr * 0.14}
          y={hy - hr * 0.06}
          width={hr * 0.95}
          height={hr * 0.4}
          rx={4 * s}
          fill={BEAK}
        />
      )}
      {muzzle === "bearMuzzle" && (
        <g>
          <ellipse cx={hx + hr * 0.34} cy={hy + hr * 0.3} rx={hr * 0.48} ry={hr * 0.33} fill={belly} />
          <circle cx={hx + hr * 0.42} cy={hy + hr * 0.16} r={hr * 0.13} fill={DARK} />
          <path
            d={`M ${hx + hr * 0.17} ${hy + hr * 0.38} A ${hr * 0.25} ${hr * 0.2} 0 0 0 ${hx + hr * 0.67} ${hy + hr * 0.38}`}
            stroke={ink}
            strokeWidth={2.2}
            strokeLinecap="round"
            fill="none"
          />
        </g>
      )}
      {muzzle === "buckteeth" && (
        <g>
          <path
            d={`M ${hx + hr * 0.09} ${hy + hr * 0.22} A ${hr * 0.31} ${hr * 0.23} 0 0 0 ${hx + hr * 0.71} ${hy + hr * 0.22}`}
            stroke={ink}
            strokeWidth={2.2}
            strokeLinecap="round"
            fill="none"
          />
          <rect x={hx + hr * 0.26} y={hy + hr * 0.3} width={hr * 0.16} height={hr * 0.24} rx={1.6} fill="#FFFFFF" />
          <rect x={hx + hr * 0.46} y={hy + hr * 0.3} width={hr * 0.16} height={hr * 0.24} rx={1.6} fill="#FFFFFF" />
        </g>
      )}
      {muzzle === "snout" && (
        <g>
          <ellipse cx={hx + hr * 0.58} cy={hy + hr * 0.12} rx={hr * 0.3} ry={hr * 0.23} fill="#E88AA0" />
          <circle cx={hx + hr * 0.5} cy={hy + hr * 0.12} r={hr * 0.07} fill={DARK} />
          <circle cx={hx + hr * 0.68} cy={hy + hr * 0.12} r={hr * 0.07} fill={DARK} />
        </g>
      )}
      {muzzle === "smile" && (
        <g>
          <circle cx={hx + hr * 0.52} cy={hy + hr * 0.1} r={hr * 0.1} fill={DARK} />
          <path
            d={`M ${hx + hr * 0.14} ${hy + hr * 0.26} A ${hr * 0.28} ${hr * 0.2} 0 0 0 ${hx + hr * 0.7} ${hy + hr * 0.26}`}
            stroke={ink}
            strokeWidth={2.2}
            strokeLinecap="round"
            fill="none"
          />
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

// __QUADS_MARKER__

/** Зверь/птица/прыгун/водный житель — диспетчер по телосложению. */
function Animal(props: AnimalProps) {
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

/** Четвероногий ходок: тело, 4 лапы с походкой, шея, голова. */
function Quadruped({ s, type, st, body, belly, shade, sleeping, pet }: AnimalProps & { st: SpeciesStyle; body: string; belly: string; shade: string }) {
  const bw = 78 * s * (st.bodyLen ?? 1);
  const bh = 46 * s;
  const legH = 26 * s * (st.legLen ?? 1);
  const hr = 15.5 * s * (st.headScale ?? 1);
  const legW = 10.5 * s;
  const half = WALK_DUR / 2;

  if (sleeping) {
    // Лёжа: тело распластано, голова впереди на земле, глазки закрыты.
    const bodyCy = -bh * 0.36;
    const headX = bw * 0.5;
    const headY = -bh * 0.34;
    return (
      <g>
        <TailQ ax={-bw * 0.46} ay={bodyCy} bw={bw} bh={bh} kind={st.tail ?? "none"} body={body} wag={false} />
        <ellipse cx={0} cy={bodyCy} rx={bw / 2} ry={bh * 0.37} fill={body} />
        <ellipse cx={-bw * 0.02} cy={bodyCy + bh * 0.14} rx={bw * 0.275} ry={bh * 0.18} fill={belly} />
        <BackDetails bodyCy={bodyCy} bw={bw} bh={bh} st={st} body={body} s={s} stage={3} />
        <line x1={bw * 0.34} y1={bodyCy - bh * 0.12} x2={headX} y2={headY} stroke={body} strokeWidth={bh * 0.4} strokeLinecap="round" />
        <circle cx={headX} cy={headY} r={hr} fill={body} />
        <Ears hx={headX} hy={headY} hr={hr} st={st} body={body} belly={belly} s={s} />
        <HeadDetails hx={headX} hy={headY} hr={hr} st={st} s={s} />
        <Face hx={headX} hy={headY} hr={hr} st={st} type={type} belly={belly} s={s} sleeping />
        <Hat hx={headX} hy={headY} hr={hr} pet={pet} s={s} />
        <Glasses hx={headX} hy={headY} hr={hr} pet={pet} hidden />
      </g>
    );
  }

  const bodyCy = -legH - bh * 0.46;
  const headX = bw * 0.4;
  const headY = bodyCy - bh * (0.14 + (st.neck ?? 0.3));
  return (
    <g>
      {/* Дальняя пара лап (диагональ, темнее) */}
      <LegQ hx={-bw * 0.25} hy={-legH} len={legH} w={legW} color={shade} phase={half} sleeping={sleeping} />
      <LegQ hx={bw * 0.23} hy={-legH} len={legH} w={legW} color={shade} phase={0} sleeping={sleeping} />
      {/* Хвост (виляет) */}
      <TailQ ax={-bw * 0.46} ay={bodyCy} bw={bw} bh={bh} kind={st.tail ?? "none"} body={body} wag />
      {/* Ближняя пара лап */}
      <LegQ hx={-bw * 0.33} hy={-legH} len={legH} w={legW} color={body} phase={0} sleeping={sleeping} />
      <LegQ hx={bw * 0.31} hy={-legH} len={legH} w={legW} color={body} phase={half} sleeping={sleeping} />
      {/* Тело и животик */}
      <ellipse cx={0} cy={bodyCy} rx={bw / 2} ry={bh / 2} fill={body} />
      <ellipse cx={0} cy={bodyCy + bh * 0.2} rx={bw * 0.29} ry={bh * 0.24} fill={belly} />
      <BackDetails bodyCy={bodyCy} bw={bw} bh={bh} st={st} body={body} s={s} stage={Math.round((s - 0.55) / 0.22)} />
      {/* Грива единорога */}
      {st.extra === "mane" && <Mane bodyCy={bodyCy} headX={headX} headY={headY} s={s} />}
      {/* Шея */}
      {(st.neck ?? 0.3) > 0.16 && (
        <line
          x1={bw * 0.3} y1={bodyCy - bh * 0.16}
          x2={headX - hr * 0.1} y2={headY + hr * 0.5}
          stroke={body} strokeWidth={bh * 0.4} strokeLinecap="round"
        />
      )}
      {/* Голова */}
      <circle cx={headX} cy={headY} r={hr} fill={body} />
      <Ears hx={headX} hy={headY} hr={hr} st={st} body={body} belly={belly} s={s} />
      <HeadDetails hx={headX} hy={headY} hr={hr} st={st} s={s} />
      <Face hx={headX} hy={headY} hr={hr} st={st} type={type} belly={belly} s={s} sleeping={sleeping} />
      <Hat hx={headX} hy={headY} hr={hr} pet={pet} s={s} />
      <Neckwear nx={headX - hr * 0.2} ny={headY + hr * 0.95} hr={hr} pet={pet} />
      <Glasses hx={headX} hy={headY} hr={hr} pet={pet} hidden={false} />
    </g>
  );
}

/** Птица: две лапки, вертикальное тело, голова сверху, переваливается. */
function Bird({ s, type, st, body, belly, shade, sleeping, pet }: AnimalProps & { st: SpeciesStyle; body: string; belly: string; shade: string }) {
  const bw = 40 * s;
  const bh = 56 * s * (st.bodyLen ?? 1);
  const legH = 16 * s;
  const hr = 14.5 * s * (st.headScale ?? 1);
  const sit = sleeping ? legH * 0.35 : legH;
  const bodyCy = -sit - bh * 0.46;
  const headX = bw * 0.06;
  const headY = bodyCy - bh * 0.5 - hr * 0.62;

  return (
    <g>
      {!sleeping && (
        <animateTransform
          attributeName="transform" type="rotate"
          values="-3;3;-3" keyTimes="0;0.5;1" calcMode="linear"
          dur={`${WALK_DUR}s`} repeatCount="indefinite"
        />
      )}
      {/* Лапки-палочки */}
      {[-1, 1].map((d) => (
        <g key={d} transform={`translate(${d * bw * 0.14} ${-sit})`}>
          <g>
            {!sleeping && (
              <animateTransform
                attributeName="transform" type="rotate"
                values={`${d > 0 ? -12 : 12};${d > 0 ? 12 : -12};${d > 0 ? -12 : 12}`}
                keyTimes="0;0.5;1" calcMode="linear"
                dur={`${WALK_DUR}s`} begin={`${-WALK_DUR / 2}s`}
                repeatCount="indefinite"
              />
            )}
            <line x1={0} y1={0} x2={0} y2={sit} stroke={sleeping ? shade : "#E8A13D"} strokeWidth={4.2 * s} strokeLinecap="round" />
            <line x1={0} y1={sit} x2={5 * s} y2={sit + 1} stroke={sleeping ? shade : "#E8A13D"} strokeWidth={4.2 * s} strokeLinecap="round" />
          </g>
        </g>
      ))}
      {/* Хвост-веер */}
      <polygon
        points={`${-bw * 0.3},${bodyCy + bh * 0.3} ${-bw * 0.78},${bodyCy + bh * 0.44} ${-bw * 0.32},${bodyCy + bh * 0.52}`}
        fill={shade}
      />
      {/* Тело и животик */}
      <ellipse cx={0} cy={bodyCy} rx={bw / 2} ry={bh / 2} fill={body} />
      <ellipse cx={bw * 0.08} cy={bodyCy + bh * 0.16} rx={bw * 0.29} ry={bh * 0.25} fill={belly} />
      {/* Крылышко */}
      <ellipse cx={-bw * 0.12} cy={bodyCy - bh * 0.02} rx={bw * 0.21} ry={bh * 0.23} fill={shade} />
      {/* Голова */}
      <circle cx={headX} cy={headY} r={hr} fill={body} />
      <Ears hx={headX} hy={headY} hr={hr} st={st} body={body} belly={belly} s={s} />
      <HeadDetails hx={headX} hy={headY} hr={hr} st={st} s={s} />
      <Face hx={headX} hy={headY} hr={hr} st={st} type={type} belly={belly} s={s} sleeping={sleeping} />
      <Hat hx={headX} hy={headY} hr={hr} pet={pet} s={s} />
      <Neckwear nx={bw * 0.04} ny={bodyCy - bh * 0.42} hr={hr} pet={pet} />
      <Glasses hx={headX} hy={headY} hr={hr} pet={pet} hidden={sleeping} />
    </g>
  );
}

/** Прыгун: зайчик и лягушонок. */
function Hopper({ s, type, st, body, belly, shade, sleeping, pet }: AnimalProps & { st: SpeciesStyle; body: string; belly: string; shade: string }) {
  const bw = 58 * s * (st.bodyLen ?? 1);
  const bh = 46 * s;
  const bodyCy = -bh * 0.5 - 4 * s;

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
      {/* Задние лапки-пружинки */}
      <ellipse cx={-bw * 0.24} cy={-6 * s} rx={bw * 0.17} ry={bh * 0.12} fill={shade} />
      <ellipse cx={-bw * 0.3} cy={-bh * 0.2} rx={bw * 0.21} ry={bh * 0.15} fill={shade} />
      {/* Передние лапки */}
      <ellipse cx={bw * 0.34} cy={-3 * s} rx={bw * 0.08} ry={bh * 0.07} fill={body} />
      {/* Хвост-помпон зайчика */}
      {type === "bunny" && (
        <circle cx={-bw * 0.5} cy={bodyCy + bh * 0.1} r={bw * 0.1} fill="#FFFFFF" opacity="0.85" />
      )}
      {/* Тело и животик */}
      <ellipse cx={0} cy={bodyCy} rx={bw / 2} ry={bh / 2} fill={body} />
      <ellipse cx={bw * 0.06} cy={bodyCy + bh * 0.18} rx={bw * 0.26} ry={bh * 0.22} fill={belly} />

      {(st.muzzle ?? "smile") === "topEyes" ? (
        <g>
          {/* Лягушонок: глаза-фонарики на макушке */}
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
      ) : (
        (() => {
          // Зайчик: голова спереди-сверху
          const hr = bh * 0.42;
          const headX = bw * 0.4;
          const headY = bodyCy - bh * 0.38;
          return (
            <g>
              <circle cx={headX} cy={headY} r={hr} fill={body} />
              <Ears hx={headX} hy={headY} hr={hr} st={st} body={body} belly={belly} s={s} />
              <HeadDetails hx={headX} hy={headY} hr={hr} st={st} s={s} />
              <Face hx={headX} hy={headY} hr={hr} st={st} type={type} belly={belly} s={s} sleeping={sleeping} />
              <Hat hx={headX} hy={headY} hr={hr} pet={pet} s={s} />
              <Neckwear nx={bw * 0.34} ny={bodyCy - bh * 0.1} hr={hr} pet={pet} />
              <Glasses hx={headX} hy={headY} hr={hr} pet={pet} hidden={sleeping} />
            </g>
          );
        })()
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

  // Водные питомцы живут в пруду по центру; остальные — на лужайке.
  const x = pondActive && aquatic ? 200 : 400 * (total === 1 ? 0.5 : 0.18 + (0.64 * index) / Math.max(1, total - 1));
  const y = aquatic ? GROUND_Y + 24 : GROUND_Y;
  const walkable = stage > 0 && !plant && !aquatic;

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
      <Animal s={s} type={pet.type} sleeping={sleeping} pet={pet} />
    );

  return (
    <g transform={`translate(${x} ${y})`}>
      {aquatic ? (
        <g className="ttg-bob-sleep" style={{ animationDelay: `${-index * 0.7}s` }}>
          {art}
        </g>
      ) : walkable && !sleeping ? (
        /* v1.9.0: звери гуляют по лужайке (тень едет вместе с питомцем). */
        <Pace delay={index * 3.1 + 1.4}>
          <ellipse cx={0} cy={3} rx={38 * s} ry={5.5 * s} fill="#000000" opacity="0.08" />
          {art}
        </Pace>
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
