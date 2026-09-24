"use client";

// Порт lib/screens/feeding_game_screen.dart (v2.1.0): настоящий зверь
// (реалистичный спрайт) стоит по центру, еда летит в ЯКОРЬ МОРДЫ,
// питомец довольно пружинит («жуёт»). Водные плавают в пруду, растения
// ловят бутоном. Вся еда цветная. Награда: 2 XP и 1 монетка за еду.

import { useEffect, useRef, useState } from "react";
import { useTTG } from "@/lib/ttg/store";
import {
  C,
  isAquatic,
  isPlant,
  petStage,
  anchorsFor,
  spriteAsset,
  spriteAspect,
  spriteStageScale,
} from "@/lib/ttg/types";
import type { Pet } from "@/lib/ttg/types";
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
  flyFrom?: { x: number; y: number };
  flyAt?: number;
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
            x: 0.40 + Math.random() * 0.20,
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

  const catchFood = (f: Food, from: { x: number; y: number }) => {
    if (f.flying) return;
    foodsRef.current = foodsRef.current.map((x) =>
      x.id === f.id ? { ...x, flying: true, flyFrom: from, flyAt: performance.now() } : x
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
    // preserveAspectRatio="slice": учитываем реальную видимую область.
    const scale = Math.max(rect.width / 400, rect.height / 240);
    const offX = (400 - rect.width / scale) / 2;
    const offY = (240 - rect.height / scale) / 2;
    const px = offX + (e.clientX - rect.left) / scale;
    const py = offY + (e.clientY - rect.top) / scale;
    const el = performance.now() - startRef.current;
    for (const f of [...foodsRef.current].reverse()) {
      if (f.flying) continue;
      const t = (el - f.spawnMs) / 1000;
      const fx = f.x * 400;
      const fy = 240 * 0.12 + 240 * f.speed * t;
      if (Math.hypot(fx - px, fy - py) <= 30) {
        catchFood(f, { x: fx, y: fy });
        return;
      }
    }
  };

  const el = phase === "playing" ? performance.now() - startRef.current : 0;

  // Прямоугольник спрайта питомца и точка рта (зеркало Flutter-версии).
  const stage = pet ? petStage(pet) : 3;
  const aspect = pet ? spriteAspect(pet.type) : 1.45;
  let boxH = 240 * 0.38 * spriteStageScale(stage);
  let boxW = boxH * aspect;
  if (boxW > 400 * 0.74) {
    boxW = 400 * 0.74;
    boxH = boxW / aspect;
  }
  const boxX = 200 - boxW / 2;
  const boxY = 240 * 0.82 - boxH;
  const mouthAnchors = pet ? anchorsFor(pet.type) : anchorsFor("fox");
  const mouthX = boxX + mouthAnchors.mouth[0] * boxW;
  const mouthY = boxY + mouthAnchors.mouth[1] * boxH;

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
          {aquatic && (
            <g>
              <ellipse cx="200" cy={240 * 0.8} rx="184" ry="27" fill="#E8D8A8" />
              <ellipse cx="200" cy={240 * 0.8} rx="172" ry="24" fill="#6EC1E4" />
            </g>
          )}

          {pet && stage > 0 && (
            <g>
              <ellipse
                cx={200}
                cy={240 * 0.82 + 2}
                rx={boxW * 0.3}
                ry={boxW * 0.045}
                fill="#2E7D32"
                opacity={aquatic ? 0 : 0.18}
              />
              {aquatic && (
                <ellipse cx={200} cy={240 * 0.8} rx="172" ry="24" fill="#6EC1E4" opacity="0.45" />
              )}
              <g
                className={mouthOpen > 0 ? "ttg-chew" : undefined}
                style={{ transformBox: "fill-box", transformOrigin: "50% 100%" }}
              >
                <image
                  href={spriteAsset(pet.type)}
                  x={boxX}
                  y={boxY}
                  width={boxW}
                  height={boxH}
                  preserveAspectRatio="none"
                />
              </g>
            </g>
          )}

          {/* Еда — всегда цветная; летит в якорь морды */}
          {phase === "playing" &&
            foods.map((f) => {
              const t = (el - f.spawnMs) / 1000;
              let cx = f.x * 400;
              let cy = 240 * 0.12 + 240 * f.speed * t;
              if (f.flying && f.flyFrom && f.flyAt) {
                const ft = Math.min(1, (performance.now() - f.flyAt) / 200);
                const ease = ft * ft * (3 - 2 * ft);
                cx = f.flyFrom.x + (mouthX - f.flyFrom.x) * ease;
                cy = f.flyFrom.y + (mouthY - f.flyFrom.y) * ease;
              }
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

}

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
