// Ежедневные задания «Ростка» (v1.7.0) — зеркало lib/models/quest.dart.
// Хеш совпадает с Flutter (BigInt для точности 64-битной арифметики),
// поэтому задания дня одинаковы в приложении и в демо.

import { isAquatic, isPlant, petStage } from "./types";
import type { Pet } from "./types";

export interface Quest {
  id: string;
  emoji: string;
  title: string;
  hint: string;
  target: number;
  rewardCoins: number;
  rewardXp: number;
}

export const QUEST_POOL: Quest[] = [
  { id: "session_10", emoji: "⏱️", title: "Десять минут тишины", hint: "Провести 10 минут в сессии детокса", target: 10, rewardCoins: 15, rewardXp: 10 },
  { id: "session_30", emoji: "🌿", title: "Полчаса без телефона", hint: "Провести 30 минут в сессии детокса", target: 30, rewardCoins: 30, rewardXp: 20 },
  { id: "feed_5", emoji: "🍽️", title: "Сытный обед", hint: "Поймать 5 едой в мини-игре «Покорми питомца»", target: 5, rewardCoins: 20, rewardXp: 15 },
  { id: "diary_1", emoji: "📓", title: "Вечерняя заметка", hint: "Написать запись в дневнике", target: 1, rewardCoins: 15, rewardXp: 10 },
  { id: "tuck_in", emoji: "🌙", title: "Спокойной ночи", hint: "Уложить питомца спать", target: 1, rewardCoins: 10, rewardXp: 5 },
  { id: "shop_1", emoji: "🛍️", title: "Заглянуть в магазин", hint: "Купить что-нибудь за монетки", target: 1, rewardCoins: 10, rewardXp: 5 },
];

export interface SeasonEvent {
  id: string;
  title: string;
  emoji: string;
  description: string;
}

export const SEASON_EVENTS: SeasonEvent[] = [
  { id: "spring", title: "Весенний сад", emoji: "🌸", description: "Всё цветёт! Питомцы получают +10% XP в этом сезоне." },
  { id: "summer", title: "Летний пикник", emoji: "☀️", description: "Яркое солнце! Еда в мини-игре падает чуть быстрее." },
  { id: "autumn", title: "Осенний листопад", emoji: "🍂", description: "Время открыток: собирайте осенние виды!" },
  { id: "winter", title: "Зимняя ярмарка", emoji: "❄️", description: "Снежные вечера: серии дней растут быстрее." },
];

export function seasonOf(d: Date): SeasonEvent {
  const m = d.getMonth() + 1;
  if (m >= 3 && m <= 5) return SEASON_EVENTS[0];
  if (m >= 6 && m <= 8) return SEASON_EVENTS[1];
  if (m >= 9 && m <= 11) return SEASON_EVENTS[2];
  return SEASON_EVENTS[3];
}

/** Хеш, побитово совпадающий с questHash в Dart (lehmer/FNV-гибрид). */
export function questHash(input: string): number {
  let h = BigInt(2166136261);
  const M = BigInt(2147483647);
  const mul1 = BigInt(16777619);
  const mul2 = BigInt(48271);
  for (let i = 0; i < input.length; i++) {
    h ^= BigInt(input.charCodeAt(i));
    h = (h * mul1) & M;
    h = (h * mul2) & M;
  }
  return Number(h);
}

export function dailyQuests(dayKey: string): Quest[] {
  const seed = questHash(`rostok-quests-${dayKey}`);
  const idx = [0, 1, 2, 3, 4, 5];
  let s = seed;
  for (let i = idx.length - 1; i > 0; i--) {
    s = (s * 48271) & 0x7fffffff;
    const j = s % (i + 1);
    [idx[i], idx[j]] = [idx[j], idx[i]];
  }
  return [QUEST_POOL[idx[0]], QUEST_POOL[idx[1]], QUEST_POOL[idx[2]]];
}

export const XP_PER_TUCK_IN = 20;

// ── Открытки ─────────────────────────────────────────────────────────
export interface Postcard {
  id: string;
  emoji: string;
  title: string;
  howTo: string;
}

export const POSTCARDS: Postcard[] = [
  { id: "pc_first", emoji: "🐣", title: "Первый друг", howTo: "Вылупите первого питомца" },
  { id: "pc_streak3", emoji: "🔥", title: "Три дня подряд", howTo: "Серия из 3 дней" },
  { id: "pc_streak7", emoji: "⚡", title: "Неделя огня", howTo: "Серия из 7 дней" },
  { id: "pc_300", emoji: "🌿", title: "Пять часов", howTo: "300 минут детокса всего" },
  { id: "pc_adult", emoji: "🦊", title: "Совсем большой", howTo: "Вырастите взрослого питомца" },
  { id: "pc_coins", emoji: "💰", title: "Запасливый", howTo: "Накопите 500 монеток" },
  { id: "pc_quests5", emoji: "📋", title: "Исполнитель", howTo: "Выполните 5 заданий" },
  { id: "pc_quests15", emoji: "🏆", title: "Мастер пауз", howTo: "Выполните 15 заданий" },
  { id: "pc_diary10", emoji: "📓", title: "Летописец", howTo: "10 записей в дневнике" },
  { id: "pc_zoo", emoji: "🎪", title: "Зоопарк", howTo: "10 разных видов в коллекции" },
];

export interface PostcardStatsInput {
  pets: Pet[];
  totalMinutes: number;
  streakDays: number;
  coins: number;
  questsDone: number;
  diaryCount: number;
}

export function postcardUnlocked(id: string, st: PostcardStatsInput): boolean {
  const kinds = st.pets.map((p) => p.type);
  const unique = new Set(kinds);
  switch (id) {
    case "pc_first":
      return st.pets.length >= 1;
    case "pc_streak3":
      return st.streakDays >= 3;
    case "pc_streak7":
      return st.streakDays >= 7;
    case "pc_300":
      return st.totalMinutes >= 300;
    case "pc_adult":
      return st.pets.some((p) => petStage(p) >= 3);
    case "pc_coins":
      return st.coins >= 500;
    case "pc_quests5":
      return st.questsDone >= 5;
    case "pc_quests15":
      return st.questsDone >= 15;
    case "pc_diary10":
      return st.diaryCount >= 10;
    case "pc_zoo":
      return unique.size >= 10;
    default:
      return false;
  }
}

// Проверка типов для помощников коллекций (используются в сценах)
export const _collectionHelpers = { isAquatic, isPlant };
