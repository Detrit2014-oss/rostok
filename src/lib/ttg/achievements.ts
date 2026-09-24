// Достижения «Ростка» (v1.5.0) — зеркало lib/models/achievement.dart.
// 23 медали: серия, время, коллекция, экономика, дневник.

import { isAquatic, isPlant, petLevelFromXp, petStage } from "./types";
import type { Pet } from "./types";

export interface Achievement {
  id: string;
  emoji: string;
  title: string;
  desc: string;
}

export const ACHIEVEMENTS: Achievement[] = [
  { id: "first_egg", emoji: "🥚", title: "Первое яйцо", desc: "Завести своего первого питомца" },
  { id: "first_hatch", emoji: "🐣", title: "Здравствуй, мир!", desc: "Питомец вылупился из яйца" },
  { id: "first_adult", emoji: "🦊", title: "Совсем большой", desc: "Вырастить питомца до взрослого" },
  { id: "first_session", emoji: "⏱️", title: "Первая пауза", desc: "Провести первую сессию детокса" },
  { id: "ten_sessions", emoji: "🌱", title: "Десять минут тишины", desc: "Накопить 10 минут детокса" },
  { id: "hour", emoji: "🕐", title: "Час без телефона", desc: "Накопить 60 минут детокса" },
  { id: "five_hours", emoji: "🌿", title: "Пять часов свободы", desc: "Накопить 300 минут детокса" },
  { id: "day_total", emoji: "🌳", title: "Сутки тишины", desc: "Накопить 24 часа детокса" },
  { id: "streak_3", emoji: "🔥", title: "Три дня подряд", desc: "Серия из 3 дней" },
  { id: "streak_7", emoji: "⚡", title: "Неделя огня", desc: "Серия из 7 дней" },
  { id: "streak_30", emoji: "🌟", title: "Месяц дисциплины", desc: "Серия из 30 дней" },
  { id: "collect_3", emoji: "🧺", title: "Маленькая семья", desc: "Три питомца в коллекции" },
  { id: "collect_5", emoji: "🏡", title: "Уютный домик", desc: "Пять питомцев в коллекции" },
  { id: "plants_lover", emoji: "🪴", title: "Садовник", desc: "Завести комнатное растение" },
  { id: "sea_lover", emoji: "🌊", title: "Морская душа", desc: "Завести водного питомца" },
  { id: "zoo_10", emoji: "🎪", title: "Зоопарк", desc: "Десять разных видов в коллекции" },
  { id: "rich_100", emoji: "🪙", title: "Первая сотня", desc: "Накопить 100 монет" },
  { id: "rich_500", emoji: "💰", title: "Капиталец", desc: "Накопить 500 монет" },
  { id: "shopper", emoji: "🛍️", title: "Модный питомец", desc: "Купить рамку в магазине" },
  { id: "level_5", emoji: "🎖️", title: "Пятый уровень", desc: "Прокачать питомца до 5 уровня" },
  { id: "level_10", emoji: "🏆", title: "Десятый уровень", desc: "Прокачать питомца до 10 уровня" },
  { id: "diary_5", emoji: "📓", title: "Летописец", desc: "Пять записей в дневнике" },
  { id: "diary_20", emoji: "📚", title: "Хроника тишины", desc: "Двадцать записей в дневнике" },
];

export interface AchievementStatsInput {
  pets: Pet[];
  totalMinutes: number;
  streakDays: number;
  coins: number;
  diaryCount: number;
}

/** Вычислить множество открытых достижений по текущей статистике. */
export function computeUnlocked(s: AchievementStatsInput): Set<string> {
  const kinds = s.pets.map((p) => p.type);
  const unique = new Set(kinds);
  const maxLevel = s.pets.reduce((m, p) => Math.max(m, petLevelFromXp(p.xp ?? 0)), 0);
  const anyHatched = s.pets.length > 0;
  const cond: Record<string, boolean> = {
    first_egg: s.pets.length >= 1,
    first_hatch: anyHatched,
    first_adult: s.pets.some((p) => petStage(p) >= 3),
    first_session: s.totalMinutes >= 1,
    ten_sessions: s.totalMinutes >= 10,
    hour: s.totalMinutes >= 60,
    five_hours: s.totalMinutes >= 300,
    day_total: s.totalMinutes >= 1440,
    streak_3: s.streakDays >= 3,
    streak_7: s.streakDays >= 7,
    streak_30: s.streakDays >= 30,
    collect_3: s.pets.length >= 3,
    collect_5: s.pets.length >= 5,
    plants_lover: kinds.some(isPlant),
    sea_lover: kinds.some(isAquatic),
    zoo_10: unique.size >= 10,
    rich_100: s.coins >= 100,
    rich_500: s.coins >= 500,
    shopper: s.pets.some((p) => (p.frame ?? "none") !== "none"),
    level_5: maxLevel >= 5,
    level_10: maxLevel >= 10,
    diary_5: s.diaryCount >= 5,
    diary_20: s.diaryCount >= 20,
  };
  const out = new Set<string>();
  for (const a of ACHIEVEMENTS) if (cond[a.id]) out.add(a.id);
  return out;
}
