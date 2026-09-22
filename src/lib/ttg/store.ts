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
import { moodAnalyze } from "./moodai";
import { compareVersions, dayKey, mondayMs, nextVersion, seededRandom, stringHash } from "./format";

export const K_DIARY_SYSTEM_PROMPT =
  "Ты — тёплый и заботливый ИИ-садовник приложения «Время Расти» " +
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
  todayKey: string;
  lastSessionDayKey: string;
  weekKey: string;

  // Session
  sessionStartedAt: number | null; // мс epoch
  timeMachine: boolean;
  lastSessionMinutes: number | null;
  nowMs: number; // тикер для таймера (не персистится)

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
  addDetoxMinutes: (minutes: number) => string | null; // возвращает имя, если эволюция
  hatchNewEgg: () => void;
  renamePet: (id: string, name: string) => void;
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
      todayKey: "",
      lastSessionDayKey: "",
      weekKey: "",

      sessionStartedAt: null,
      timeMachine: false,
      lastSessionMinutes: null,
      nowMs: Date.now(),

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
        set({ sessionStartedAt: Date.now() });
      },

      stopSession: () => {
        const s = get();
        if (!s.sessionStartedAt) return { minutes: 0, evolvedPetName: null };
        const realSec = Math.max(0, Math.floor((Date.now() - s.sessionStartedAt) / 1000));
        // Машина времени: 1 секунда = 1 минута
        const minutes = s.timeMachine ? realSec : Math.floor(realSec / 60);
        const evolved = s.addDetoxMinutes(minutes);
        set({ sessionStartedAt: null, lastSessionMinutes: minutes });
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

      hatchNewEgg: () => {
        const s = get();
        if (s.pets.some((p) => petStage(p) < 3)) return;
        set({ pets: [...s.pets, makeEgg(s.pets.length)] });
      },

      renamePet: (id, name) => {
        const clean = name.trim();
        if (!clean) return;
        set({
          pets: get().pets.map((p) => (p.id === id ? { ...p, name: clean } : p)),
        });
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
          pets: [makeEgg(0)],
          totalMinutes: 0,
          todayMinutes: 0,
          streakDays: 0,
          weekMinutes: 0,
          lastSessionDayKey: "",
          sessionStartedAt: null,
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
      partialize: (s) => ({
        pets: s.pets,
        totalMinutes: s.totalMinutes,
        todayMinutes: s.todayMinutes,
        streakDays: s.streakDays,
        weekMinutes: s.weekMinutes,
        todayKey: s.todayKey,
        lastSessionDayKey: s.lastSessionDayKey,
        weekKey: s.weekKey,
        sessionStartedAt: s.sessionStartedAt,
        timeMachine: s.timeMachine,
        diaryEntries: s.diaryEntries,
        llm: s.llm,
        weekly: s.weekly,
        simulateUpdate: s.simulateUpdate,
        customUpdateUrl: s.customUpdateUrl,
        appVersion: s.appVersion,
        hintDismissed: s.hintDismissed,
      }),
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

export function elapsedSeconds(startedAt: number | null, timeMachine: boolean): number {
  if (!startedAt) return 0;
  const real = Math.floor((Date.now() - startedAt) / 1000);
  return timeMachine ? real * 60 : real;
}
