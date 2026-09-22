// ─────────────────────────────────────────────────────────────────────
// «Время Расти» — типы и константы. Порт lib/models + lib/core из
// Flutter-проекта v1.0.0 (1:1 логика).
// ─────────────────────────────────────────────────────────────────────

export type PetType = "fox" | "cat" | "owl" | "dragon";

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

export const PET_CATALOG: { name: string; type: PetType }[] = [
  { name: "Лисёнок", type: "fox" },
  { name: "Котик", type: "cat" },
  { name: "Совёнок", type: "owl" },
  { name: "Дракончик", type: "dragon" },
];

export const K_APP_VERSION = "1.0.0";
export const K_APP_BUILD_NUMBER = 1;
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
} as const;

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
  }
}

/** Цвет животика: body @ 35% поверх белого (аналог Color.alphaBlend). */
export function bellyColor(type: PetType): string {
  const hex = bodyColor(type).replace("#", "");
  const r = parseInt(hex.slice(0, 2), 16);
  const g = parseInt(hex.slice(2, 4), 16);
  const b = parseInt(hex.slice(4, 6), 16);
  const mix = (c: number) => Math.round(c * 0.35 + 255 * 0.65);
  const to = (n: number) => n.toString(16).padStart(2, "0");
  return `#${to(mix(r))}${to(mix(g))}${to(mix(b))}`;
}
