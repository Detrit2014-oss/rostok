"use client";

// Порт lib/screens/pet_selection_screen.dart (v1.1.0): большой экран
// выбора питомца при первом запуске и после взросления предыдущего.
// 4 большие живые карточки — видно, кем именно вырастет яйцо.

import { useState } from "react";
import { useTTG } from "@/lib/ttg/store";
import { C, PET_CATALOG, STAGE_THRESHOLDS } from "@/lib/ttg/types";
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
  };
}

export function PetChoiceScreen() {
  const pets = useTTG((s) => s.pets);
  const choosePet = useTTG((s) => s.choosePet);
  const cancelPetChoice = useTTG((s) => s.cancelPetChoice);
  const [selected, setSelected] = useState<PetType | null>(null);

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
          Он вырастет, пока вы отдыхаете от телефона
        </p>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto py-3">
        <div className="mx-auto grid w-full max-w-[430px] grid-cols-2 gap-3.5 px-4">
          {PET_CATALOG.map((s) => {
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
