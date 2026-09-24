"use client";

// Порт lib/screens/pet_screen.dart: сцена питомца, сессия детокса,
// прогресс стадии, список питомцев.

import { useTTG, activePet, countedSecondsSoFar } from "@/lib/ttg/store";
import {
  C,
  STAGE_NAMES,
  minutesToNextStage,
  petLevelFromXp,
  petLevelProgress,
  petStage,
  stageProgress,
} from "@/lib/ttg/types";
import { dailyQuests, seasonOf, XP_PER_TUCK_IN } from "@/lib/ttg/quests";
import { useWeather } from "@/lib/ttg/use-weather";
import { formatTimer } from "@/lib/ttg/format";
import { PetScene } from "./scene";
import { BigButton, Chip, InfoCard, ProgressBar } from "./widgets";
import { ShopScreen } from "./shop-screen";
import { FeedingGame } from "./feeding-game";
import { CheckCircle2, Clock, Coins, Flame, Pencil, PhoneOff, Utensils, Snowflake, Store } from "lucide-react";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { useState } from "react";

function stageEmoji(stage: number): string {
  switch (stage) {
    case 3:
      return "🐾";
    case 2:
      return "🐣";
    case 1:
      return "🐥";
    default:
      return "🥚";
  }
}

export function PetScreen() {
  const pets = useTTG((s) => s.pets);
  const todayMinutes = useTTG((s) => s.todayMinutes);
  const streakDays = useTTG((s) => s.streakDays);
  const coins = useTTG((s) => s.coins);
  const freezes = useTTG((s) => s.freezes);
  const sessionStartedAt = useTTG((s) => s.sessionStartedAt);
  const countedSec = useTTG((s) => s.countedSec);
  const awaySinceMs = useTTG((s) => s.awaySinceMs);
  const timeMachine = useTTG((s) => s.timeMachine);
  const buyFrame = useTTG((s) => s.buyFrame);
  const addQuestProgress = useTTG((s) => s.addQuestProgress);
  const claimQuest = useTTG((s) => s.claimQuest);
  const tuckIn = useTTG((s) => s.tuckIn);
  const questProgress = useTTG((s) => s.questProgress);
  const questClaimed = useTTG((s) => s.questClaimed);
  const questDay = useTTG((s) => s.questDay);
  const tuckInDay = useTTG((s) => s.tuckInDay);
  const weatherCondition = useTTG((s) => s.weatherCondition);
  const startSession = useTTG((s) => s.startSession);
  const stopSession = useTTG((s) => s.stopSession);
  const openPetChoice = useTTG((s) => s.openPetChoice);
  const renamePet = useTTG((s) => s.renamePet);

  // Погода (v1.7.0): GPS → Open-Meteo, иначе погода по дате.
  useWeather();

  const today = new Date();
  const dayK = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
  const quests = dailyQuests(questDay || dayK);
  const season = seasonOf(new Date());

  const [renameTarget, setRenameTarget] = useState<string | null>(null);
  const [renameValue, setRenameValue] = useState("");
  const [shopOpen, setShopOpen] = useState(false);
  const [gameOpen, setGameOpen] = useState(false);

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
    <div
      className="relative flex h-full flex-col"
      style={{ background: `linear-gradient(180deg, ${C.skyTop}, ${C.skyBottom})` }}
    >
      {shopOpen && <ShopScreen onClose={() => setShopOpen(false)} />}
      {gameOpen && <FeedingGame onClose={() => setGameOpen(false)} />}
      {/* Чипы статистики */}
      <div className="flex flex-wrap gap-2 px-4 pt-2">
        <Chip icon={Clock} text={`Сегодня: ${todayMinutes} мин`} />
        <Chip icon={Flame} text={`Серия: ${streakDays}`} />
        <Chip icon={Coins} text={`🪙 ${coins}`} />
        {freezes > 0 && <Chip icon={Snowflake} text={`🧊 ×${freezes}`} />}
        <button
          type="button"
          aria-label="Открыть магазин"
          onClick={() => setShopOpen(true)}
          className="ml-auto flex items-center gap-1.5 rounded-full border-[1.5px] bg-white/90 px-3 py-1.5 text-[12.5px] font-bold transition-transform active:scale-95"
          style={{ borderColor: C.border, color: C.ink }}
        >
          <Store size={15} style={{ color: C.greenDark }} />
          Магазин
        </button>
      </div>

      {/* Сцена */}
      <div className="min-h-[190px] shrink-0 px-3 pt-2" style={{ height: "34%" }}>
        <div className="h-full w-full overflow-hidden rounded-[18px] border-2 bg-white" style={{ borderColor: C.border }}>
          <PetScene
            pets={pets}
            sleeping={running}
            weather={weatherCondition === "clear" ? null : weatherCondition}
            frame={active?.frame ?? "none"}
          />
        </div>
      </div>

      {/* Управление */}
      <div className="flex-1 space-y-3 overflow-y-auto px-4 pb-4 pt-3">
        {active && (
          <InfoCard>
            <div className="flex items-center">
              <span className="text-[13.5px] font-extrabold" style={{ color: C.ink }}>
                {active.name} · Ур. {petLevelFromXp(active.xp ?? 0)}
              </span>
              <span className="ml-auto text-[12px] font-bold" style={{ color: C.inkSoft }}>
                {active.xp ?? 0} XP
              </span>
            </div>
            <div className="mt-1.5">
              <ProgressBar value={petLevelProgress(active.xp ?? 0)} />
            </div>
          </InfoCard>
        )}
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
                {active ? `${active.name} — ${STAGE_NAMES[petStage(active)]}` : "Ждём новое яйцо"}
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
            {active && (
              <button
                type="button"
                onClick={() => setGameOpen(true)}
                className="mt-2 flex w-full items-center justify-center gap-2 rounded-[16px] border-2 py-3 text-[14px] font-extrabold transition-transform active:scale-[0.98]"
                style={{ borderColor: C.orange, color: C.orange, backgroundColor: "#FFF4E8" }}
              >
                <Utensils size={18} />
                Покормить питомца (мини-игра)
              </button>
            )}
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
          {/* Сезонное событие (v1.7.0) */}
          <div
            className="rounded-2xl px-3.5 py-2.5 text-[12.5px]"
            style={{ backgroundColor: "#FFF3D6", border: "2px solid #FFD98A", color: C.ink }}
          >
            {season.emoji} {season.title}: {season.description}
          </div>

          {/* Задания дня (v1.7.0) */}
          <div className="mt-3 flex items-center">
            <span className="flex-1 text-[15px] font-extrabold" style={{ color: C.ink }}>
              Задания дня
            </span>
            <span className="text-[12.5px] font-bold" style={{ color: C.inkSoft }}>
              {quests.filter((q) => questClaimed.includes(q.id)).length}/3
            </span>
          </div>
          <div className="mt-2 space-y-2.5">
            {quests.map((q) => {
              const claimed = questClaimed.includes(q.id);
              const prog = Math.min(q.target, questProgress[q.id] ?? 0);
              const complete = prog >= q.target;
              return (
                <div key={q.id}>
                  <div className="flex items-center gap-2.5">
                    <span className="text-[20px]">{q.emoji}</span>
                    <div className="flex-1">
                      <p className="text-[13.5px] font-bold" style={{ color: C.ink }}>
                        {q.title}
                      </p>
                      <p className="text-[11.5px]" style={{ color: C.inkSoft }}>
                        {claimed
                          ? `Награда получена: +${q.rewardCoins} 🪙 +${q.rewardXp} XP`
                          : `${q.hint} · ${prog}/${q.target}`}
                      </p>
                    </div>
                    {claimed ? (
                      <CheckCircle2 size={22} style={{ color: C.green }} />
                    ) : complete ? (
                      <button
                        type="button"
                        className="rounded-xl px-3 py-1.5 text-[12.5px] font-extrabold text-white transition-transform active:scale-95"
                        style={{ backgroundColor: C.green }}
                        onClick={() => {
                          if (claimQuest(q.id)) toast(`Награда: +${q.rewardCoins} 🪙 +${q.rewardXp} XP`);
                        }}
                      >
                        Забрать
                      </button>
                    ) : null}
                  </div>
                  <div className="mt-1.5 h-[6px] overflow-hidden rounded-full" style={{ backgroundColor: "#EFF4EC" }}>
                    <div
                      className="h-full rounded-full transition-all"
                      style={{ width: `${(prog / q.target) * 100}%`, backgroundColor: C.green }}
                    />
                  </div>
                </div>
              );
            })}
          </div>

          {/* Сон (v1.7.0) — питомец спит ЛЕЖА */}
          <div className="mt-3.5 flex items-center gap-3">
            <span className="text-[24px]">🌙</span>
            <div className="flex-1">
              <p className="text-[14.5px] font-extrabold" style={{ color: C.ink }}>
                Уложить питомца спать
              </p>
              <p className="text-[12px] leading-snug" style={{ color: C.inkSoft }}>
                {tuckInDay === dayK
                  ? `Уже спит сладким сном. До завтра! (+${XP_PER_TUCK_IN} XP получено)`
                  : `Вечерний ритуал: питомец уснёт лёжа и получит +${XP_PER_TUCK_IN} XP`}
              </p>
            </div>
            <button
              type="button"
              disabled={tuckInDay === dayK}
              className="rounded-xl px-3.5 py-2 text-[13px] font-extrabold text-white transition-transform active:scale-95 disabled:opacity-50"
              style={{ backgroundColor: C.purple }}
              onClick={() => {
                if (tuckIn()) {
                  addQuestProgress("tuck_in", 1);
                  toast(`Питомец уснул 😴 +${XP_PER_TUCK_IN} XP`);
                }
              }}
            >
              {tuckInDay === dayK ? "Спит" : "Уложить"}
            </button>
          </div>
        </InfoCard>

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
                  {stageEmoji(petStage(p))} {p.name} · {STAGE_NAMES[petStage(p)]}
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
