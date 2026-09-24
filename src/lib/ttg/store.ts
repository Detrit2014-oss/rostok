"use client";

// ─────────────────────────────────────────────────────────────────────
// Единое состояние приложения (порт сервисов Flutter на zustand):
//  • PetService            — питомцы, эволюция, серия дней, недельная статистика
//  • FocusSessionService   — сессия по реальному времени + машина времени ×60
//  • DiaryService          — дневник с двойным ответом (офлайн + LLM)
//  • ChallengeService      — «Детокс-неделя», боты с детерминированным сидом
//  • UpdateService         — проверка version.json + симуляция обновления
// Всё переживает перезагрузку страницы (localStorage).
// ─────────────────────────────────────────────────────────────────────

import { create } from "zustand";
import { persist } from "zustand/middleware";
import {
  AppUpdateInfo,
  Challenge,
  ChallengeParticipant,
  DiaryEntry,
  K_APP_VERSION,
  K_DEFAULT_UPDATE_URL,
  LlmConfig,
  PET_CATALOG,
  Pet,
  petStage,
} from "./types";
import type { PetType } from "./types";
import { moodAnalyze } from "./moodai";
import { compareVersions, dayKey, mondayMs, nextVersion, seededRandom, stringHash } from "./format";

export const K_DIARY_SYSTEM_PROMPT =
  "Ты — тёплый и заботливый ИИ-садовник приложения «Росток» " +
  "о цифровой гигиене и ментальном здоровье. Пользователь вечером пишет " +
  "короткую заметку о своём дне. Ответь на русском: 2–4 предложения. " +
  "Поддержи человека, мягко отрази его чувства без осуждения и дай одну " +
  "практичную рекомендацию для улучшения сна или снижения стресса. " +
  "Без диагнозов, без канцелярита, обращение на «вы».";

const BOT_NAMES = ["Аня", "Марк", "Лена", "Дима", "Соня", "Кирилл"];
const BOT_EMOJIS = ["🌻", "🌷", "🌿", "🌲", "🍀", "🐝"];

interface TTGState {
  hydrated: boolean;

  // Pets & stats
  pets: Pet[];
  totalMinutes: number;
  todayMinutes: number;
  streakDays: number;
  weekMinutes: number;
  /** Монетки (v1.5.0) — валюта магазина. */
  coins: number;
  /** Заморозки серии 🧊 (v1.7.0), максимум 2. */
  freezes: number;
  todayKey: string;
  lastSessionDayKey: string;
  weekKey: string;

  // Session — привязана к экранному времени (порт v1.1.0):
  // засчитывается только время, когда вкладка/приложение НЕ активны
  // (на телефоне — экран погашен; в демо — вкладка скрыта).
  sessionStartedAt: number | null; // мс epoch
  countedSec: number; // уже засчитанные секунды «вне экрана»
  awaySinceMs: number | null; // когда вкладка скрылась (мс epoch)
  timeMachine: boolean; // ×60, считает ВСЁ время (тест)
  lastSessionMinutes: number | null;
  nowMs: number; // тикер для таймера (не персистится)

  // Выбор питомца (v1.1.0)
  needsPetChoice: boolean;

  // Diary
  diaryEntries: DiaryEntry[];
  llm: LlmConfig;

  // Challenge
  weekly: Challenge | null;

  // Updates
  simulateUpdate: boolean;
  customUpdateUrl: string;
  availableUpdate: AppUpdateInfo | null;
  updateLastError: string | null;
  updateChecking: boolean;
  appVersion: string;

  hintDismissed: boolean;

  // ── actions ──
  setHydrated: () => void;
  tick: () => void;
  rollDateCounters: () => void;
  startSession: () => void;
  stopSession: () => { minutes: number; evolvedPetName: string | null };
  onAppVisibility: (visible: boolean) => void;
  choosePet: (type: PetType) => void;
  openPetChoice: () => void;
  cancelPetChoice: () => void;
  addDetoxMinutes: (minutes: number) => string | null; // возвращает имя, если эволюция
  renamePet: (id: string, name: string) => void;
  /** Начислить XP активному питомцу (кормление, задания). */
  addXp: (amount: number) => void;
  addCoins: (amount: number) => void;
  /** Купить рамку активному питомцу; false — не хватило монет. */
  buyFrame: (frameId: string, price: number) => boolean;
  /** Купить заморозку серии 🧊; false — лимит/не хватает монет. */
  buyFreeze: () => boolean;
  setTimeMachine: (v: boolean) => void;
  addDiaryEntry: (text: string) => DiaryEntry;
  applyLlmReply: (id: string, reply: string) => void;
  setLlmConfig: (cfg: LlmConfig) => void;
  ensureWeekly: () => void;
  refreshChallenge: () => void;
  createChallenge: (title: string, goalHours: number) => void;
  setSimulateUpdate: (v: boolean) => void;
  setCustomUpdateUrl: (url: string) => void;
  checkForUpdates: () => Promise<"available" | "latest" | "error" | "simulated">;
  clearAvailableUpdate: () => void;
  applyUpdate: (version: string) => void;
  dismissHint: () => void;
  resetAll: () => void;
}

function makeEgg(index: number): Pet {
  const species = PET_CATALOG[index % PET_CATALOG.length];
  return {
    id: `p${Date.now()}${Math.floor(Math.random() * 1000)}`,
    name: species.name,
    type: species.type,
    bornAt: Date.now(),
    growthMinutes: 0,
    xp: 0,
    frame: "none",
  };
}

/** Боты живут своей жизнью: прогресс детерминирован сидом и днём недели. */
function updateBots(c: Challenge): void {
  const wd = new Date().getDay() === 0 ? 7 : new Date().getDay();
  const rnd = seededRandom(stringHash(c.id));
  for (const p of c.participants) {
    if (p.isUser) continue;
    const pacePerDay = 40 + Math.floor(rnd() * 60); // 40–99 мин/день
    p.minutes = pacePerDay * wd + Math.floor(rnd() * 30);
  }
}

function newWeeklyChallenge(goalHours = 10, title = "Детокс-неделя"): Challenge {
  const monday = mondayMs(new Date());
  return {
    id: `w${monday}`,
    title,
    goalHours,
    weekStartMs: monday,
    isDemo: true,
    participants: [
      { name: "Вы", emoji: "🐾", minutes: 0, isUser: true },
      ...BOT_NAMES.slice(0, 4).map((name, i) => ({
        name,
        emoji: BOT_EMOJIS[i],
        minutes: 0,
        isUser: false,
      })),
    ],
  };
}

export const useTTG = create<TTGState>()(
  persist(
    (set, get) => ({
      hydrated: false,

      pets: [],
      totalMinutes: 0,
      todayMinutes: 0,
      streakDays: 0,
      weekMinutes: 0,
      coins: 0,
      freezes: 0,
      todayKey: "",
      lastSessionDayKey: "",
      weekKey: "",

      sessionStartedAt: null,
      countedSec: 0,
      awaySinceMs: null,
      timeMachine: false,
      lastSessionMinutes: null,
      nowMs: Date.now(),

      needsPetChoice: true,

      diaryEntries: [],
      llm: { baseUrl: "https://api.openai.com/v1", apiKey: "", model: "gpt-4o-mini" },

      weekly: null,

      simulateUpdate: false,
      customUpdateUrl: "",
      availableUpdate: null,
      updateLastError: null,
      updateChecking: false,
      appVersion: K_APP_VERSION,

      hintDismissed: false,

      setHydrated: () => set({ hydrated: true }),

      tick: () => {
        if (get().sessionStartedAt !== null) set({ nowMs: Date.now() });
      },

      rollDateCounters: () => {
        const s = get();
        const now = new Date();
        const today = dayKey(now);
        let { todayMinutes, weekMinutes, todayKey, weekKey } = s;
        if (today !== todayKey) {
          todayMinutes = 0;
          todayKey = today;
        }
        const monday = mondayMs(now);
        const wk = dayKey(new Date(monday));
        if (wk !== weekKey) {
          weekMinutes = 0;
          weekKey = wk;
        }
        set({ todayMinutes, weekMinutes, todayKey, weekKey });
      },

      startSession: () => {
        if (get().sessionStartedAt) return;
        set({
          sessionStartedAt: Date.now(),
          countedSec: 0,
          awaySinceMs: null,
        });
      },

      /** Вкладка скрылась — рост пошёл; вернулась — капнувшее переводим в зачёт. */
      onAppVisibility: (visible) => {
        const s = get();
        if (!s.sessionStartedAt || s.timeMachine) return;
        if (!visible) {
          if (!s.awaySinceMs) set({ awaySinceMs: Date.now() });
          return;
        }
        const away = s.awaySinceMs;
        if (!away) return;
        const addSec = Math.max(0, Math.floor((Date.now() - away) / 1000));
        set({ countedSec: s.countedSec + addSec, awaySinceMs: null, nowMs: Date.now() });
      },

      /** Большой экран выбора: создаём питомца выбранного вида. */
      choosePet: (type) => {
        const s = get();
        const species = PET_CATALOG.find((x) => x.type === type) ?? PET_CATALOG[0];
        const pet: Pet = {
          id: `p${Date.now()}${Math.floor(Math.random() * 1000)}`,
          name: species.name,
          type,
          bornAt: Date.now(),
          growthMinutes: 0,
          xp: 0,
          frame: "none",
        };
        set({ pets: [...s.pets, pet], needsPetChoice: false });
      },

      openPetChoice: () => set({ needsPetChoice: true }),
      cancelPetChoice: () => set({ needsPetChoice: false }),

      stopSession: () => {
        const s = get();
        if (!s.sessionStartedAt) return { minutes: 0, evolvedPetName: null };
        let minutes: number;
        if (s.timeMachine) {
          // 1 секунда = 1 минута, считается всё время
          minutes = Math.floor((Date.now() - s.sessionStartedAt) / 1000);
        } else {
          const pending = s.awaySinceMs
            ? Math.max(0, Math.floor((Date.now() - s.awaySinceMs) / 1000))
            : 0;
          minutes = Math.floor((s.countedSec + pending) / 60);
        }
        set({
          sessionStartedAt: null,
          countedSec: 0,
          awaySinceMs: null,
          lastSessionMinutes: minutes,
        });
        const evolved = s.addDetoxMinutes(minutes);
        return { minutes, evolvedPetName: evolved };
      },

      addDetoxMinutes: (minutes) => {
        if (minutes <= 0) return null;
        get().rollDateCounters();
        const s = get();

        let pets = [...s.pets];
        let targetIdx = pets.findIndex((p) => petStage(p) < 3);
        if (targetIdx === -1) {
          pets.push(makeEgg(pets.length));
          targetIdx = pets.length - 1;
        }
        const target = pets[targetIdx];
        const wasAdult = petStage(target) >= 3;
        let evolvedName: string | null = null;
        const updatedTarget: Pet = {
          ...target,
          growthMinutes: target.growthMinutes + minutes,
          // XP-экономика (v1.5.0): 1 минута детокса = 1 XP питомцу.
          xp: (target.xp ?? 0) + minutes,
        };
        if (!wasAdult && petStage(updatedTarget) >= 3) {
          evolvedName = updatedTarget.name;
        }
        pets[targetIdx] = updatedTarget;

        // Серия дней
        let { streakDays, lastSessionDayKey } = s;
        const today = dayKey(new Date());
        if (lastSessionDayKey !== today) {
          const y = new Date();
          y.setDate(y.getDate() - 1);
          streakDays = lastSessionDayKey === dayKey(y) ? streakDays + 1 : 1;
          lastSessionDayKey = today;
        }

        set({
          pets,
          totalMinutes: s.totalMinutes + minutes,
          todayMinutes: s.todayMinutes + minutes,
          weekMinutes: s.weekMinutes + minutes,
          // Монетки (v1.5.0): 1 минута = 1 монетка.
          coins: (s.coins ?? 0) + minutes,
          streakDays,
          lastSessionDayKey,
          weekly: s.weekly
            ? {
                ...s.weekly,
                participants: s.weekly.participants.map((p) =>
                  p.isUser ? { ...p, minutes: s.weekMinutes + minutes } : p
                ),
              }
            : null,
        });
        return evolvedName;
      },

      renamePet: (id, name) => {
        const clean = name.trim();
        if (!clean) return;
        set({
          pets: get().pets.map((p) => (p.id === id ? { ...p, name: clean } : p)),
        });
      },

      addXp: (amount) => {
        if (amount <= 0) return;
        set({
          pets: get().pets.map((p) =>
            petStage(p) < 3 ? { ...p, xp: (p.xp ?? 0) + amount } : p
          ),
        });
      },

      addCoins: (amount) =>
        set({ coins: Math.max(0, (get().coins ?? 0) + amount) }),

      buyFrame: (frameId, price) => {
        const s = get();
        if ((s.coins ?? 0) < price) return false;
        const idx = s.pets.findIndex((p) => petStage(p) < 3);
        if (idx === -1) return false;
        set({
          coins: s.coins - price,
          pets: s.pets.map((p, i) =>
            i === idx ? { ...p, frame: frameId } : p
          ),
        });
        return true;
      },

      buyFreeze: () => {
        const s = get();
        if (s.freezes >= 2) return false;
        if (s.coins < 200) return false;
        set({ coins: s.coins - 200, freezes: s.freezes + 1 });
        return true;
      },

      setTimeMachine: (v) => set({ timeMachine: v }),

      addDiaryEntry: (text) => {
        const local = moodAnalyze(text);
        const entry: DiaryEntry = {
          id: `d${Date.now()}`,
          createdAt: Date.now(),
          text,
          moodScore: local.score,
          tags: local.tags,
          aiReply: local.reply,
          source: "local",
        };
        set({ diaryEntries: [entry, ...get().diaryEntries] });
        return entry;
      },

      applyLlmReply: (id, reply) => {
        set({
          diaryEntries: get().diaryEntries.map((e) =>
            e.id === id ? { ...e, aiReply: reply, source: "llm" as const } : e
          ),
        });
      },

      setLlmConfig: (cfg) =>
        set({
          llm: {
            baseUrl: cfg.baseUrl.trim() || "https://api.openai.com/v1",
            apiKey: cfg.apiKey.trim(),
            model: cfg.model.trim() || "gpt-4o-mini",
          },
        }),

      ensureWeekly: () => {
        const s = get();
        const monday = mondayMs(new Date());
        if (!s.weekly || s.weekly.weekStartMs !== monday) {
          set({ weekly: newWeeklyChallenge() });
        }
      },

      refreshChallenge: () => {
        get().ensureWeekly();
        const s = get();
        if (!s.weekly) return;
        const weekly: Challenge = { ...s.weekly, participants: [...s.weekly.participants] };
        updateBots(weekly);
        weekly.participants = weekly.participants.map((p) =>
          p.isUser ? { ...p, minutes: s.weekMinutes } : p
        );
        set({ weekly });
      },

      createChallenge: (title, goalHours) => {
        const monday = mondayMs(new Date());
        const goal = Math.min(60, Math.max(1, goalHours));
        const rnd = seededRandom(Date.now() % 2147483647);
        const pick = <T,>(arr: T[]) => arr[Math.floor(rnd() * arr.length)];
        const weekly: Challenge = {
          id: `w${monday}-${Date.now() % 100000}`,
          title: title.trim() || "Мой челлендж",
          goalHours: goal,
          weekStartMs: monday,
          isDemo: true,
          participants: [
            { name: "Вы", emoji: "🐾", minutes: get().weekMinutes, isUser: true },
            ...Array.from({ length: 4 }, () => {
              const i = Math.floor(rnd() * BOT_NAMES.length);
              return {
                name: pick(BOT_NAMES),
                emoji: BOT_EMOJIS[i],
                minutes: 0,
                isUser: false,
              };
            }),
          ],
        };
        updateBots(weekly);
        weekly.participants = weekly.participants.map((p) =>
          p.isUser ? { ...p, minutes: get().weekMinutes } : p
        );
        set({ weekly });
      },

      setSimulateUpdate: (v) =>
        set({
          simulateUpdate: v,
          availableUpdate: v ? simulatedInfo(get().appVersion) : null,
        }),

      setCustomUpdateUrl: (url) => set({ customUpdateUrl: url }),

      checkForUpdates: async () => {
        const s = get();
        if (s.simulateUpdate) {
          set({ availableUpdate: simulatedInfo(s.appVersion) });
          return "simulated";
        }
        set({ updateChecking: true, updateLastError: null });
        const url = s.customUpdateUrl.trim() || K_DEFAULT_UPDATE_URL;
        try {
          const res = await fetch(url, { cache: "no-store" });
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          const data = (await res.json()) as AppUpdateInfo;
          const isNewer = compareVersions(data.latest_version ?? "", s.appVersion) > 0;
          set({
            updateChecking: false,
            availableUpdate: isNewer ? data : null,
          });
          return isNewer ? "available" : "latest";
        } catch (e) {
          set({
            updateChecking: false,
            updateLastError: `Не удалось проверить обновления: ${e instanceof Error ? e.message : "ошибка сети"}`,
          });
          return "error";
        }
      },

      clearAvailableUpdate: () => set({ availableUpdate: null }),

      applyUpdate: (version) =>
        set({
          appVersion: version,
          availableUpdate: null,
          simulateUpdate: false,
        }),

      dismissHint: () => set({ hintDismissed: true }),

      resetAll: () =>
        set({
          pets: [],
          needsPetChoice: true,
          totalMinutes: 0,
          todayMinutes: 0,
          streakDays: 0,
          weekMinutes: 0,
          coins: 0,
          freezes: 0,
          lastSessionDayKey: "",
          sessionStartedAt: null,
          countedSec: 0,
          awaySinceMs: null,
          lastSessionMinutes: null,
          diaryEntries: [],
          weekly: newWeeklyChallenge(),
          simulateUpdate: false,
          availableUpdate: null,
          updateLastError: null,
        }),
    }),
    {
      name: "ttg-web-state-v1",
      version: 2,
      partialize: (s) => ({
        pets: s.pets,
        totalMinutes: s.totalMinutes,
        todayMinutes: s.todayMinutes,
        streakDays: s.streakDays,
        weekMinutes: s.weekMinutes,
        coins: s.coins,
        freezes: s.freezes,
        todayKey: s.todayKey,
        lastSessionDayKey: s.lastSessionDayKey,
        weekKey: s.weekKey,
        sessionStartedAt: s.sessionStartedAt,
        countedSec: s.countedSec,
        awaySinceMs: s.awaySinceMs,
        timeMachine: s.timeMachine,
        needsPetChoice: s.needsPetChoice,
        diaryEntries: s.diaryEntries,
        llm: s.llm,
        weekly: s.weekly,
        simulateUpdate: s.simulateUpdate,
        customUpdateUrl: s.customUpdateUrl,
        appVersion: s.appVersion,
        hintDismissed: s.hintDismissed,
      }),
      migrate: (persisted: unknown, version: number) => {
        const s = persisted as Partial<TTGState>;
        if (version < 2) {
          // v1: яйцо создавалось автоматически — тем, у кого коллекция
          // уже есть, выбор не показываем; новым — показываем.
          s.needsPetChoice = !s.pets || s.pets.length === 0;
          s.countedSec = 0;
          s.awaySinceMs = null;
        }
        return s as TTGState;
      },
      onRehydrateStorage: () => (state) => {
        state?.setHydrated();
      },
    }
  )
);

function simulatedInfo(current: string): AppUpdateInfo {
  return {
    latest_version: nextVersion(current),
    notes:
      "Демо-обновление: ровно так баннер увидят все пользователи " +
      "после публикации нового version.json на хостинге.",
    force_update: false,
    android_url: "https://play.google.com/store/apps/details?id=REPLACE_ME",
    ios_url: "https://apps.apple.com/app/REPLACE_ME",
  };
}

/** Селекторы-помощники */
export function activePet(pets: Pet[]): Pet | null {
  for (const p of pets) if (petStage(p) < 3) return p;
  return null;
}

export function adultCount(pets: Pet[]): number {
  return pets.filter((p) => petStage(p) >= 3).length;
}

export function leaderboard(weekly: Challenge | null): ChallengeParticipant[] {
  if (!weekly) return [];
  return [...weekly.participants].sort((a, b) => b.minutes - a.minutes);
}

export function daysLeft(): number {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const monday = new Date(today);
  const wd = now.getDay() === 0 ? 7 : now.getDay();
  monday.setDate(today.getDate() - (wd - 1));
  const nextMonday = new Date(monday);
  nextMonday.setDate(monday.getDate() + 7);
  return Math.round((nextMonday.getTime() - today.getTime()) / 86400000);
}

/** Засчитанные секунды текущей сессии (фон + текущий период вне вкладки). */
export function countedSecondsSoFar(s: {
  sessionStartedAt: number | null;
  countedSec: number;
  awaySinceMs: number | null;
  timeMachine: boolean;
  nowMs: number;
}): number {
  if (!s.sessionStartedAt) return 0;
  if (s.timeMachine) {
    return Math.floor((s.nowMs - s.sessionStartedAt) / 1000) * 60;
  }
  const pending = s.awaySinceMs
    ? Math.max(0, Math.floor((s.nowMs - s.awaySinceMs) / 1000))
    : 0;
  return s.countedSec + pending;
}
