// ─────────────────────────────────────────────────────────────────────
// «Росток» — типы и константы. Порт lib/models + lib/core из
// Flutter-проекта (1:1 логика). С v1.3.0 зверята вылупляются из яиц,
// а растения вырастают из семечек.
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
  // v1.3.0: растения. Логично, что они не вылупляются из яйца —
  // они растут из семечка в горшочке (стадия 0 = «Семечко»).
  | "cactus"
  | "sunflower"
  | "clover"
  | "bonsai"
  | "fern"
  | "tulip";

const PLANT_TYPES = new Set<PetType>([
  "cactus",
  "sunflower",
  "clover",
  "bonsai",
  "fern",
  "tulip",
]);

/** Растение? Тогда вместо яйца — семечко в горшочке. */
export function isPlant(type: PetType): boolean {
  return PLANT_TYPES.has(type);
}

export interface Pet {
  id: string;
  name: string;
  type: PetType;
  bornAt: number;
  growthMinutes: number;
}

export const STAGE_THRESHOLDS = [0, 5, 15, 30] as const;

export function petStage(p: Pet): number {
  if (p.growthMinutes >= STAGE_THRESHOLDS[3]) return 3;
  if (p.growthMinutes >= STAGE_THRESHOLDS[2]) return 2;
  if (p.growthMinutes >= STAGE_THRESHOLDS[1]) return 1;
  return 0;
}

export const STAGE_NAMES = ["Яйцо", "Малыш", "Подросток", "Взрослый"];
export const PLANT_STAGE_NAMES = ["Семечко", "Росток", "Кустик", "Цветение"];

export function stageName(type: PetType, stage: number): string {
  const names = isPlant(type) ? PLANT_STAGE_NAMES : STAGE_NAMES;
  return names[stage] ?? STAGE_NAMES[stage];
}

export function stageEmoji(type: PetType, stage: number): string {
  const set = isPlant(type) ? ["🌰", "🌱", "🌿", "🌸"] : ["🥚", "🐥", "🐣", "🐾"];
  return set[stage] ?? set[0];
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
  {
    name: "Лисёнок",
    type: "fox",
    emoji: "🦊",
    desc: "Энергичный непоседа — любит быстрые прогулки",
    accusative: "Лисёнка",
  },
  {
    name: "Котик",
    type: "cat",
    emoji: "🐱",
    desc: "Спокойный и мягкий — ценит долгую тишину",
    accusative: "Котика",
  },
  {
    name: "Совёнок",
    type: "owl",
    emoji: "🦉",
    desc: "Мудрый хранитель тихих вечеров",
    accusative: "Совёнка",
  },
  {
    name: "Дракончик",
    type: "dragon",
    emoji: "🐲",
    desc: "Весёлый смельчак — растёт от каждой передышки",
    accusative: "Дракончика",
  },
  {
    name: "Утёнок",
    type: "duck",
    emoji: "🦆",
    desc: "Весёлый плескун — обожает тихие лужи и покой",
    accusative: "Утёнка",
  },
  {
    name: "Зайчик",
    type: "bunny",
    emoji: "🐰",
    desc: "Прыгучий сладкоежка — оживает на свежем воздухе",
    accusative: "Зайчика",
  },
  {
    name: "Пингвинёнок",
    type: "penguin",
    emoji: "🐧",
    desc: "Неуклюжий милаха — верный друг долгих пауз",
    accusative: "Пингвинёнка",
  },
  {
    name: "Ёжик",
    type: "hedgehog",
    emoji: "🦔",
    desc: "Колючий снаружи, добрый внутри — любит уединение",
    accusative: "Ёжика",
  },
  {
    name: "Панда",
    type: "panda",
    emoji: "🐼",
    desc: "Неторопливый философ — мастер спокойствия",
    accusative: "Панду",
  },
  {
    name: "Медвежонок",
    type: "bear",
    emoji: "🐻",
    desc: "Тёплый обнимашка — сладко спит, пока вы отдыхаете",
    accusative: "Медвежонка",
  },
  // v1.3.0: шесть горшечных растений — растут из семечка, не из яйца.
  {
    name: "Кактусёнок",
    type: "cactus",
    emoji: "🌵",
    desc: "Колючий философ — терпеливо растёт из семечка",
    accusative: "Кактусёнка",
  },
  {
    name: "Подсолнушек",
    type: "sunflower",
    emoji: "🌻",
    desc: "Яркий оптимист — тянется к солнцу вместе с вами",
    accusative: "Подсолнушка",
  },
  {
    name: "Клеверчик",
    type: "clover",
    emoji: "🍀",
    desc: "Приносит удачу тем, кто отдыхает от экрана",
    accusative: "Клеверчика",
  },
  {
    name: "Бонсайчик",
    type: "bonsai",
    emoji: "🎋",
    desc: "Мудрец в миниатюре — спокойствие в каждом листке",
    accusative: "Бонсайчика",
  },
  {
    name: "Папоротик",
    type: "fern",
    emoji: "🌿",
    desc: "Хранитель лесных тайн — любит тихие вечера",
    accusative: "Папоротика",
  },
  {
    name: "Тюльпанчик",
    type: "tulip",
    emoji: "🌷",
    desc: "Весеннее настроение — расцветает от вашей заботы",
    accusative: "Тюльпанчика",
  },
];

export const K_APP_VERSION = "1.3.0";
export const K_APP_BUILD_NUMBER = 4;
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
  // v1.3.0: растения
  cactus: "#4FA850",
  sunflower: "#FFB800",
  clover: "#4CB944",
  bonsai: "#6B9E4A",
  fern: "#2F8F5B",
  tulip: "#FF6B6B",
} as const;

/** Неизвестный вид (например, сохранение из более новой версии) — красим как лисёнка, чтобы не падать. */
const FALLBACK_COLOR = C.fox;

export function bodyColor(type: PetType): string {
  switch (type) {
    case "fox":
      return C.fox;
    case "cat":
      return C.cat;
    case "owl":
      return C.owl;
    case "dragon":
      return C.dragon;
    case "duck":
      return C.duck;
    case "bunny":
      return C.bunny;
    case "penguin":
      return C.penguin;
    case "hedgehog":
      return C.hedgehog;
    case "panda":
      return C.panda;
    case "bear":
      return C.bear;
    case "cactus":
      return C.cactus;
    case "sunflower":
      return C.sunflower;
    case "clover":
      return C.clover;
    case "bonsai":
      return C.bonsai;
    case "fern":
      return C.fern;
    case "tulip":
      return C.tulip;
    default:
      return FALLBACK_COLOR;
  }
}

/** Белый животик у пингвинёнка и панды, у остальных — смесь с белым. */
export function bellyColor(type: PetType): string {
  if (type === "penguin" || type === "panda") return "#FDFBF5";
  const hex = (bodyColor(type) ?? FALLBACK_COLOR).replace("#", "");
  const r = parseInt(hex.slice(0, 2), 16);
  const g = parseInt(hex.slice(2, 4), 16);
  const b = parseInt(hex.slice(4, 6), 16);
  const mix = (c: number) => Math.round(c * 0.35 + 255 * 0.65);
  const to = (n: number) => n.toString(16).padStart(2, "0");
  return `#${to(mix(r))}${to(mix(g))}${to(mix(b))}`;
}
