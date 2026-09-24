"use client";

// Порт lib/screens/feeding_game_screen.dart (v1.6.0): питомец СИДИТ
// на задних лапах и ЛОВИТ ЕДУ РТОМ; кит — лицом к экрану. Вся еда
// цветная (без прозрачных квадратов). Награда: 2 XP и 1 монетка за еду.

import { useEffect, useRef, useState } from "react";
import { useTTG } from "@/lib/ttg/store";
import {
  C,
  isAquatic,
  isPlant,
  petStage,
  speciesStyle,
} from "@/lib/ttg/types";
import type { Pet, PetType } from "@/lib/ttg/types";
import { bellyColor, bodyColor } from "@/lib/ttg/types";
import { BigButton, Coin } from "./widgets";
import { X } from "lucide-react";
import { toast } from "sonner";

const ROUND_SECONDS = 45;
const SPAWN_EVERY_MS = 850;

interface Food {
  id: number;
  kind: number;
  x: number; // 0..1
  spawnMs: number;
  speed: number; // высоты экрана в секунду
  flying?: boolean;
}

type Phase = "menu" | "playing" | "finished";

export function FeedingGame({ onClose }: { onClose: () => void }) {
  const pets = useTTG((s) => s.pets);
  const addXp = useTTG((s) => s.addXp);
  const addCoins = useTTG((s) => s.addCoins);
  const addQuestProgress = useTTG((s) => s.addQuestProgress);
  const coins = useTTG((s) => s.coins);

  const pet: Pet | null = pets.find((p) => petStage(p) < 3) ?? null;
  const aquatic = pet ? isAquatic(pet.type) : false;
  const plant = pet ? isPlant(pet.type) : false;

  const [phase, setPhase] = useState<Phase>("menu");
  const [score, setScore] = useState(0);
  const [best, setBest] = useState(0);
  const [foods, setFoods] = useState<Food[]>([]);
  const [left, setLeft] = useState(ROUND_SECONDS);
  const [mouthOpen, setMouthOpen] = useState(0);

  const startRef = useRef(0);
  const rafRef = useRef(0);
  const foodsRef = useRef<Food[]>([]);
  const scoreRef = useRef(0);
  const idRef = useRef(0);

  const start = () => {
    setPhase("playing");
    setScore(0);
    scoreRef.current = 0;
    setFoods([]);
    foodsRef.current = [];
    setLeft(ROUND_SECONDS);
    startRef.current = performance.now();
    const loop = () => {
      const now = performance.now();
      const el = now - startRef.current;
      // Спавн еды (foodsRef — единый источник, setFoods — для рендера)
      const last = foodsRef.current.length
        ? foodsRef.current[foodsRef.current.length - 1].spawnMs
        : -SPAWN_EVERY_MS;
      if (el - last >= SPAWN_EVERY_MS) {
        foodsRef.current = [
          ...foodsRef.current,
          {
            id: ++idRef.current,
            kind: Math.floor(Math.random() * 5),
            x: 0.12 + Math.random() * 0.76,
            spawnMs: el,
            speed: 0.28 + Math.random() * 0.16,
          },
        ];
      }
      setFoods([...foodsRef.current]);
      // Таймер
      setLeft(Math.max(0, ROUND_SECONDS - Math.floor(el / 1000)));
      if (el >= ROUND_SECONDS * 1000) {
        finish();
        return;
      }
      rafRef.current = requestAnimationFrame(loop);
    };
    rafRef.current = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(rafRef.current);
  };

  const finish = () => {
    cancelAnimationFrame(rafRef.current);
    setPhase("finished");
    const s = scoreRef.current;
    setBest((b) => Math.max(b, s));
    if (pet && s > 0) {
      addXp(s * 2);
      addCoins(s);
    }
    addQuestProgress("feed_5", s);
  };

  useEffect(
    () => () => cancelAnimationFrame(rafRef.current),
    []
  );

  const catchFood = (f: Food) => {
    if (f.flying) return;
    foodsRef.current = foodsRef.current.map((x) =>
      x.id === f.id ? { ...x, flying: true } : x
    );
    setFoods([...foodsRef.current]);
    setMouthOpen(1);
    setTimeout(() => {
      foodsRef.current = foodsRef.current.filter((x) => x.id !== f.id);
      setFoods([...foodsRef.current]);
      scoreRef.current += 1;
      setScore(scoreRef.current);
    }, 200);
    setTimeout(() => setMouthOpen(0), 480);
  };

  const onTap = (e: React.MouseEvent<SVGSVGElement>) => {
    if (phase !== "playing") return;
    const rect = e.currentTarget.getBoundingClientRect();
    const px = ((e.clientX - rect.left) / rect.width) * 400;
    const py = ((e.clientY - rect.top) / rect.height) * 240;
    const el = performance.now() - startRef.current;
    for (const f of [...foodsRef.current].reverse()) {
      if (f.flying) continue;
      const t = (el - f.spawnMs) / 1000;
      const fx = f.x * 400;
      const fy = 240 * 0.12 + 240 * f.speed * t;
      if (Math.hypot(fx - px, fy - py) <= 26) {
        catchFood(f);
        return;
      }
    }
  };

  const el = phase === "playing" ? performance.now() - startRef.current : 0;

  return (
    <div className="absolute inset-0 z-40 flex flex-col" style={{ background: C.bg }}>
      {/* Шапка */}
      <div className="flex items-center justify-between border-b-2 bg-white px-4 py-3" style={{ borderColor: C.border }}>
        <span className="text-[16px] font-extrabold" style={{ color: C.ink }}>
          🍽️ Покорми питомца
        </span>
        <span className="text-[13px] font-bold" style={{ color: C.ink }}>
          <Coin size={16} /> {coins}
        </span>
        <button
          type="button"
          onClick={onClose}
          aria-label="Закрыть игру"
          className="rounded-full p-1.5"
          style={{ backgroundColor: C.greenSoft, color: C.greenDark }}
        >
          <X size={18} />
        </button>
      </div>

      {/* Сцена игры */}
      <div className="relative flex-1">
        <svg
          viewBox="0 0 400 240"
          preserveAspectRatio="xMidYMid slice"
          className="h-full w-full"
          onClick={onTap}
          role="img"
          aria-label="Мини-игра кормления"
        >
          <defs>
            <linearGradient id="fg-sky" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="#A6E4FF" />
              <stop offset="1" stopColor="#EAF9E0" />
            </linearGradient>
          </defs>
          <rect x="0" y="0" width="400" height="240" fill="url(#fg-sky)" />
          <rect x="0" y={240 * 0.8} width="400" height={240 * 0.2} fill="#90D26D" />
          {aquatic && <ellipse cx="200" cy="187" rx="172" ry="24" fill="#6EC1E4" />}

          {pet && phase !== "menu" && (
            <g transform="translate(200 0)">
              {aquatic ? (
                <WhaleFront mouthOpen={mouthOpen} type={pet.type} />
              ) : plant ? (
                <SittingPlant mouthOpen={mouthOpen} type={pet.type} />
              ) : (
                <SittingPet mouthOpen={mouthOpen} type={pet.type} />
              )}
            </g>
          )}

          {/* Еда — всегда цветная */}
          {phase === "playing" &&
            foods.map((f) => {
              const t = (el - f.spawnMs) / 1000;
              const cx = f.x * 400;
              const cy = f.flying ? lerpTo(f) : 240 * 0.12 + 240 * f.speed * t;
              return <FoodShape key={f.id} kind={f.kind} x={cx} y={cy} />;
            })}
        </svg>

        {/* Панели фаз */}
        {phase === "menu" && (
          <div className="absolute inset-x-0 bottom-0 space-y-2 bg-white/85 p-4 backdrop-blur-sm">
            <p className="text-center text-[13.5px]" style={{ color: C.inkSoft }}>
              {pet
                ? `${pet.name} сидит и ждёт угощение! Тапайте по еде — она полетит прямо в рот. 45 секунд.`
                : "Сначала выберите питомца на главном экране."}
            </p>
            <BigButton
              label="Начать кормление"
              fullWidth
              disabled={!pet}
              onClick={start}
            />
          </div>
        )}
        {phase === "finished" && (
          <div className="absolute inset-x-0 bottom-0 space-y-2 bg-white/90 p-4 backdrop-blur-sm">
            <p className="text-center text-[15px] font-extrabold" style={{ color: C.ink }}>
              Хрум-хрум! 🎉 Поймано еды: {score}
            </p>
            <p className="text-center text-[12.5px]" style={{ color: C.inkSoft }}>
              Награда: +{score * 2} XP · +{score} монеток (рекорд: {Math.max(best, score)})
            </p>
            <div className="flex gap-2">
              <BigButton label="Ещё раз" fullWidth onClick={start} />
              <BigButton
                label="Готово"
                color={C.blue}
                shadow={C.blueDark}
                fullWidth
                onClick={onClose}
              />
            </div>
          </div>
        )}
        {phase === "playing" && (
          <div className="absolute left-4 top-3 rounded-2xl bg-white/90 px-3 py-2 text-[13px] font-extrabold" style={{ color: C.ink }}>
            Поймано: {score} · {left} с
          </div>
        )}
      </div>
    </div>
  );

  function lerpTo(f: Food): number {
    // Полёт в рот — визуально сжимаем координату Y к точке рта.
    return 240 * 0.52;
  }
}

/** Открытый рот: тёмная пасть с язычком. */
function Mouth({ x, y, r, belly }: { x: number; y: number; r: number; belly: string }) {
  const rr = Math.max(6, Math.min(60, r));
  return (
    <g>
      <circle cx={x} cy={y} r={rr} fill="#7E3A47" />
      <circle cx={x} cy={y + rr * 0.35} r={rr * 0.55} fill="#E88A9A" />
      <circle cx={x} cy={y} r={rr * 1.06} fill="none" stroke={belly} strokeOpacity="0.7" strokeWidth="3" />
    </g>
  );
}

/** Питомец СИДИТ на задних лапах (v1.8.0). */
function SittingPet({ type, mouthOpen }: { type: PetType; mouthOpen: number }) {
  const st = speciesStyle(type);
  const body = bodyColor(type);
  const belly = bellyColor(type);
  const groundY = 240 * 0.8;
  const bodyW = 110;
  const bodyH = 118;
  const bodyCy = groundY - bodyH * 0.52;
  const headR = bodyW * 0.42;
  const headCy = bodyCy - bodyH * 0.62;

  return (
    <g>
      {/* Хвост за телом */}
      {(st.tail === "bushy" || st.tail === "thin" || st.tail === "curl") && (
        <ellipse
          cx={bodyW * 0.58}
          cy={bodyCy + bodyH * (st.tail === "bushy" ? 0.18 : 0.3)}
          rx={bodyW * (st.tail === "bushy" ? 0.25 : 0.11)}
          ry={bodyH * (st.tail === "bushy" ? 0.36 : 0.17)}
          fill={body}
        />
      )}

      {/* Бёдра и ступни — сидит на задних лапах */}
      <circle cx={-bodyW * 0.38} cy={bodyCy + bodyH * 0.32} r={bodyW * 0.24} fill={body} />
      <circle cx={bodyW * 0.38} cy={bodyCy + bodyH * 0.32} r={bodyW * 0.24} fill={body} />
      {[-0.34, 0.34].map((sx) => (
        <g key={sx}>
          <ellipse cx={sx * bodyW} cy={groundY - 6} rx={17} ry={9} fill={body} />
          {[-1, 0, 1].map((t) => (
            <circle key={t} cx={sx * bodyW + t * 8} cy={groundY - 4} r={2.6} fill={belly} />
          ))}
        </g>
      ))}

      {/* Тело и животик */}
      <ellipse cx={0} cy={bodyCy} rx={bodyW / 2} ry={bodyH / 2} fill={body} />
      <ellipse cx={0} cy={bodyCy + bodyH * 0.14} rx={bodyW * 0.28} ry={bodyH * 0.25} fill={belly} />

      {/* Передние лапки на животике */}
      {[-0.16, 0.16].map((sx) => (
        <ellipse key={sx} cx={sx * bodyW} cy={bodyCy + bodyH * 0.3} rx={11} ry={7} fill={body} />
      ))}

      {/* Уши */}
      {(st.ear === "triangle") &&
        [-1, 1].map((sx) => (
          <path
            key={sx}
            d={`M ${sx * headR * 0.75} ${headCy - headR * 0.35} L ${sx * headR * 0.5} ${headCy - headR * 1.25} L ${sx * headR * 0.15} ${headCy - headR * 0.7} Z`}
            fill={body}
          />
        ))}
      {(st.ear === "round" || st.ear === "pom") &&
        [-1, 1].map((sx) => (
          <circle key={sx} cx={sx * headR * 0.72} cy={headCy - headR * 0.7} r={headR * 0.34} fill={body} />
        ))}
      {st.ear === "long" &&
        [-1, 1].map((sx) => (
          <rect
            key={sx}
            x={sx * headR * 0.42 - headR * 0.2}
            y={headCy - headR * 2}
            width={headR * 0.4}
            height={headR * 1.5}
            rx={headR * 0.2}
            fill={body}
          />
        ))}
      {st.ear === "horns" &&
        [-1, 1].map((sx) => (
          <circle key={sx} cx={sx * headR * 0.4} cy={headCy - headR * 0.85} r={headR * 0.14} fill="#F6E7C1" />
        ))}
      {st.ear === "tuft" && <circle cx={0} cy={headCy - headR} r={headR * 0.18} fill={body} />}

      {/* Голова */}
      <circle cx={0} cy={headCy} r={headR} fill={body} />

      {/* Очки панды / маска енота */}
      {st.extra === "patches" &&
        [-0.42, 0.42].map((sx) => (
          <ellipse key={sx} cx={sx * headR} cy={headCy - headR * 0.05} rx={headR * 0.3} ry={headR * 0.34} fill={DARK} />
        ))}
      {st.extra === "mask" &&
        [-0.42, 0.42].map((sx) => (
          <ellipse key={sx} cx={sx * headR} cy={headCy - headR * 0.05} rx={headR * 0.34} ry={headR * 0.3} fill="#5A5F66" />
        ))}

      {/* Глаза */}
      {[-0.42, 0.42].map((sx) => (
        <g key={sx}>
          <circle cx={sx * headR} cy={headCy - headR * 0.05} r={headR * 0.2} fill="#FFFFFF" />
          <circle cx={sx * headR + 1} cy={headCy - headR * 0.05 + 1} r={headR * 0.1} fill="#33261A" />
        </g>
      ))}
      {/* Румянец */}
      {[-0.72, 0.72].map((sx) => (
        <circle key={sx} cx={sx * headR} cy={headCy + headR * 0.18} r={headR * 0.14} fill="#FF8FA3" opacity="0.55" />
      ))}

      {/* РОТ — открыт, ловит еду */}
      <Mouth x={0} y={headCy + headR * 0.45} r={headR * (0.3 + 0.5 * mouthOpen)} belly={belly} />
    </g>
  );
}

/** Кит и водные — ЛИЦОМ К ЭКРАНУ (v1.8.0). */
function WhaleFront({ type, mouthOpen }: { type: PetType; mouthOpen: number }) {
  const body = bodyColor(type);
  const belly = bellyColor(type);
  const cy = 240 * 0.56;
  const r = 58;

  return (
    <g>
      {/* Боковые плавники */}
      {[-1.05, 1.05].map((sx) => (
        <ellipse key={sx} cx={sx * r} cy={cy} rx={r * 0.25} ry={r * 0.45} fill={body} opacity="0.85" />
      ))}
      {/* Тело — камера смотрит киту в лицо */}
      <circle cx={0} cy={cy} r={r} fill={body} />
      <ellipse cx={0} cy={cy + r * 0.45} rx={r * 0.75} ry={r * 0.45} fill={belly} />
      {/* Глаза */}
      {[-0.45, 0.45].map((sx) => (
        <g key={sx}>
          <circle cx={sx * r} cy={cy - r * 0.3} r={r * 0.16} fill="#FFFFFF" />
          <circle cx={sx * r + 1} cy={cy - r * 0.3 + 1} r={r * 0.08} fill="#33261A" />
        </g>
      ))}
      {/* Фонтанчик */}
      <circle cx={0} cy={cy - r * 0.75} r={r * 0.08} fill="#3E6E8E" />
      {/* БОЛЬШОЙ РОТ */}
      <Mouth x={0} y={cy + r * 0.32} r={r * (0.34 + 0.42 * mouthOpen)} belly={belly} />
    </g>
  );
}

/** Растение «ловит» верхушкой (распахнутый бутон). */
function SittingPlant({ type, mouthOpen }: { type: PetType; mouthOpen: number }) {
  const body = bodyColor(type);
  const groundY = 240 * 0.8;
  const topY = groundY - 58;
  return (
    <g>
      <path d={`M -34 ${groundY - 52} L 34 ${groundY - 52} L 26 ${groundY - 4} L -26 ${groundY - 4} Z`} fill="#CB7B4E" />
      <rect x={-37} y={groundY - 58} width={74} height={10} fill="#A85F38" />
      <rect x={-3} y={topY - 44} width={6} height={44} fill="#5FA052" />
      <path d={`M 0 ${topY - 40} Q -36 ${topY - 48} -30 ${topY - 74} Q -8 ${topY - 56} 0 ${topY - 40} Z`} fill={body} />
      <path d={`M 0 ${topY - 40} Q 36 ${topY - 48} 30 ${topY - 74} Q 8 ${topY - 56} 0 ${topY - 40} Z`} fill={body} opacity="0.88" />
      <Mouth x={0} y={topY - 46} r={14 + 12 * mouthOpen} belly={body} />
    </g>
  );
}

/** Еда — всё рисуется явными цветами (фикс «прозрачного квадрата»). */
function FoodShape({ kind, x, y }: { kind: number; x: number; y: number }) {
  return (
    <g transform={`translate(${x} ${y}) rotate(${Math.sin((y / 240) * 6.3) * 9})`}>
      {kind === 0 && (
        <g>
          <circle cx={0} cy={2} r={15} fill="#E5484D" />
          <circle cx={-5} cy={-3} r={5} fill="#FF8A8E" />
          <rect x={-1.5} y={-22} width={3} height={8} fill="#8B5E34" />
          <ellipse cx={7} cy={-18} rx={6} ry={3} fill="#62C46A" />
        </g>
      )}
      {kind === 1 && (
        <g>
          <ellipse cx={-2} cy={0} rx={14} ry={7} fill="#5FA8D3" />
          <polygon points="11,0 21,-8 21,8" fill="#4A8FB8" />
          <circle cx={-10} cy={-3} r={2.2} fill="#FFFFFF" />
          <circle cx={-10} cy={-3} r={1.1} fill="#33261A" />
        </g>
      )}
      {kind === 2 && (
        <g>
          <polygon points="-9,-12 9,-12 0,16" fill="#FF8A3D" />
          {[-4, 0, 4].map((sx) => (
            <circle key={sx} cx={sx} cy={-15} r={3.4} fill="#62C46A" />
          ))}
        </g>
      )}
      {kind === 3 && (
        <g>
          <rect x={-11} y={-8} width={22} height={20} rx={6} fill="#E8A33D" />
          <rect x={-12} y={-13.5} width={24} height={7} rx={3} fill="#C97B4E" />
          <circle cx={0} cy={2} r={4.5} fill="#FFD98A" />
        </g>
      )}
      {kind === 4 && (
        <g>
          <circle cx={-5} cy={3} r={8} fill="#7C5CBF" />
          <circle cx={6} cy={4} r={7.2} fill="#8F6FD1" />
          <circle cx={1} cy={-6} r={7.6} fill="#6B4CAD" />
          <circle cx={4} cy={-12} r={2.4} fill="#62C46A" />
        </g>
      )}
    </g>
  );
}

const DARK = "#3A3A3A";
