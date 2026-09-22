"use client";

// Оболочка приложения (порт lib/screens/home_shell.dart): глобальный
// баннер обновлений + 4 вкладки + инициализация сервисов при старте.

import { useEffect, useState, useSyncExternalStore } from "react";
import { useTTG } from "@/lib/ttg/store";
import { C } from "@/lib/ttg/types";
import { UpdateBanner } from "./update-banner";
import { PetScreen } from "./pet-screen";
import { PetChoiceScreen } from "./pet-choice-screen";
import { DiaryScreen } from "./diary-screen";
import { ChallengeScreen } from "./challenge-screen";
import { ProfileScreen } from "./profile-screen";
import { PawPrint, NotebookPen, Trophy, User } from "lucide-react";
import { Toaster } from "sonner";

const TABS = [
  { key: "pet", label: "Питомец", icon: PawPrint, title: "Время Расти" },
  { key: "diary", label: "Дневник", icon: NotebookPen, title: "Дневник настроения" },
  { key: "challenge", label: "Челлендж", icon: Trophy, title: "Челленджи" },
  { key: "profile", label: "Профиль", icon: User, title: "Профиль" },
] as const;

type TabKey = (typeof TABS)[number]["key"];

const subscribeNoop = () => () => {};

export function TTGApp() {
  const [tab, setTab] = useState<TabKey>("pet");

  // false на сервере и при гидрации, true после — без setState в эффекте
  const mounted = useSyncExternalStore(
    subscribeNoop,
    () => true,
    () => false
  );

  const hydrated = useTTG((s) => s.hydrated);
  const needsPetChoice = useTTG((s) => s.needsPetChoice);
  const rollDateCounters = useTTG((s) => s.rollDateCounters);
  const ensureWeekly = useTTG((s) => s.ensureWeekly);
  const refreshChallenge = useTTG((s) => s.refreshChallenge);
  const tick = useTTG((s) => s.tick);
  const onAppVisibility = useTTG((s) => s.onAppVisibility);

  // Гидрация и инициализация (аналог load() всех сервисов).
  // Первого питомца НЕ создаём автоматически — вид выбирает
  // пользователь на большом экране выбора (как в v1.1.0).
  useEffect(() => {
    if (!hydrated) return;
    rollDateCounters();
    ensureWeekly();
    refreshChallenge();
  }, [hydrated]);

  // Тикер таймера сессии — раз в секунду
  useEffect(() => {
    const t = setInterval(() => tick(), 1000);
    return () => clearInterval(t);
  }, [tick]);

  // Экранное время в демо: вкладка скрыта = «экран телефона погашен».
  // Скрыли вкладку — счёт пошёл; вернулись — время зачислено.
  useEffect(() => {
    const onVis = () =>
      onAppVisibility(document.visibilityState === "visible");
    document.addEventListener("visibilitychange", onVis);
    return () => document.removeEventListener("visibilitychange", onVis);
  }, [onAppVisibility]);

  if (!mounted || !hydrated) {
    return (
      <div className="flex min-h-[100dvh] items-center justify-center" style={{ backgroundColor: C.bg }}>
        <div className="flex flex-col items-center gap-3">
          <span className="text-4xl">🌱</span>
          <span className="text-[15px] font-bold" style={{ color: C.inkSoft }}>
            Время Расти…
          </span>
        </div>
      </div>
    );
  }

  const activeTab = TABS.find((t) => t.key === tab)!;

  return (
    <div
      className="flex min-h-[100dvh] items-center justify-center sm:py-5"
      style={{
        background:
          "radial-gradient(1200px 600px at 15% 0%, #DCF3FF 0%, transparent 60%)," +
          "radial-gradient(1000px 500px at 90% 100%, #E4F6E2 0%, transparent 55%)," +
          "#F6F3EA",
      }}
    >
      <div
        className="relative flex h-[100dvh] w-full max-w-[430px] flex-col overflow-hidden bg-white sm:h-[min(880px,94dvh)] sm:rounded-[2rem] sm:border-2 sm:shadow-2xl"
        style={{ borderColor: C.border }}
      >
        {/* Выбор питомца — ворота первого запуска (v1.1.0) */}
        {needsPetChoice ? (
          <PetChoiceScreen />
        ) : (
          <>
            {/* Глобальный баннер обновлений */}
            <div className="shrink-0">
              <UpdateBanner />
            </div>

            {/* Заголовок */}
            <header className="shrink-0 bg-[#FFFDF7] py-3 text-center">
              <h1
                className="text-[20px] font-extrabold"
                style={{ color: C.ink }}
              >
                {activeTab.title}
              </h1>
            </header>

            {/* Контент */}
            <main className="min-h-0 flex-1">
              {tab === "pet" && <PetScreen />}
              {tab === "diary" && <DiaryScreen />}
              {tab === "challenge" && <ChallengeScreen />}
              {tab === "profile" && <ProfileScreen />}
            </main>

            {/* Нижняя навигация */}
            <nav
              className="flex shrink-0 border-t-2 bg-white pb-[max(env(safe-area-inset-bottom),8px)] pt-1.5"
              style={{ borderColor: C.border }}
              aria-label="Основная навигация"
            >
              {TABS.map((t) => {
                const selected = t.key === tab;
                const Icon = t.icon;
                return (
                  <button
                    key={t.key}
                    type="button"
                    onClick={() => setTab(t.key)}
                    className="flex flex-1 flex-col items-center gap-0.5 py-1.5"
                    aria-current={selected ? "page" : undefined}
                  >
                    <Icon
                      size={26}
                      strokeWidth={selected ? 2.6 : 2}
                      style={{ color: selected ? C.green : C.inkSoft }}
                    />
                    <span
                      className="text-[12px] font-bold"
                      style={{ color: selected ? C.green : C.inkSoft }}
                    >
                      {t.label}
                    </span>
                  </button>
                );
              })}
            </nav>
          </>
        )}
      </div>

      <Toaster
        position="top-center"
        toastOptions={{
          style: {
            background: C.ink,
            color: "#FFFFFF",
            fontSize: "14px",
            borderRadius: "14px",
            maxWidth: "360px",
          },
        }}
      />
    </div>
  );
}
