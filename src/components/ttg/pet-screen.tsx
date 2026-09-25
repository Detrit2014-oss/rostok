"use client";

// Порт lib/screens/pet_screen.dart: сцена питомца, сессия детокса,
// прогресс стадии, список питомцев.

import { useTTG, activePet, countedSecondsSoFar } from "@/lib/ttg/store";
import {
  C,
  minutesToNextStage,
  petStage,
  stageEmoji,
  stageName,
  stageProgress,
} from "@/lib/ttg/types";
import { formatTimer } from "@/lib/ttg/format";
import { PetScene } from "./scene";
import { BigButton, Chip, InfoCard, ProgressBar } from "./widgets";
import { CheckCircle2, Clock, Flame, Pencil, PhoneOff } from "lucide-react";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { useState } from "react";

export function PetScreen() {
  const pets = useTTG((s) => s.pets);
  const todayMinutes = useTTG((s) => s.todayMinutes);
  const streakDays = useTTG((s) => s.streakDays);
  const sessionStartedAt = useTTG((s) => s.sessionStartedAt);
  const countedSec = useTTG((s) => s.countedSec);
  const awaySinceMs = useTTG((s) => s.awaySinceMs);
  const timeMachine = useTTG((s) => s.timeMachine);
  const startSession = useTTG((s) => s.startSession);
  const stopSession = useTTG((s) => s.stopSession);
  const openPetChoice = useTTG((s) => s.openPetChoice);
  const renamePet = useTTG((s) => s.renamePet);

  const [renameTarget, setRenameTarget] = useState<string | null>(null);
  const [renameValue, setRenameValue] = useState("");

  const running = sessionStartedAt !== null;
  const nowMs = useTTG((s) => s.nowMs);
  const active = activePet(pets);
  // Засчитанные секунды: только время вне вкладки (аналог погашенного
  // экрана). Машина времени ×60 — исключение: считает всё время.
  const sec = countedSecondsSoFar({
    sessionStartedAt,
    countedSec,
    awaySinceMs,
    timeMachine,
    nowMs,
  });

  return (
    <div className="flex h-full flex-col" style={{ background: `linear-gradient(180deg, ${C.skyTop}, ${C.skyBottom})` }}>
      {/* Чипы статистики */}
      <div className="flex gap-2 px-4 pt-2">
        <Chip icon={Clock} text={`Сегодня: ${todayMinutes} мин`} />
        <Chip icon={Flame} text={`Серия: ${streakDays}`} />
      </div>

      {/* Сцена */}
      <div className="min-h-[190px] shrink-0 px-3 pt-2" style={{ height: "34%" }}>
        <div className="h-full w-full overflow-hidden rounded-[18px] border-2 bg-white" style={{ borderColor: C.border }}>
          <PetScene pets={pets} sleeping={running} />
        </div>
      </div>

      {/* Управление */}
      <div className="flex-1 space-y-3 overflow-y-auto px-4 pb-4 pt-3">
        {running ? (
          <div
            className="w-full rounded-[20px] p-4 text-center"
            style={{ backgroundColor: C.green, boxShadow: `0 4px 0 0 ${C.greenDark}` }}
          >
            <p className="text-[14px] font-semibold text-white/90">
              Телефон отдыхает — питомец растёт
            </p>
            <p className="mt-1 text-[34px] font-extrabold tabular-nums text-white">
              {formatTimer(sec)}
            </p>
            {timeMachine ? (
              <p className="pb-1 pt-0.5 text-[12px] font-bold" style={{ color: C.yellow }}>
                Тестовый режим: 1 секунда = 1 минута
              </p>
            ) : awaySinceMs ? (
              <p className="pb-1 pt-0.5 text-[12.5px] font-bold text-white">
                🌱 Экран погашен — рост идёт
              </p>
            ) : (
              <p className="pb-1 pt-0.5 text-[12px] font-semibold text-white/90">
                ⏸ Счёт на паузе: вкладка активна. Скройте вкладку — питомец начнёт расти
              </p>
            )}
            <div className="pt-2">
              <BigButton
                label="Я вернулся"
                icon={CheckCircle2}
                color={C.yellow}
                shadow={C.yellowDark}
                textColor="#5B4300"
                fullWidth
                onClick={() => {
                  const { minutes, evolvedPetName } = stopSession();
                  if (minutes === 0 && !evolvedPetName) {
                    toast(
                      "Пока 0 мин — вкладка была активна всё время 🙈 В демо рост идёт, пока вкладка скрыта (или включите машину времени)"
                    );
                  } else {
                    toast(`Отлично! Питомцу начислено ${minutes} мин без телефона. 💚`);
                  }
                  if (evolvedPetName) {
                    setTimeout(() => {
                      toast.success(`Ура! 🎉 «${evolvedPetName}» вырос во взрослого питомца! Теперь можно выбрать нового — коллекция продолжается.`, {
                        duration: 7000,
                      });
                    }, 400);
                  }
                }}
              />
            </div>
          </div>
        ) : (
          <InfoCard>
            <div className="flex items-center gap-2">
              <span className="text-lg">🐾</span>
              <span className="flex-1 truncate text-[15px] font-extrabold" style={{ color: C.ink }}>
                {active ? `${active.name} — ${stageName(active.type, petStage(active))}` : "Ждём нового питомца"}
              </span>
              {active && (
                <>
                  <span className="shrink-0 text-[12px]" style={{ color: C.inkSoft }}>
                    до роста: {minutesToNextStage(active)} мин
                  </span>
                  <button
                    type="button"
                    aria-label="Переименовать питомца"
                    onClick={() => {
                      setRenameTarget(active.id);
                      setRenameValue(active.name);
                    }}
                    className="rounded-lg p-1"
                  >
                    <Pencil size={18} style={{ color: C.inkSoft }} />
                  </button>
                </>
              )}
            </div>
            <div className="mt-2.5">
              <ProgressBar value={active ? stageProgress(active) : 0} />
            </div>
            <div className="pt-3.5">
              <BigButton
                label={active ? `Отложить телефон: растим ${active.name}` : "Отложить телефон — растим питомца"}
                icon={PhoneOff}
                fullWidth
                onClick={() => startSession()}
              />
            </div>
            <p
              className="pt-2 text-center text-[11.5px] leading-snug"
              style={{ color: C.inkSoft }}
            >
              🌱 Рост идёт, пока вкладка скрыта (на телефоне — пока экран погашен)
            </p>
            {!active && (
              <button
                type="button"
                onClick={() => openPetChoice()}
                className="mt-2 w-full text-[14px] font-semibold"
                style={{ color: C.green }}
              >
                Выбрать нового питомца
              </button>
            )}
          </InfoCard>
        )}

        <InfoCard>
          <div className="flex items-center">
            <span className="flex-1 text-[15px] font-extrabold" style={{ color: C.ink }}>
              Мои питомцы
            </span>
            <span className="text-[12px]" style={{ color: C.inkSoft }}>
              Взрослых: {pets.filter((p) => petStage(p) >= 3).length}
            </span>
          </div>
          <div className="mt-2.5 flex flex-wrap gap-2">
            {pets.map((p) => {
              const adult = petStage(p) >= 3;
              return (
                <span
                  key={p.id}
                  className="rounded-full border-[1.5px] px-2.5 py-1.5 text-[12.5px] font-bold"
                  style={{
                    color: C.ink,
                    backgroundColor: adult ? C.greenSoft : "#FFF6E3",
                    borderColor: adult ? C.green : "#F0E0C0",
                  }}
                >
                  {stageEmoji(p.type, petStage(p))} {p.name} · {stageName(p.type, petStage(p))}
                </span>
              );
            })}
          </div>
        </InfoCard>
      </div>

      {/* Диалог переименования */}
      <Dialog open={renameTarget !== null} onOpenChange={(v) => !v && setRenameTarget(null)}>
        <DialogContent className="max-w-[320px] rounded-3xl" aria-describedby={undefined}>
          <DialogHeader>
            <DialogTitle className="text-center text-lg font-extrabold">Как зовут питомца?</DialogTitle>
          </DialogHeader>
          <input
            autoFocus
            maxLength={20}
            value={renameValue}
            onChange={(e) => setRenameValue(e.target.value)}
            placeholder="Имя питомца"
            className="w-full rounded-2xl border-2 px-4 py-3 text-[15px] outline-none"
            style={{ borderColor: C.border, color: C.ink }}
          />
          <div className="flex justify-end gap-4 pt-1">
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.inkSoft }}
              onClick={() => setRenameTarget(null)}
            >
              Отмена
            </button>
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.green }}
              onClick={() => {
                if (renameTarget) renamePet(renameTarget, renameValue);
                setRenameTarget(null);
              }}
            >
              Сохранить
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
