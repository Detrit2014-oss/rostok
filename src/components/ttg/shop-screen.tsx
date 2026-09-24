"use client";

// Порт lib/screens/shop_screen.dart (v1.9.0): монетки (рисованые),
// гардероб — одежда и окрасы-скины, рамки, заморозка серии 🧊.

import { useTTG } from "@/lib/ttg/store";
import { C, petStage, SLOT_TITLES, WARDROBE_CATALOG } from "@/lib/ttg/types";
import type { WardrobeItem } from "@/lib/ttg/types";
import { Coin, CoinText, InfoCard } from "./widgets";
import { X } from "lucide-react";
import { toast } from "sonner";

const FRAMES: { id: string; title: string; emoji: string; price: number; sub: string }[] = [
  { id: "none", title: "Без рамки", emoji: "✨", price: 0, sub: "Просто и мило" },
  { id: "gold", title: "Золотая", emoji: "🥇", price: 150, sub: "Блеск чемпионов" },
  { id: "neon", title: "Неоновая", emoji: "💠", price: 250, sub: "Свет в темноте" },
  { id: "flower", title: "Цветочная", emoji: "🌸", price: 200, sub: "Весна круглый год" },
];

const SLOTS: WardrobeItem["slot"][] = ["hat", "neck", "face", "skin"];

export function ShopScreen({ onClose }: { onClose: () => void }) {
  const coins = useTTG((s) => s.coins);
  const streakDays = useTTG((s) => s.streakDays);
  const freezes = useTTG((s) => s.freezes);
  const pets = useTTG((s) => s.pets);
  const wardrobe = useTTG((s) => s.wardrobe);
  const buyFrame = useTTG((s) => s.buyFrame);
  const buyFreeze = useTTG((s) => s.buyFreeze);
  const buyWardrobeItem = useTTG((s) => s.buyWardrobeItem);
  const equipItem = useTTG((s) => s.equipItem);
  const addQuestProgress = useTTG((s) => s.addQuestProgress);

  const active = pets.find((p) => petStage(p) < 3) ?? null;
  const FREEZE_PRICE = 200;

  const worn = (w: WardrobeItem): boolean => {
    if (!active) return false;
    switch (w.slot) {
      case "hat":
        return (active.hat ?? "none") === w.id;
      case "neck":
        return (active.neck ?? "none") === w.id;
      case "face":
        return (active.face ?? "none") === w.id;
      case "skin":
        return (active.skin ?? "classic") === w.id;
      default:
        return false;
    }
  };

  const handleWardrobe = (w: WardrobeItem) => {
    if (!active) return;
    if (wardrobe.includes(w.id)) {
      equipItem(w.slot, w.id);
      return;
    }
    const ok = buyWardrobeItem(w.id, w.price);
    if (ok) {
      equipItem(w.slot, w.id);
      addQuestProgress("shop_1", 1);
      toast(`${w.title} — новое в гардеробе!`);
    } else {
      toast("Не хватает монеток");
    }
  };

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
            <Coin size={40} />
            <div>
              <p className="text-[24px] font-extrabold leading-none text-white">{coins}</p>
              <p className="pt-1 text-[12px] font-semibold text-white/95">
                монеток · серия {streakDays} дн. · 🧊 ×{freezes}
              </p>
            </div>
          </div>
        </div>

        {/* Гардероб (v1.9.0) */}
        <p className="px-1 pt-1 text-[16px] font-extrabold" style={{ color: C.ink }}>
          Гардероб питомца
        </p>
        {!active ? (
          <InfoCard>
            <p className="text-[13px]" style={{ color: C.inkSoft }}>
              Сначала выберите питомца — тогда его можно будет нарядить.
            </p>
          </InfoCard>
        ) : (
          SLOTS.map((slot) => (
            <div key={slot} className="space-y-2">
              <p className="px-1 text-[12.5px] font-bold" style={{ color: C.inkSoft }}>
                {SLOT_TITLES[slot] ?? slot}
              </p>
              {WARDROBE_CATALOG.filter((w) => w.slot === slot).map((w) => {
                const owned = wardrobe.includes(w.id);
                const on = worn(w);
                return (
                  <InfoCard key={w.id}>
                    <div className="flex items-center gap-3">
                      <span className="text-[26px]">{w.emoji}</span>
                      <div className="flex-1">
                        <p className="text-[14.5px] font-extrabold" style={{ color: C.ink }}>
                          {w.title}
                        </p>
                        <p className="text-[12px]" style={{ color: C.inkSoft }}>
                          {w.subtitle}
                        </p>
                      </div>
                      {on ? (
                        <span
                          className="rounded-full px-3 py-1.5 text-[12px] font-extrabold"
                          style={{ backgroundColor: C.greenSoft, color: C.greenDark }}
                        >
                          Надето
                        </span>
                      ) : owned ? (
                        <button
                          type="button"
                          className="rounded-xl px-3.5 py-2 text-[13px] font-extrabold text-white transition-transform active:scale-95"
                          style={{ backgroundColor: C.blue }}
                          onClick={() => equipItem(w.slot, w.id)}
                        >
                          Надеть
                        </button>
                      ) : (
                        <button
                          type="button"
                          className="rounded-xl px-3.5 py-2 text-[13px] font-extrabold text-white transition-transform active:scale-95"
                          style={{ backgroundColor: C.green }}
                          onClick={() => handleWardrobe(w)}
                        >
                          <CoinText amount={w.price} textSize={13} color="#FFFFFF" />
                        </button>
                      )}
                    </div>
                  </InfoCard>
                );
              })}
            </div>
          ))
        )}

        {/* Рамки */}
        <p className="px-1 pt-2 text-[16px] font-extrabold" style={{ color: C.ink }}>
          Рамки для питомца
        </p>
        {!active
          ? null
          : FRAMES.map((f) => {
              const on = (active?.frame ?? "none") === f.id;
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
                    {on ? (
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
                          toast(ok ? `Рамка «${f.title}» надета!` : "Не хватает монеток");
                        }}
                      >
                        {f.price === 0 ? "Снять" : <CoinText amount={f.price} textSize={13} color="#FFFFFF" />}
                      </button>
                    )}
                  </div>
                </InfoCard>
              );
            })}

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
                      : "Не хватает монеток"
                );
              }}
            >
              <CoinText amount={FREEZE_PRICE} textSize={13} color="#FFFFFF" />
            </button>
          </div>
        </InfoCard>
      </div>
    </div>
  );
}
