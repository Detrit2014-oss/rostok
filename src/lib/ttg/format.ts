// Порт lib/core/utils.dart + вспомогательные функции update/challenge.

const MONTHS_RU = [
  "января", "февраля", "марта", "апреля", "мая", "июня",
  "июля", "августа", "сентября", "октября", "ноября", "декабря",
];

export function formatRuDateTime(ms: number): string {
  const d = new Date(ms);
  const hh = String(d.getHours()).padStart(2, "0");
  const mm = String(d.getMinutes()).padStart(2, "0");
  return `${d.getDate()} ${MONTHS_RU[d.getMonth()]}, ${hh}:${mm}`;
}

export function formatDurationMinutes(minutes: number): string {
  if (minutes < 60) return `${minutes} мин`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m === 0 ? `${h} ч` : `${h} ч ${m} мин`;
}

export function formatTimer(totalSeconds: number): string {
  const h = Math.floor(totalSeconds / 3600);
  const m = Math.floor((totalSeconds % 3600) / 60);
  const s = totalSeconds % 60;
  const two = (v: number) => String(v).padStart(2, "0");
  return h > 0 ? `${h}:${two(m)}:${two(s)}` : `${two(m)}:${two(s)}`;
}

export function dayKey(d: Date): string {
  return `${d.year ?? d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

/** Понедельник 00:00 указанной даты (мс). */
export function mondayMs(d: Date): number {
  const day = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const wd = d.getDay() === 0 ? 7 : d.getDay(); // Пн=1..Вс=7
  day.setDate(day.getDate() - (wd - 1));
  return day.getTime();
}

/** >0 — a новее b; <0 — a старше b; 0 — равны. Формат: 1.2.10 */
export function compareVersions(a: string, b: string): number {
  const pa = a.split(".");
  const pb = b.split(".");
  const n = Math.max(pa.length, pb.length);
  for (let i = 0; i < n; i++) {
    const x = i < pa.length ? parseInt(pa[i], 10) || 0 : 0;
    const y = i < pb.length ? parseInt(pb[i], 10) || 0 : 0;
    if (x !== y) return x > y ? 1 : -1;
  }
  return 0;
}

export function nextVersion(current: string): string {
  const parts = current.split(".");
  const minor = parts.length > 1 ? parseInt(parts[1], 10) || 0 : 0;
  return `${parts[0]}.${minor + 1}.0`;
}

/** Детерминированный ПСЧ (mulberry32) — замена Random(seed) из Dart. */
export function seededRandom(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function stringHash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  }
  return h;
}
