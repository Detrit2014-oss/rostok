"use client";

// Порт lib/screens/feeding_game_screen.dart (v2.2.0): мультяшный зверь
// из cartoon.ts стоит по центру — дышит, моргает, жуёт. Еда летит прямо
// в ЯКОРЬ РТА движка. Водные плавают в пруду (кромка воды сверху),
// растения ловят макушкой. Вся еда цветная. Награда: 2 XP и 1 монетка.

import { useEffect, useRef, useState } from "react";
import { useTTG } from "@/lib/ttg/store";
import {
  C,
  cartoonMouthLocal,
  cartoonSpec,
  cartoonStageScale,
  isAquatic,
  isPlant,
  petStage,
} from "@/lib/ttg/types";
import type { Pet } from "@/lib/ttg/types";
import { paintCartoonPet } from "@/lib/ttg/cartoon";
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

  // ── Canvas сцены: питомец + еда + кромка воды ──
  const petCanvasRef = useRef<HTMLCanvasElement>(null);
  const petRef = useRef<Pet | null>(pet);
  const mouthOpenRef = useRef(0);

  useEffect(() => {
    petRef.current = pet;
    mouthOpenRef.current = mouthOpen;
  });

  useEffect(() => {
    const canvas = petCanvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const t0 = performance.now();
    let raf = 0;
    const loop = (now: number) => {
      const tSec = (now - t0) / 1000;
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      if (w > 0 && h > 0) {
        if (canvas.width !== Math.round(w * dpr) || canvas.height !== Math.round(h * dpr)) {
          canvas.width = Math.round(w * dpr);
          canvas.height = Math.round(h * dpr);
        }
        const s = Math.max(w / 400, h / 240); // slice-кроп, как у SVG
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        ctx.clearRect(0, 0, w, h);
        ctx.translate((w - 400 * s) / 2, (h - 240 * s) / 2);
        ctx.scale(s, s);

        const cur = petRef.current;
        const st = cur ? petStage(cur) : 3;
        const groundY = 240 * 0.82;
        if (cur && st > 0) {
          const spec = cartoonSpec(cur.type);
          let bh = 240 * 0.38 * cartoonStageScale(st);
          let bw = bh * spec.aspect;
          if (bw > 400 * 0.74) {
            bw = 400 * 0.74;
            bh = bw / spec.aspect;
          }
          const chewing = mouthOpenRef.current > 0;
          const chew = chewing ? 1 + 0.06 * Math.sin(tSec * Math.PI * 2 * 6) : 1;
          const bob = Math.sin((tSec * Math.PI * 2) / 2.2) * 2.5;
          // Тень.
          ctx.beginPath();
          ctx.ellipse(200, groundY + 2, (bw * 0.55 * chew) / 2, (bw * 0.09) / 2, 0, 0, Math.PI * 2);
          ctx.fillStyle = cur && isAquatic(cur.type) ? "rgba(0,0,0,0)" : "rgba(46,125,50,0.18)";
          ctx.fill();
          // Питомец.
          ctx.save();
          ctx.translate(200, groundY + bob);
          ctx.scale(chew, chew);
          paintCartoonPet(ctx, cur, bh, { tSec, kind: "idle", chewing });
          ctx.restore();
          // Кромка воды поверх водного питомца.
          if (isAquatic(cur.type)) {
            ctx.fillStyle = "rgba(110,193,228,0.45)";
            ctx.beginPath();
            ctx.ellipse(200, 240 * 0.8, 172, 24, 0, 0, Math.PI * 2);
            ctx.fill();
          }
        }

        // Еда (вся — на canvas, чтобы лежала поверх питомца).
        const el = now - startRef.current;
        const m = cur && st > 0 ? cartoonMouthLocal(cur.type, foodBoxH(cur, st)) : { x: 200, y: groundY - 40 };
        const mouthX = 200 + m.x;
        const mouthY = groundY + m.y;
        for (const f of foodsRef.current) {
          const t = (el - f.spawnMs) / 1000;
          let cx = f.x * 400;
          let cy = 240 * 0.12 + 240 * f.speed * t;
          if (f.flying && f.flyFrom && f.flyAt) {
            const ft = Math.min(1, (performance.now() - f.flyAt) / 200);
            const ease = ft * ft * (3 - 2 * ft);
            cx = f.flyFrom.x + (mouthX - f.flyFrom.x) * ease;
            cy = f.flyFrom.y + (mouthY - f.flyFrom.y) * ease;
          }
          drawFood(ctx, f.kind, cx, cy);
        }
      }
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, []);

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

  const onTap = (e: React.MouseEvent<HTMLDivElement>) => {
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

  // Прямоугольник питомца и точка рта (зеркало Flutter-версии).
  const stage = pet ? petStage(pet) : 3;
  const aspect = pet ? cartoonSpec(pet.type).aspect : 1.4;
  let boxH = 240 * 0.38 * cartoonStageScale(stage);
  let boxW = boxH * aspect;
  if (boxW > 400 * 0.74) {
    boxW = 400 * 0.74;
    boxH = boxW / aspect;
  }
  const mouth = pet
    ? cartoonMouthLocal(pet.type, boxH)
    : cartoonMouthLocal("fox", boxH);
  const mouthX = 200 + mouth.x;
  const mouthY = 240 * 0.82 + mouth.y;

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

      {/* Сцена игры: SVG-фон + canvas (питомец, вода, еда) */}
      <div
        className="relative flex-1"
        onClick={onTap}
        role="img"
        aria-label="Мини-игра кормления"
      >
        <svg
          viewBox="0 0 400 240"
          preserveAspectRatio="xMidYMid slice"
          className="h-full w-full"
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
        </svg>
        <canvas ref={petCanvasRef} className="pointer-events-none absolute inset-0 h-full w-full" />

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

function foodBoxH(pet: Pet, stage: number): number {
  const aspect = cartoonSpec(pet.type).aspect;
  let bh = 240 * 0.38 * cartoonStageScale(stage);
  const bw = bh * aspect;
  if (bw > 400 * 0.74) bh = 400 * 0.74 / aspect;
  return bh;
}

/** Еда на canvas (порт FoodShape): всегда цветная, слегка покачивается. */
function drawFood(cv: CanvasRenderingContext2D, kind: number, x: number, y: number) {
  cv.save();
  cv.translate(x, y);
  cv.rotate((Math.sin((y / 240) * 6.3) * 9 * Math.PI) / 180);
  if (kind === 0) {
    // Яблоко
    cv.fillStyle = "#E5484D";
    cv.beginPath(); cv.arc(0, 2, 15, 0, Math.PI * 2); cv.fill();
    cv.fillStyle = "#FF8A8E";
    cv.beginPath(); cv.arc(-5, -3, 5, 0, Math.PI * 2); cv.fill();
    cv.fillStyle = "#8B5E34";
    cv.fillRect(-1.5, -22, 3, 8);
    cv.fillStyle = "#62C46A";
    cv.beginPath(); cv.ellipse(7, -18, 6, 3, 0, 0, Math.PI * 2); cv.fill();
  } else if (kind === 1) {
    // Рыбка
    cv.fillStyle = "#5FA8D3";
    cv.beginPath(); cv.ellipse(-2, 0, 14, 7, 0, 0, Math.PI * 2); cv.fill();
    cv.fillStyle = "#4A8FB8";
    cv.beginPath(); cv.moveTo(11, 0); cv.lineTo(21, -8); cv.lineTo(21, 8); cv.closePath(); cv.fill();
    cv.fillStyle = "#FFFFFF";
    cv.beginPath(); cv.arc(-10, -3, 2.2, 0, Math.PI * 2); cv.fill();
    cv.fillStyle = "#33261A";
    cv.beginPath(); cv.arc(-10, -3, 1.1, 0, Math.PI * 2); cv.fill();
  } else if (kind === 2) {
    // Морковка
    cv.fillStyle = "#FF8A3D";
    cv.beginPath(); cv.moveTo(-9, -12); cv.lineTo(9, -12); cv.lineTo(0, 16); cv.closePath(); cv.fill();
    cv.fillStyle = "#62C46A";
    for (const sx of [-4, 0, 4]) {
      cv.beginPath(); cv.arc(sx, -15, 3.4, 0, Math.PI * 2); cv.fill();
    }
  } else if (kind === 3) {
    // Горшочек мёда
    cv.fillStyle = "#E8A33D";
    cv.beginPath(); cv.roundRect(-11, -8, 22, 20, 6); cv.fill();
    cv.fillStyle = "#C97B4E";
    cv.beginPath(); cv.roundRect(-12, -13.5, 24, 7, 3); cv.fill();
    cv.fillStyle = "#FFD98A";
    cv.beginPath(); cv.arc(0, 2, 4.5, 0, Math.PI * 2); cv.fill();
  } else {
    // Ягоды
    cv.fillStyle = "#7C5CBF";
    cv.beginPath(); cv.arc(-5, 3, 8, 0, Math.PI * 2); cv.fill();
    cv.fillStyle = "#8F6FD1";
    cv.beginPath(); cv.arc(6, 4, 7.2, 0, Math.PI * 2); cv.fill();
    cv.fillStyle = "#6B4CAD";
    cv.beginPath(); cv.arc(1, -6, 7.6, 0, Math.PI * 2); cv.fill();
    cv.fillStyle = "#62C46A";
    cv.beginPath(); cv.arc(4, -12, 2.4, 0, Math.PI * 2); cv.fill();
  }
  cv.restore();
}

const DARK = "#3A3A3A";
