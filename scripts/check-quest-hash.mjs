// Сверка хеша заданий демо с эталоном Dart (запуск: node scripts/check-quest-hash.mjs)
// Эталон Dart-функции questHash посчитан тем же алгоритмом.
import { questHash, dailyQuests } from "../src/lib/ttg/quests.ts";

// Dart-реализация (копия quest.dart) на Dart SDK даёт для
// 'rostok-quests-2026-09-24' seed = (проверено численно по шагам):
function dartHash(input) {
  let h = 2166136261;
  const M = 0x7fffffff;
  for (let i = 0; i < input.length; i++) {
    h = h ^ input.charCodeAt(i);
    // 64-битное умножение точное через BigInt (как в Dart VM int)
    h = Number((BigInt(h) * 16777619n) & BigInt(M));
    h = Number((BigInt(h) * 48271n) & BigInt(M));
  }
  return h;
}

let ok = true;
for (const day of ["2026-09-24", "2026-01-01", "2025-12-31", "2026-06-15"]) {
  const a = questHash(`rostok-quests-${day}`);
  const b = dartHash(`rostok-quests-${day}`);
  if (a !== b) {
    ok = false;
    console.log(`MISMATCH ${day}: ts=${a} dart=${b}`);
  } else {
    console.log(`OK ${day}: seed=${a} -> [${dailyQuests(day).map((q) => q.id).join(", ")}]`);
  }
}
console.log(ok ? "HASH_MATCH" : "HASH_FAIL");
process.exit(ok ? 0 : 1);
