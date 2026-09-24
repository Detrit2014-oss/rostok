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
  /** Растения (v1.9.0) выращены из семечка — без стадии «Яйцо». */
  fromSeed?: boolean;
  /** Гардероб (v1.9.0): hat: none|cap|beanie|crown; neck: none|scarf|bow;
   *  face: none|glasses|shades; skin: classic|golden|mint|rose. */
  hat?: string;
  neck?: string;
  face?: string;
  skin?: string;
  /** Уже забранные возрастные подарки (дни). */
  claimedAges?: number[];
}

/** Пороги стадий в минутах (v1.9.0): рост замедлен в 20 раз.
 *  Яйцо/семечко → 100 мин → малыш → 300 → подросток → 600 → взрослый. */
export const STAGE_THRESHOLDS = [0, 100, 300, 600] as const;

export function petStage(p: Pet): number {
  if (p.growthMinutes >= STAGE_THRESHOLDS[3]) return 3;
  if (p.growthMinutes >= STAGE_THRESHOLDS[2]) return 2;
  if (p.growthMinutes >= STAGE_THRESHOLDS[1]) return 1;
  return 0;
}

export const STAGE_NAMES = ["Яйцо", "Малыш", "Подросток", "Взрослый"];

/** У растений первая стадия — «Семечко», а не «Яйцо» (v1.9.0). */
export function stageName(p: Pet): string {
  const stage = petStage(p);
  if (stage === 0 && isPlant(p.type)) return "Семечко";
  return STAGE_NAMES[stage];
}

/** Полных дней питомца (v1.9.0). */
export function ageDays(p: Pet, nowMs?: number): number {
  const now = nowMs ?? Date.now();
  return Math.max(0, Math.floor((now - p.bornAt) / 86400000));
}

/** Возрастные вехи: день → подарок (монет + столько же XP). */
export const AGE_BONUSES: Record<number, number> = {
  1: 30,
  3: 60,
  7: 120,
  14: 250,
  30: 500,
  60: 900,
  100: 1500,
};

/** Вехи, которые уже можно забрать, но ещё не забрали. */
export function pendingAgeBonuses(p: Pet, nowMs?: number): number[] {
  const days = ageDays(p, nowMs);
  return Object.keys(AGE_BONUSES)
    .map(Number)
    .filter((d) => d <= days && !(p.claimedAges ?? []).includes(d))
    .sort((a, b) => a - b);
}

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

export const K_APP_VERSION = "2.3.0";
export const K_APP_BUILD_NUMBER = 12;
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

/** Таблица фирменных цветов видов (зеркало lib/data/species_style.dart).
 *  С v2.1.0 внешность — реалистичные спрайты (SPRITE_META), цвета
 *  используются для точек на яйце и акцентов интерфейса. */
export interface SpeciesStyle {
  body: string;
  belly?: string;
}

const SPECIES_STYLES: Record<PetType, SpeciesStyle> = {
  // ── Четвероногие ходоки ──
  fox: { body: "#FF9F45" },
  cat: { body: "#A8B8C8" },
  dragon: { body: "#62C46A", belly: "#D9F2DC" },
  bunny: { body: "#D9CFC4", belly: "#F7F1EA" },
  hedgehog: { body: "#C08552", belly: "#F0DCBE" },
  panda: { body: "#F2EEE4" },
  bear: { body: "#A9744F" },
  dog: { body: "#F2C078", belly: "#FBE8C8" },
  deer: { body: "#D9A06C", belly: "#F7E7D2" },
  squirrel: { body: "#C97B4A", belly: "#F4E3D2" },
  raccoon: { body: "#9AA3AC", belly: "#E5E9ED" },
  koala: { body: "#B5C4CE", belly: "#E9EFF3" },
  pig: { body: "#F5A8B8", belly: "#FDE3E9" },
  unicorn: { body: "#F3EAFB" },
  // ── Птицы ──
  owl: { body: "#A97FE0", belly: "#EFE3FB" },
  duck: { body: "#FFD24C" },
  chick: { body: "#FFD94C" },
  penguin: { body: "#56789A" },
  // ── Прыгуны ──
  frog: { body: "#7CC46B", belly: "#E2F4DC" },
  // ── Водные жители пруда ──
  seal: { body: "#B8C9D9", belly: "#E8EFF5" },
  whale: { body: "#5FA8D3", belly: "#DCEFF9" },
  turtle: { body: "#8FBF6A", belly: "#E5F0D5" },
  octopus: { body: "#D98AC2", belly: "#F7E4F0" },
  crab: { body: "#E86A5C", belly: "#F9DAD5" },
  // ── Растения на грядке ──
  cactus: { body: "#5FA052" },
  bonsai: { body: "#6FBF4E" },
  succulent: { body: "#9BC98F" },
  sunflower: { body: "#FFC800" },
  clover: { body: "#5FA052" },
  sprout: { body: "#7FC45C" },
};

export function speciesStyle(type: PetType): SpeciesStyle {
  return SPECIES_STYLES[type] ?? SPECIES_STYLES.fox;
}

// ── Гардероб (v1.9.0) ───────────────────────────────────────────────

export interface WardrobeItem {
  id: string;
  slot: "hat" | "neck" | "face";
  title: string;
  emoji: string;
  price: number;
  subtitle: string;
}

export const WARDROBE_CATALOG: WardrobeItem[] = [
  { id: "cap", slot: "hat", title: "Кепка", emoji: "🧢", price: 80, subtitle: "Спортивный стиль" },
  { id: "beanie", slot: "hat", title: "Шапочка", emoji: "🧶", price: 120, subtitle: "Тепло в холода" },
  { id: "crown", slot: "hat", title: "Корона", emoji: "👑", price: 400, subtitle: "Для особенных питомцев" },
  { id: "scarf", slot: "neck", title: "Шарф", emoji: "🧣", price: 100, subtitle: "В полосочку, тёплый" },
  { id: "bow", slot: "neck", title: "Бантик", emoji: "🎀", price: 90, subtitle: "Мило и нарядно" },
  { id: "glasses", slot: "face", title: "Очки", emoji: "👓", price: 150, subtitle: "Умный взгляд" },
  { id: "shades", slot: "face", title: "Тёмные очки", emoji: "🕶️", price: 200, subtitle: "Звезда лужайки" },
  // v2.1.0: окрасы заменены новыми аксессуарами (спрайт реалистичного
  // зверя нельзя перекрасить; купленные окрасы вернулись монетками).
  { id: "bandana", slot: "neck", title: "Бандана", emoji: "🔵", price: 450, subtitle: "Стиль настоящего путешественника" },
  { id: "bell", slot: "neck", title: "Колокольчик", emoji: "🔔", price: 300, subtitle: "Звенит от каждого шага" },
  { id: "flowerPin", slot: "hat", title: "Цветочек", emoji: "🌸", price: 280, subtitle: "Весенняя нежность" },
];

export const SLOT_TITLES: Record<string, string> = {
  hat: "Головные уборы",
  neck: "Шея",
  face: "Лицо",
};

/** hex → rgb-компоненты. */
function hexParts(hex: string): [number, number, number] {
  const h = hex.replace("#", "");
  return [
    parseInt(h.slice(0, 2), 16),
    parseInt(h.slice(2, 4), 16),
    parseInt(h.slice(4, 6), 16),
  ];
}

function toHex(n: number): string {
  return Math.round(Math.min(255, Math.max(0, n))).toString(16).padStart(2, "0");
}

/** Смесь двух цветов: a поверх b с альфой alpha (0..1). */
export function mixColors(base: string, overlay: string, alpha: number): string {
  const [r1, g1, b1] = hexParts(base);
  const [r2, g2, b2] = hexParts(overlay);
  const m = (c1: number, c2: number) => Math.round(c1 * (1 - alpha) + c2 * alpha);
  return `#${toHex(m(r1, r2))}${toHex(m(g1, g2))}${toHex(m(b1, b2))}`;
}

// ── Мультяшный движок v2.2.0 «Мультяшные звери» ─────────────────────
// Зеркало lib/data/cartoon.dart: спека 30 видов + геометрия сцены.
// Рисовальщик (canvas 2D) живёт в cartoon.ts — числа совпадают 1:1.

/** Спека вида: сборка тела, палитра, уши/хвост/морда, доп. детали. */
export interface CartoonSpec {
  build: "quad" | "bird" | "hop" | "pond" | "plant";
  /** Высота взрослого питомца как доля высоты сцены (240). */
  heightF: number;
  /** Отношение ширины к высоте бокса отрисовки. */
  aspect: number;
  body: string;
  belly: string;
  accent?: string;
  dark?: string;
  ear: string;
  tail: string;
  muzzle: string;
  extras: string[];
}

const spec = (
  build: CartoonSpec["build"],
  heightF: number,
  aspect: number,
  body: string,
  belly: string,
  extra: Partial<CartoonSpec> = {},
): CartoonSpec => ({
  build,
  heightF,
  aspect,
  body,
  belly,
  ear: extra.ear ?? "none",
  tail: extra.tail ?? "none",
  muzzle: extra.muzzle ?? "none",
  accent: extra.accent,
  dark: extra.dark,
  extras: extra.extras ?? [],
});

export const CARTOON: Record<PetType, CartoonSpec> = {
  fox: spec("quad", 0.165, 1.12, "#FF9F45", "#FFF3E2", { accent: "#E07B2A", ear: "pointy", tail: "bushy", muzzle: "fox" }),
  cat: spec("quad", 0.15, 1.12, "#A8B8C8", "#E8EEF4", { accent: "#FFB8C9", ear: "pointy", tail: "cat", muzzle: "cat" }),
  dog: spec("quad", 0.17, 1.15, "#F2C078", "#FBE8C8", { accent: "#C98850", ear: "floppy", tail: "long", muzzle: "bear" }),
  bear: spec("quad", 0.185, 1.1, "#A9744F", "#E8C9A8", { ear: "round", tail: "puff", muzzle: "bear" }),
  panda: spec("quad", 0.18, 1.1, "#F7F4EC", "#FCFAF4", { dark: "#3B3B44", ear: "round", tail: "puff", muzzle: "bear", extras: ["mask"] }),
  raccoon: spec("quad", 0.155, 1.2, "#9AA3AC", "#E5E9ED", { dark: "#4E5560", ear: "pointy", tail: "bushy", muzzle: "fox", extras: ["mask", "rings"] }),
  hedgehog: spec("quad", 0.125, 1.25, "#C08552", "#F0DCBE", { dark: "#8A6642", ear: "pointy", tail: "puff", muzzle: "fox", extras: ["spikesBack"] }),
  squirrel: spec("quad", 0.15, 1.2, "#C97B4A", "#F4E3D2", { accent: "#A85E34", ear: "tufts", tail: "bushy", muzzle: "fox" }),
  pig: spec("quad", 0.16, 1.15, "#F5A8B8", "#FDE3E9", { accent: "#E98CA1", ear: "floppy", tail: "curl", muzzle: "snout" }),
  koala: spec("quad", 0.155, 1.05, "#B5C4CE", "#E9EFF3", { accent: "#F7F1EA", ear: "round", muzzle: "flat" }),
  deer: spec("quad", 0.215, 1.2, "#D9A06C", "#F7E7D2", { accent: "#A87A4F", ear: "long", tail: "puff", muzzle: "long", extras: ["antlers", "spots"] }),
  unicorn: spec("quad", 0.215, 1.2, "#F3EAFB", "#FCF7FE", { accent: "#FF9FCE", ear: "long", tail: "mane", muzzle: "long", extras: ["horn", "mane"] }),
  dragon: spec("quad", 0.19, 1.4, "#62C46A", "#D9F2DC", { accent: "#4CA95A", ear: "pointy", tail: "long", muzzle: "cat", extras: ["wings", "spikesBack"] }),
  owl: spec("bird", 0.165, 0.65, "#A97FE0", "#EFE3FB", { accent: "#FFB84C", ear: "tufts", tail: "plume", muzzle: "beak" }),
  duck: spec("bird", 0.13, 0.65, "#FFD24C", "#FFE9A0", { accent: "#FF9F45", tail: "flat", muzzle: "beak" }),
  chick: spec("bird", 0.105, 0.6, "#FFD94C", "#FFE9A0", { accent: "#FF9F45", ear: "tuft", muzzle: "beak" }),
  penguin: spec("bird", 0.155, 0.65, "#56789A", "#F4F8FB", { accent: "#FFB84C", muzzle: "beak" }),
  bunny: spec("hop", 0.15, 0.78, "#D9CFC4", "#F7F1EA", { accent: "#FFB8C9", ear: "long", tail: "puff", muzzle: "flat" }),
  frog: spec("hop", 0.095, 1.43, "#7CC46B", "#E2F4DC", { accent: "#FF8FB1", muzzle: "wide" }),
  whale: spec("pond", 0.125, 2.8, "#5FA8D3", "#DCEFF9", { accent: "#4A8FB8", tail: "fluke", muzzle: "flat", extras: ["fin"] }),
  seal: spec("pond", 0.115, 2.4, "#B8C9D9", "#E8EFF5", { accent: "#8FA8BD", tail: "fluke", muzzle: "flat", extras: ["paddles"] }),
  turtle: spec("pond", 0.085, 2.2, "#8FBF6A", "#E5F0D5", { dark: "#5C9245", tail: "puff", muzzle: "flat", extras: ["shell"] }),
  octopus: spec("pond", 0.13, 1.35, "#D98AC2", "#F7E4F0", { accent: "#C06BA6", muzzle: "flat", extras: ["suckers"] }),
  crab: spec("pond", 0.075, 1.75, "#E86A5C", "#F9DAD5", { accent: "#C94F43", ear: "stalk", muzzle: "flat", extras: ["claws"] }),
  cactus: spec("plant", 0.155, 0.55, "#5FA052", "#7FB86E", { accent: "#FF8FB1", extras: ["flower", "arms"] }),
  bonsai: spec("plant", 0.2, 0.9, "#6FBF4E", "#8FCF6A", { accent: "#8A6642" }),
  succulent: spec("plant", 0.115, 0.6, "#9BC98F", "#B5D9A8", { accent: "#E8A8C8" }),
  sunflower: spec("plant", 0.205, 0.57, "#FFC800", "#8A5A32", { accent: "#5FA052" }),
  clover: spec("plant", 0.115, 0.74, "#5FA052", "#7FC45C", { accent: "#F7F1EA" }),
  sprout: spec("plant", 0.12, 0.53, "#7FC45C", "#9BD878", { accent: "#5FA052" }),
};

export function cartoonSpec(type: PetType): CartoonSpec {
  return (
    CARTOON[type] ?? {
      build: "quad", heightF: 0.16, aspect: 1.4,
      body: "#9BC98F", belly: "#E5F0D5",
      ear: "none", tail: "none", muzzle: "none", extras: [],
    }
  );
}

/** Стадии меняют только размер: малыш 55%, подросток 78%, взрослый 100%. */
export function cartoonStageScale(stage: number): number {
  return [0.55, 0.78, 1, 1][Math.max(0, Math.min(3, stage))];
}

/** Прыгуны: во время прогулки перескакивают, а не идут. */
export const HOP_PETS: PetType[] = ["bunny", "frog"];

/** Якорь рта (мини-игра): x от центра бокса вперёд, y от земли
 *  (вверх = отрицательный), в долях высоты h. Зеркало cartoonMouthLocal. */
export function cartoonMouthLocal(type: PetType, h: number): { x: number; y: number } {
  const s = cartoonSpec(type);
  switch (s.build) {
    case "bird":
      return { x: h * 0.18, y: -h * 0.66 };
    case "hop":
      return type === "frog"
        ? { x: h * 0.45, y: -h * 0.43 }
        : { x: h * 0.32, y: -h * 0.63 };
    case "pond":
      switch (type) {
        case "whale": return { x: h * 1.0, y: -h * 0.5 };
        case "seal": return { x: h * 1.05, y: -h * 0.48 };
        case "turtle": return { x: h * 1.05, y: -h * 0.33 };
        case "octopus": return { x: 0, y: -h * 0.54 };
        default: return { x: 0, y: -h * 0.4 };
      }
    case "plant":
      return { x: 0, y: -h * 0.85 };
    default:
      return { x: h * 0.5, y: -h * 0.66 };
  }
}

/** Геометрия сцены (зеркало SceneGeom): доли ширины 400 / высоты 240. */
export const GEOM = {
  groundYF: 0.74,
  pondCXF: 0.62,
  pondCYF: 0.765,
  pondRWF: 0.21,
  pondRHF: 0.058,
  bedX0F: 0.045,
  bedX1F: 0.335,
  bedYF: 0.845,
} as const;

/** Полосы прогулки зверей: y-линия и масштаб глубины.
 *  Все полосы НИЖЕ пруда — звери проходят перед ним, а не по воде. */
export function laneYs(n: number): number[] {
  if (n <= 1) return [0.935];
  return Array.from({ length: n }, (_, i) => 0.915 + (0.0675 * i) / (n - 1));
}

export function laneScales(n: number): number[] {
  if (n <= 1) return [1.05];
  return Array.from({ length: n }, (_, i) => 0.9 + (0.2 * i) / (n - 1));
}
