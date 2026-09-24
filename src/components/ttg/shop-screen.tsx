"use client";

// Порт lib/screens/shop_screen.dart (v1.5.0): монетки, рамки,
// заморозка серии 🧊 (v1.7.0).

import { useTTG } from "@/lib/ttg/store";
import { C, petStage } from "@/lib/ttg/types";
import { InfoCard } from "./widgets";
import { X } from "lucide-react";
import { toast } from "sonner";

const FRAMES: { id: string; title: string; emoji: string; price: number; sub: string }[] = [
  { id: "none", title: "Без рамки", emoji: "✨", price: 0, sub: "Просто и мило" },
  { id: "gold", title: "Золотая", emoji: "🥇", price: 150, sub: "Блеск чемпионов" },
  { id: "neon", title: "Неоновая", emoji: "💠", price: 250, sub: "Свет в темноте" },
  { id: "flower", title: "Цветочная", emoji: "🌸", price: 200, sub: "Весна круглый год" },
];

export function ShopScreen({ onClose }: { onClose: () => void }) {
  const coins = useTTG((s) => s.coins);
  const streakDays = useTTG((s) => s.streakDays);
  const freezes = useTTG((s) => s.freezes);
  const pets = useTTG((s) => s.pets);
  const buyFrame = useTTG((s) => s.buyFrame);
  const buyFreeze = useTTG((s) => s.buyFreeze);
  const addQuestProgress = useTTG((s) => s.addQuestProgress);

  const active = pets.find((p) => petStage(p) < 3) ?? null;
  const FREEZE_PRICE = 200;

  return (
    <div
      className="absolute inset-0 z-40 flex flex-col overflow-y-auto"
      style={{ background: C.bg }}
    >
      {/* Шапка */}
      <div className="sticky top-0 z-10 flex items-center justify-between border-b-2 bg-white px-4 py-3" style={{ borderColor: C.border }}>
        <span className="text-[17px] font-extrabold" style={{ color: C.ink }}>
          🛍️ Магазин
        </span>
        <button
          type="button"
          onClick={onClose}
          aria-label="Закрыть магазин"
          className="rounded-full p-1.5"
          style={{ backgroundColor: C.greenSoft, color: C.greenDark }}
        >
          <X size={18} />
        </button>
      </div>

      <div className="space-y-3 px-4 pb-6 pt-4">
        {/* Кошелёк */}
        <div
          className="rounded-[20px] p-4"
          style={{ backgroundColor: C.yellow, boxShadow: `0 4px 0 0 ${C.yellowDark}` }}
        >
          <div className="flex items-center gap-3">
            <span className="text-[32px]">🪙</span>
            <div>
              <p className="text-[24px] font-extrabold leading-none text-white">{coins}</p>
              <p className="pt-1 text-[12px] font-semibold text-white/95">
                монеток · серия {streakDays} дн. · 🧊 ×{freezes}
              </p>
            </div>
          </div>
        </div>

        {/* Рамки */}
        <p className="px-1 pt-1 text-[16px] font-extrabold" style={{ color: C.ink }}>
          Рамки для питомца
        </p>
        {!active ? (
          <InfoCard>
            <p className="text-[13px]" style={{ color: C.inkSoft }}>
              Сначала выберите питомца — тогда его можно будет нарядить.
            </p>
          </InfoCard>
        ) : (
          FRAMES.map((f) => {
            const worn = (active?.frame ?? "none") === f.id;
            return (
              <InfoCard key={f.id}>
                <div className="flex items-center gap-3">
                  <span className="text-[26px]">{f.emoji}</span>
                  <div className="flex-1">
                    <p className="text-[14.5px] font-extrabold" style={{ color: C.ink }}>
                      {f.title}
                    </p>
                    <p className="text-[12px]" style={{ color: C.inkSoft }}>
                      {f.sub}
                    </p>
                  </div>
                  {worn ? (
                    <span
                      className="rounded-full px-3 py-1.5 text-[12px] font-extrabold"
                      style={{ backgroundColor: C.greenSoft, color: C.greenDark }}
                    >
                      Надета
                    </span>
                  ) : (
                    <button
                      type="button"
                      className="rounded-xl px-3.5 py-2 text-[13px] font-extrabold text-white transition-transform active:scale-95"
                      style={{ backgroundColor: f.price === 0 ? C.inkSoft : C.green }}
                      onClick={() => {
                        const ok = buyFrame(f.id, f.price);
                        if (ok) addQuestProgress("shop_1", 1);
                        toast(ok ? `Рамка «${f.title}» надета!` : "Не хватает монеток 🪙");
                      }}
                    >
                      {f.price === 0 ? "Снять" : `${f.price} 🪙`}
                    </button>
                  )}
                </div>
              </InfoCard>
            );
          })
        )}

        {/* Заморозка */}
        <p className="px-1 pt-2 text-[16px] font-extrabold" style={{ color: C.ink }}>
          Защита серии
        </p>
        <InfoCard>
          <div className="flex items-center gap-3">
            <span className="text-[26px]">🧊</span>
            <div className="flex-1">
              <p className="text-[14.5px] font-extrabold" style={{ color: C.ink }}>
                Заморозка серии
              </p>
              <p className="text-[12px]" style={{ color: C.inkSoft }}>
                Пропустили день? 🧊 сохранит streak. В запасе: {freezes}/2
              </p>
            </div>
            <button
              type="button"
              disabled={freezes >= 2}
              className="rounded-xl px-3.5 py-2 text-[13px] font-extrabold text-white transition-transform active:scale-95 disabled:opacity-50"
              style={{ backgroundColor: C.blue }}
              onClick={() => {
                const ok = buyFreeze();
                if (ok) addQuestProgress("shop_1", 1);
                toast(
                  ok
                    ? "Заморозка 🧊 куплена! Серия спасена от пропуска."
                    : freezes >= 2
                      ? "В запасе уже 2 заморозки"
                      : "Не хватает монеток 🪙"
                );
              }}
            >
              {FREEZE_PRICE} 🪙
            </button>
          </div>
        </InfoCard>
      </div>
    </div>
  );
}
