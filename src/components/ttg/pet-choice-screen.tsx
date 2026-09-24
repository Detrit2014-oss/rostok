"use client";

// Порт lib/screens/pet_selection_screen.dart (v1.5.0): большой экран
// выбора питомца при первом запуске и после взросления предыдущего.
// 30 живых карточек (24 зверя + 6 растений) с фильтрами + кубик.

import { useMemo, useState } from "react";
import { useTTG } from "@/lib/ttg/store";
import {
  C,
  PET_CATALOG,
  STAGE_THRESHOLDS,
  isAquatic,
  isPlant,
} from "@/lib/ttg/types";
import type { Pet, PetType } from "@/lib/ttg/types";
import { PetScene } from "./scene";
import { BigButton } from "./widgets";

/** Превью-питомец стадии «Малыш» — показывает, кем станет яйцо. */
function previewPet(type: PetType): Pet {
  const species = PET_CATALOG.find((s) => s.type === type) ?? PET_CATALOG[0];
  return {
    id: `preview-${type}`,
    name: species.name,
    type,
    bornAt: 0,
    growthMinutes: STAGE_THRESHOLDS[1],
    xp: 0,
    frame: "none",
  };
}

type FilterKind = "all" | "beast" | "water" | "plant";
const FILTERS: { id: FilterKind; label: string }[] = [
  { id: "all", label: "Все 30" },
  { id: "beast", label: "🦁 Звери" },
  { id: "water", label: "💧 Водные" },
  { id: "plant", label: "🪴 Растения" },
];

export function PetChoiceScreen() {
  const pets = useTTG((s) => s.pets);
  const choosePet = useTTG((s) => s.choosePet);
  const cancelPetChoice = useTTG((s) => s.cancelPetChoice);
  const [selected, setSelected] = useState<PetType | null>(null);
  const [filter, setFilter] = useState<FilterKind>("all");

  const visibleSpecies = useMemo(
    () =>
      PET_CATALOG.filter((s) => {
        if (filter === "all") return true;
        if (filter === "water") return isAquatic(s.type);
        if (filter === "plant") return isPlant(s.type);
        return !isAquatic(s.type) && !isPlant(s.type);
      }),
    [filter]
  );

  // Новый питомец вместо выросшего — можно отложить решение.
  const canDismiss = pets.length > 0;
  const selectedSpecies =
    PET_CATALOG.find((s) => s.type === selected) ?? null;

  return (
    <div
      className="flex h-full flex-col"
      style={{
        background: `linear-gradient(180deg, ${C.skyTop}, ${C.skyBottom})`,
      }}
    >
      <div className="px-5 pt-5 text-center">
        <p className="text-[24px] font-extrabold" style={{ color: C.ink }}>
          Выбери питомца! 🐣
        </p>
        <p
          className="mt-1 text-[13.5px] font-semibold"
          style={{ color: C.inkSoft }}
        >
          Он вырастет, пока вы отдыхаете от телефона. Всего видов:{" "}
          {PET_CATALOG.length}
        </p>
      </div>

      <div className="flex shrink-0 gap-2 overflow-x-auto px-4 pt-3">
        {FILTERS.map((f) => (
          <button
            key={f.id}
            type="button"
            onClick={() => setFilter(f.id)}
            className="whitespace-nowrap rounded-full px-3.5 py-1.5 text-[12.5px] font-extrabold transition-transform active:scale-95"
            style={{
              backgroundColor: filter === f.id ? C.green : "#FFFFFF",
              color: filter === f.id ? "#FFFFFF" : C.inkSoft,
              border: `2px solid ${filter === f.id ? C.greenDark : C.border}`,
            }}
          >
            {f.label}
          </button>
        ))}
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto py-3">
        <div className="mx-auto grid w-full max-w-[430px] grid-cols-2 gap-3.5 px-4">
          {visibleSpecies.map((s) => {
            const active = selected === s.type;
            return (
              <button
                key={s.type}
                type="button"
                onClick={() => setSelected(s.type)}
                aria-pressed={active}
                className="overflow-hidden rounded-[20px] bg-white text-left transition-transform active:scale-[0.98]"
                style={{
                  borderColor: active ? C.green : C.border,
                  borderStyle: "solid",
                  borderWidth: active ? 3 : 2,
                  boxShadow: active ? `0 3px 0 0 ${C.greenDark}` : "none",
                }}
              >
                <div className="relative h-[130px] w-full">
                  <PetScene pets={[previewPet(s.type)]} sleeping={false} />
                  {active && (
                    <span
                      className="absolute right-2 top-2 flex h-6 w-6 items-center justify-center rounded-full text-[13px] font-extrabold text-white"
                      style={{ backgroundColor: C.green }}
                    >
                      ✓
                    </span>
                  )}
                </div>
                <div className="px-2.5 pb-3 pt-1">
                  <p
                    className="text-[15.5px] font-extrabold"
                    style={{ color: C.ink }}
                  >
                    {s.emoji} {s.name}
                  </p>
                  <p
                    className="mt-0.5 text-[11px] leading-snug"
                    style={{ color: C.inkSoft }}
                  >
                    {s.desc}
                  </p>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      <div className="shrink-0 px-5 pb-[max(env(safe-area-inset-bottom),14px)] pt-1">
        <BigButton
          label={
            selectedSpecies
              ? `Встречаем «${selectedSpecies.accusative}»!`
              : "Выберите питомца"
          }
          fullWidth
          disabled={!selectedSpecies}
          onClick={() => selected && choosePet(selected)}
        />
        <button
          type="button"
          onClick={() => {
            const pick =
              PET_CATALOG[Math.floor(Math.random() * PET_CATALOG.length)];
            choosePet(pick.type);
          }}
          className="mt-2 w-full text-[13.5px] font-semibold"
          style={{ color: C.blue }}
        >
          🎲 Случайный питомец
        </button>
        {canDismiss && (
          <button
            type="button"
            onClick={cancelPetChoice}
            className="mt-2 w-full text-[13.5px] font-semibold"
            style={{ color: C.inkSoft }}
          >
            Позже
          </button>
        )}
      </div>
    </div>
  );
}
