// ─────────────────────────────────────────────────────────────────────
// «Росток» — типы и константы. Порт lib/models + lib/core из
// Flutter-проекта v1.0.0 (1:1 логика).
// ─────────────────────────────────────────────────────────────────────

export type PetType =
  | "fox"
  | "cat"
  | "owl"
  | "dragon"
  | "duck"
  | "bunny"
  | "penguin"
  | "hedgehog"
  | "panda"
  | "bear"
  | "dog"
  | "deer"
  | "seal"
  | "whale"
  | "turtle"
  | "frog"
  | "squirrel"
  | "raccoon"
  | "koala"
  | "pig"
  | "chick"
  | "unicorn"
  | "octopus"
  | "crab"
  | "cactus"
  | "bonsai"
  | "succulent"
  | "sunflower"
  | "clover"
  | "sprout";

/** Водные жители — живут в пруду по центру сцены (v1.8.0). */
export const AQUATIC_PETS: readonly PetType[] = [
  "whale",
  "seal",
  "octopus",
  "crab",
  "turtle",
];

export function isAquatic(t: PetType): boolean {
  return AQUATIC_PETS.includes(t);
}

export const PLANT_PETS: readonly PetType[] = [
  "cactus",
  "bonsai",
  "succulent",
  "sunflower",
  "clover",
  "sprout",
];

export function isPlant(t: PetType): boolean {
  return PLANT_PETS.includes(t);
}

/** Пороги уровней XP (v1.5.0): уровень N+1 при xp >= XP_LEVELS[N]. */
export const XP_LEVELS = [0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700] as const;

export function petLevelFromXp(xp: number): number {
  let level = 1;
  for (let i = 0; i < XP_LEVELS.length; i++) {
    if (xp >= XP_LEVELS[i]) level = i + 1;
  }
  if (xp >= XP_LEVELS[XP_LEVELS.length - 1]) {
    level += Math.floor((xp - XP_LEVELS[XP_LEVELS.length - 1]) / 550);
  }
  return level;
}

export function petLevelProgress(xp: number): number {
  const level = petLevelFromXp(xp);
  if (level <= 1) return Math.min(1, Math.max(0, xp / 100));
  let prev: number;
  let next: number;
  if (level <= XP_LEVELS.length) {
    prev = XP_LEVELS[level - 2];
    next = XP_LEVELS[level - 1];
  } else {
    const base = XP_LEVELS[XP_LEVELS.length - 1] + (level - XP_LEVELS.length - 1) * 550;
    prev = base;
    next = base + 550;
  }
  return Math.min(1, Math.max(0, (xp - prev) / (next - prev)));
}

export interface Pet {
  id: string;
  name: string;
  type: PetType;
  bornAt: number;
  growthMinutes: number;
  /** Опыт питомца (v1.5.0): сессии, кормление, задания. */
  xp: number;
  /** Декоративная рамка из магазина: none|gold|neon|flower. */
  frame: string;
}

export const STAGE_THRESHOLDS = [0, 5, 15, 30] as const;

export function petStage(p: Pet): number {
  if (p.growthMinutes >= STAGE_THRESHOLDS[3]) return 3;
  if (p.growthMinutes >= STAGE_THRESHOLDS[2]) return 2;
  if (p.growthMinutes >= STAGE_THRESHOLDS[1]) return 1;
  return 0;
}

export const STAGE_NAMES = ["Яйцо", "Малыш", "Подросток", "Взрослый"];

export function stageProgress(p: Pet): number {
  const stage = petStage(p);
  if (stage >= 3) return 1;
  const next = STAGE_THRESHOLDS[stage + 1];
  const prev = STAGE_THRESHOLDS[stage];
  return Math.min(1, Math.max(0, (p.growthMinutes - prev) / (next - prev)));
}

export function minutesToNextStage(p: Pet): number {
  const stage = petStage(p);
  if (stage >= 3) return 0;
  return STAGE_THRESHOLDS[stage + 1] - p.growthMinutes;
}

export function isAdult(p: Pet): boolean {
  return petStage(p) >= 3;
}

export interface DiaryEntry {
  id: string;
  createdAt: number;
  text: string;
  moodScore: number; // -100..100
  tags: string[];
  aiReply: string;
  source: "local" | "llm";
}

export interface ChallengeParticipant {
  name: string;
  emoji: string;
  minutes: number;
  isUser: boolean;
}

export interface Challenge {
  id: string;
  title: string;
  goalHours: number;
  weekStartMs: number;
  isDemo: boolean;
  participants: ChallengeParticipant[];
}

export interface AppUpdateInfo {
  latest_version: string;
  min_supported_version?: string;
  notes?: string;
  force_update?: boolean;
  android_url?: string;
  ios_url?: string;
}

export interface LlmConfig {
  baseUrl: string;
  apiKey: string;
  model: string;
}

export const PET_CATALOG: {
  name: string;
  type: PetType;
  emoji: string;
  desc: string;
  accusative: string;
}[] = [
  { name: "Лисёнок", type: "fox", emoji: "🦊", desc: "Энергичный непоседа — любит быстрые прогулки", accusative: "Лисёнка" },
  { name: "Котик", type: "cat", emoji: "🐱", desc: "Спокойный и мягкий — ценит долгую тишину", accusative: "Котика" },
  { name: "Совёнок", type: "owl", emoji: "🦉", desc: "Мудрый хранитель тихих вечеров", accusative: "Совёнка" },
  { name: "Дракончик", type: "dragon", emoji: "🐲", desc: "Весёлый смельчак — растёт от каждой передышки", accusative: "Дракончика" },
  { name: "Утёнок", type: "duck", emoji: "🦆", desc: "Весёлый плескун — обожает тихие лужи и покой", accusative: "Утёнка" },
  { name: "Зайчик", type: "bunny", emoji: "🐰", desc: "Прыгучий сладкоежка — оживает на свежем воздухе", accusative: "Зайчика" },
  { name: "Пингвинёнок", type: "penguin", emoji: "🐧", desc: "Неуклюжий милаха — верный друг долгих пауз", accusative: "Пингвинёнка" },
  { name: "Ёжик", type: "hedgehog", emoji: "🦔", desc: "Колючий снаружи, добрый внутри — любит уединение", accusative: "Ёжика" },
  { name: "Панда", type: "panda", emoji: "🐼", desc: "Неторопливый философ — мастер спокойствия", accusative: "Панду" },
  { name: "Медвежонок", type: "bear", emoji: "🐻", desc: "Тёплый обнимашка — сладко спит, пока вы отдыхаете", accusative: "Медвежонка" },
  { name: "Щенок", type: "dog", emoji: "🐶", desc: "Верный товарищ — радуется каждой паузе", accusative: "Щенка" },
  { name: "Оленёнок", type: "deer", emoji: "🦌", desc: "Пугливый лесной житель — ценит тишину леса", accusative: "Оленёнка" },
  { name: "Тюлень", type: "seal", emoji: "🦭", desc: "Мягкий любитель дремать на солнышке", accusative: "Тюленя" },
  { name: "Кит", type: "whale", emoji: "🐳", desc: "Большой и добрый — в его волнах легко выдохнуть", accusative: "Кита" },
  { name: "Черепашка", type: "turtle", emoji: "🐢", desc: "Мудрая неторопливость — никуда не спешит", accusative: "Черепашку" },
  { name: "Лягушонок", type: "frog", emoji: "🐸", desc: "Прыгучий квакун — поёт вечерами у пруда", accusative: "Лягушонка" },
  { name: "Белочка", type: "squirrel", emoji: "🐿️", desc: "Запасливая хлопотунья — всё успевает", accusative: "Белочку" },
  { name: "Енот", type: "raccoon", emoji: "🦝", desc: "Любопытный исследователь — моет всё подряд", accusative: "Енота" },
  { name: "Коала", type: "koala", emoji: "🐨", desc: "Чемпион медленных объятий и сна", accusative: "Коалу" },
  { name: "Поросёнок", type: "pig", emoji: "🐷", desc: "Розовый оптимист — хрюкает от счастья", accusative: "Поросёнка" },
  { name: "Цыплёнок", type: "chick", emoji: "🐤", desc: "Маленький жёлтый комочек радости", accusative: "Цыплёнка" },
  { name: "Единорог", type: "unicorn", emoji: "🦄", desc: "Радужный мечтатель — верит в чудеса пауз", accusative: "Единорога" },
  { name: "Осьминожка", type: "octopus", emoji: "🐙", desc: "Восемь рук — и все тянутся к книгам", accusative: "Осьминожку" },
  { name: "Крабик", type: "crab", emoji: "🦀", desc: "Ходит боком, а думает — прямо", accusative: "Крабика" },
  { name: "Кактусик", type: "cactus", emoji: "🌵", desc: "Колючий стойкий друг — растёт даже в пустоте", accusative: "Кактусика" },
  { name: "Бонсайчик", type: "bonsai", emoji: "🎋", desc: "Маленькое дерево большой мудрости", accusative: "Бонсайчика" },
  { name: "Суккулентик", type: "succulent", emoji: "🪴", desc: "Пухлый хранитель воды и спокойствия", accusative: "Суккулентика" },
  { name: "Подсолнух", type: "sunflower", emoji: "🌻", desc: "Всегда поворачивается к свету", accusative: "Подсолнух" },
  { name: "Клеверок", type: "clover", emoji: "🍀", desc: "Приносит удачу тихим вечерам", accusative: "Клеверка" },
  { name: "Росточек", type: "sprout", emoji: "🌱", desc: "Самый первый друг — символ «Ростка»", accusative: "Росточек" },
];

export const K_APP_VERSION = "1.2.0";
export const K_APP_BUILD_NUMBER = 3;
export const K_DEFAULT_UPDATE_URL =
  "https://your-username.github.io/time-to-grow-updates/version.json";
export const K_UPDATE_CHECK_INTERVAL_HOURS = 6;

// Палитра Duolingo-стиля (lib/core/theme.dart)
export const C = {
  bg: "#FFFDF7",
  card: "#FFFFFF",
  border: "#E8E8E8",
  green: "#4CB944",
  greenDark: "#379630",
  greenSoft: "#E4F6E2",
  blue: "#1CB0F6",
  blueDark: "#1899D6",
  yellow: "#FFC800",
  yellowDark: "#E0A800",
  orange: "#FF9600",
  coral: "#FF6B6B",
  coralDark: "#E14C4C",
  purple: "#A560E8",
  ink: "#3C3C3C",
  inkSoft: "#8F8F8F",
  skyTop: "#A6E4FF",
  skyBottom: "#EAF9E0",
  grass: "#90D26D",
  grassDark: "#6FBF4E",
  fox: "#FF9F45",
  cat: "#A8B8C8",
  owl: "#A97FE0",
  dragon: "#62C46A",
  duck: "#FFD24C",
  bunny: "#D9CFC4",
  penguin: "#56789A",
  hedgehog: "#C08552",
  panda: "#F2EEE4",
  bear: "#A9744F",
} as const;

export function bodyColor(type: PetType): string {
  return speciesStyle(type).body;
}

/** Животик: задан явно или смесь body с белым (как в Flutter). */
export function bellyColor(type: PetType): string {
  const st = speciesStyle(type);
  if (st.belly) return st.belly;
  const hex = st.body.replace("#", "");
  const r = parseInt(hex.slice(0, 2), 16);
  const g = parseInt(hex.slice(2, 4), 16);
  const b = parseInt(hex.slice(4, 6), 16);
  const mix = (c: number) => Math.round(c * 0.35 + 255 * 0.65);
  const to = (n: number) => n.toString(16).padStart(2, "0");
  return `#${to(mix(r))}${to(mix(g))}${to(mix(b))}`;
}

/** Таблица внешности видов (зеркало lib/data/species_style.dart). */
export interface SpeciesStyle {
  body: string;
  belly?: string;
  ear?: "none" | "triangle" | "round" | "long" | "tuft" | "horns" | "pom" | "crest";
  tail?: "none" | "bushy" | "thin" | "curl" | "puff";
  muzzle?:
    | "smile"
    | "beak"
    | "duckBeak"
    | "bearMuzzle"
    | "buckteeth"
    | "whaleMouth"
    | "topEyes"
    | "snout";
  extra?:
    | "none"
    | "spikes"
    | "patches"
    | "shell"
    | "wings"
    | "mask"
    | "mane"
    | "spots"
    | "claws"
    | "tentacles";
  whiteBelly?: boolean;
}

const SPECIES_STYLES: Record<PetType, SpeciesStyle> = {
  fox: { body: "#FF9F45", ear: "triangle", tail: "bushy", extra: "spots" },
  cat: { body: "#A8B8C8", ear: "triangle", tail: "thin" },
  owl: { body: "#A97FE0", belly: "#EFE3FB", ear: "tuft", muzzle: "beak" },
  dragon: { body: "#62C46A", belly: "#D9F2DC", ear: "horns", extra: "wings" },
  duck: { body: "#FFD24C", ear: "tuft", muzzle: "duckBeak" },
  bunny: { body: "#D9CFC4", belly: "#F7F1EA", ear: "long", muzzle: "buckteeth" },
  penguin: { body: "#56789A", muzzle: "beak", whiteBelly: true },
  hedgehog: { body: "#C08552", belly: "#F0DCBE", ear: "round", extra: "spikes" },
  panda: { body: "#F2EEE4", ear: "pom", extra: "patches", whiteBelly: true },
  bear: { body: "#A9744F", ear: "round", muzzle: "bearMuzzle" },
  dog: { body: "#F2C078", belly: "#FBE8C8", ear: "triangle", tail: "bushy", muzzle: "bearMuzzle" },
  deer: { body: "#D9A06C", belly: "#F7E7D2", ear: "round", muzzle: "smile" },
  seal: { body: "#B8C9D9", belly: "#E8EFF5", muzzle: "smile" },
  whale: { body: "#5FA8D3", belly: "#DCEFF9", muzzle: "whaleMouth" },
  turtle: { body: "#8FBF6A", belly: "#E5F0D5", extra: "shell" },
  frog: { body: "#7CC46B", belly: "#E2F4DC", muzzle: "topEyes" },
  squirrel: { body: "#C97B4A", belly: "#F4E3D2", ear: "tuft", tail: "bushy" },
  raccoon: { body: "#9AA3AC", belly: "#E5E9ED", ear: "triangle", extra: "mask" },
  koala: { body: "#B5C4CE", belly: "#E9EFF3", ear: "pom", muzzle: "bearMuzzle" },
  pig: { body: "#F5A8B8", belly: "#FDE3E9", ear: "triangle", tail: "curl", muzzle: "snout" },
  chick: { body: "#FFD94C", ear: "tuft", muzzle: "beak" },
  unicorn: { body: "#F3EAFB", ear: "triangle", extra: "mane", whiteBelly: true },
  octopus: { body: "#D98AC2", belly: "#F7E4F0", extra: "tentacles" },
  crab: { body: "#E86A5C", belly: "#F9DAD5", extra: "claws" },
  cactus: { body: "#5FA052" },
  bonsai: { body: "#6FBF4E", belly: "#CB7B4E" },
  succulent: { body: "#9BC98F", belly: "#CB7B4E" },
  sunflower: { body: "#FFC800", belly: "#CB7B4E" },
  clover: { body: "#5FA052", belly: "#CB7B4E" },
  sprout: { body: "#7FC45C", belly: "#CB7B4E" },
};

export function speciesStyle(type: PetType): SpeciesStyle {
  return SPECIES_STYLES[type] ?? SPECIES_STYLES.fox;
}
