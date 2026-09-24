"use client";

// Порт lib/services/weather_service.dart (v1.7.0): Open-Meteo без ключа.
// Режим «auto» — пытаемся взять геолокацию браузера; иначе/при ошибке —
// детерминированная «погода по дате» (как в Flutter для веба).
// Режим «date» — всегда детерминированная (используется в сетке выбора).

import { useEffect } from "react";
import { useTTG } from "@/lib/ttg/store";

/** Детерминированная погода по ключу дня — как в Dart. */
export function deterministicWeather(dayKey: string): string {
  let h = 7;
  for (let i = 0; i < dayKey.length; i++) {
    h = (h * 31 + dayKey.charCodeAt(i)) & 0x7fffffff;
  }
  const wheel = [
    "clear",
    "clear",
    "partly",
    "partly",
    "cloudy",
    "rain",
    "snow",
    "fog",
    "thunder",
  ];
  return wheel[h % wheel.length];
}

/** Код WMO → состояние сцены (зеркало weatherFromWmo). */
export function weatherFromWmo(code: number): string {
  if (code === 0) return "clear";
  if (code === 1 || code === 2) return "partly";
  if (code === 3) return "cloudy";
  if (code === 45 || code === 48) return "fog";
  if (code >= 51 && code <= 67) return "rain";
  if (code >= 71 && code <= 77) return "snow";
  if (code >= 80 && code <= 82) return "rain";
  if (code === 85 || code === 86) return "snow";
  if (code >= 95) return "thunder";
  return "partly";
}

function dayKeyOf(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

/**
 * Следит за погодой. При mode="auto" один раз пробует геолокацию →
 * Open-Meteo; любые ошибки — fallback на погоду по дате.
 */
export function useWeather(): void {
  const mode = useTTG((s) => s.weatherMode);
  const setWeatherCondition = useTTG((s) => s.setWeatherCondition);
  const weatherCondition = useTTG((s) => s.weatherCondition);

  useEffect(() => {
    const day = dayKeyOf(new Date());
    if (mode === "date") {
      setWeatherCondition(deterministicWeather(day));
      return;
    }
    let cancelled = false;

    const fallback = () => {
      if (!cancelled) setWeatherCondition(deterministicWeather(day));
    };

    if (typeof navigator === "undefined" || !navigator.geolocation) {
      fallback();
      return;
    }

    navigator.geolocation.getCurrentPosition(
      async (pos) => {
        try {
          const url =
            "https://api.open-meteo.com/v1/forecast" +
            `?latitude=${pos.coords.latitude.toFixed(3)}` +
            `&longitude=${pos.coords.longitude.toFixed(3)}` +
            "&current=weather_code";
          const res = await fetch(url, { cache: "no-store" });
          if (!res.ok) throw new Error(`HTTP ${res.status}`);
          const data = (await res.json()) as {
            current?: { weather_code?: number };
          };
          const code = data.current?.weather_code ?? 0;
          if (!cancelled) setWeatherCondition(weatherFromWmo(code));
        } catch {
          fallback();
        }
      },
      () => fallback(),
      { timeout: 8000, maximumAge: 600000 }
    );

    return () => {
      cancelled = true;
    };
    // Погода обновляется при смене режима и раз при монтировании экрана.
  }, [mode, setWeatherCondition]);

  // Возвращаем ничего — состояние читается из стора; условие нужно, чтобы
  // линтер не ругался на неиспользуемую переменную.
  void weatherCondition;
}
