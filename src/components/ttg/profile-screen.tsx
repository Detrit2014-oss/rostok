"use client";

// Порт lib/screens/profile_screen.dart: статистика, настройки обновлений,
// настройка LLM, машина времени ×60 и сброс прогресса.

import { useTTG, adultCount } from "@/lib/ttg/store";
import {
  C,
  K_APP_BUILD_NUMBER,
  K_DEFAULT_UPDATE_URL,
} from "@/lib/ttg/types";
import { formatDurationMinutes } from "@/lib/ttg/format";
import { InfoCard, OutlineButton, StatTile } from "./widgets";
import {
  Clock,
  Coins,
  Flame,
  Link2,
  NotebookPen,
  PawPrint,
  Bot,
  Timer,
  Trash2,
  Download,
} from "lucide-react";
import { useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Switch } from "@/components/ui/switch";
import { toast } from "sonner";

import {
  ACHIEVEMENTS,
  type AchievementStatsInput,
  computeUnlocked,
} from "@/lib/ttg/achievements";
import { POSTCARDS, postcardUnlocked } from "@/lib/ttg/quests";
import { useWeather, deterministicWeather } from "@/lib/ttg/use-weather";
import { useMemo } from "react";

function AchievementsCard() {
  const pets = useTTG((s) => s.pets);
  const totalMinutes = useTTG((s) => s.totalMinutes);
  const streakDays = useTTG((s) => s.streakDays);
  const coins = useTTG((s) => s.coins);
  const diaryCount = useTTG((s) => s.diaryEntries.length);

  const stats: AchievementStatsInput = { pets, totalMinutes, streakDays, coins, diaryCount };
  const unlocked = useMemo(() => computeUnlocked(stats), [pets, totalMinutes, streakDays, coins, diaryCount]);

  return (
    <InfoCard className="mt-4">
      <div className="flex items-center">
        <p className="flex-1 text-[16px] font-extrabold" style={{ color: C.ink }}>
          Достижения
        </p>
        <p className="text-[12.5px] font-bold" style={{ color: C.inkSoft }}>
          {unlocked.size}/{ACHIEVEMENTS.length}
        </p>
      </div>
      <p className="mt-1 text-[12.5px] leading-snug" style={{ color: C.inkSoft }}>
        Открываются сами: за серию, питомцев, уровень и дневник.
      </p>
      <div className="mt-2.5 flex flex-wrap gap-2">
        {ACHIEVEMENTS.map((a) => {
          const on = unlocked.has(a.id);
          return (
            <span
              key={a.id}
              title={on ? `${a.title} — ${a.desc}` : `${a.title} — ещё не открыто`}
              className="flex h-[44px] w-[44px] items-center justify-center rounded-xl border-2 text-[20px]"
              style={{
                opacity: on ? 1 : 0.32,
                backgroundColor: on ? C.greenSoft : "#F2F2F2",
                borderColor: on ? C.green : C.border,
              }}
            >
              {a.emoji}
            </span>
          );
        })}
      </div>
    </InfoCard>
  );
}

function PostcardsCard() {
  const pets = useTTG((s) => s.pets);
  const totalMinutes = useTTG((s) => s.totalMinutes);
  const streakDays = useTTG((s) => s.streakDays);
  const coins = useTTG((s) => s.coins);
  const diaryCount = useTTG((s) => s.diaryEntries.length);
  const questsDoneTotal = useTTG((s) => s.questsDoneTotal);

  const st = { pets, totalMinutes, streakDays, coins, questsDone: questsDoneTotal, diaryCount };
  const unlockedCount = POSTCARDS.filter((pc) => postcardUnlocked(pc.id, st)).length;

  return (
    <InfoCard className="mt-4">
      <div className="flex items-center">
        <p className="flex-1 text-[16px] font-extrabold" style={{ color: C.ink }}>
          Открытки
        </p>
        <p className="text-[12.5px] font-bold" style={{ color: C.inkSoft }}>
          {unlockedCount}/{POSTCARDS.length}
        </p>
      </div>
      <div className="mt-2.5 flex flex-wrap gap-2">
        {POSTCARDS.map((pc) => {
          const on = postcardUnlocked(pc.id, st);
          return (
            <div
              key={pc.id}
              title={`${pc.title} — ${pc.howTo}`}
              className="flex h-[62px] w-[52px] flex-col items-center justify-center rounded-[10px] border-2"
              style={{
                opacity: on ? 1 : 0.32,
                backgroundColor: on ? "#FFFFFF" : "#F4F4F4",
                borderColor: on ? C.green : C.border,
              }}
            >
              <span className="text-[22px]">{pc.emoji}</span>
              <span className="px-0.5 text-center text-[7.5px] leading-tight" style={{ color: C.ink }}>
                {pc.title}
              </span>
            </div>
          );
        })}
      </div>
    </InfoCard>
  );
}

const WEATHER_LABELS: Record<string, string> = {
  clear: "Ясно",
  partly: "Переменная облачность",
  cloudy: "Облачно",
  fog: "Туман",
  rain: "Дождь",
  snow: "Снег",
  thunder: "Гроза",
};

const WEATHER_EMOJI: Record<string, string> = {
  clear: "☀️",
  partly: "⛅",
  cloudy: "☁️",
  fog: "🌫️",
  rain: "🌧️",
  snow: "❄️",
  thunder: "⛈️",
};

function WeatherCard() {
  const weatherMode = useTTG((s) => s.weatherMode);
  const weatherCondition = useTTG((s) => s.weatherCondition);
  const setWeatherMode = useTTG((s) => s.setWeatherMode);

  // Подтягиваем реальную погоду в режиме «Авто».
  useWeather();
  const shown = weatherMode === "date"
    ? deterministicWeather(dayKeyToday())
    : weatherCondition;

  return (
    <InfoCard className="mt-4">
      <p className="text-[16px] font-extrabold" style={{ color: C.ink }}>
        Погода в мире
      </p>
      <p className="mt-1 text-[13.5px]" style={{ color: C.ink }}>
        {WEATHER_EMOJI[shown] ?? "☀️"} {WEATHER_LABELS[shown] ?? "Ясно"}
      </p>
      <p className="mt-0.5 text-[11.5px]" style={{ color: C.inkSoft }}>
        В режиме «Авто» сцена питомца повторяет погоду за окном (Open-Meteo).
      </p>
      <div className="mt-2 flex gap-2">
        {(["auto", "date"] as const).map((m) => (
          <button
            key={m}
            type="button"
            onClick={() => setWeatherMode(m)}
            className="rounded-full px-3.5 py-1.5 text-[12.5px] font-extrabold"
            style={{
              backgroundColor: weatherMode === m ? C.green : "#FFFFFF",
              color: weatherMode === m ? "#FFFFFF" : C.inkSoft,
              border: `2px solid ${weatherMode === m ? C.greenDark : C.border}`,
            }}
          >
            {m === "auto" ? "Авто (GPS)" : "По дате"}
          </button>
        ))}
      </div>
    </InfoCard>
  );
}

function dayKeyToday(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

export function ProfileScreen() {
  const totalMinutes = useTTG((s) => s.totalMinutes);
  const streakDays = useTTG((s) => s.streakDays);
  const pets = useTTG((s) => s.pets);
  const coins = useTTG((s) => s.coins);
  const diaryCount = useTTG((s) => s.diaryEntries.length);
  const focusTimeMachine = useTTG((s) => s.timeMachine);
  const setTimeMachine = useTTG((s) => s.setTimeMachine);
  const simulateUpdate = useTTG((s) => s.simulateUpdate);
  const customUrl = useTTG((s) => s.customUpdateUrl);
  const checking = useTTG((s) => s.updateChecking);
  const appVersion = useTTG((s) => s.appVersion);
  const setSimulateUpdate = useTTG((s) => s.setSimulateUpdate);
  const setCustomUpdateUrl = useTTG((s) => s.setCustomUpdateUrl);
  const checkForUpdates = useTTG((s) => s.checkForUpdates);
  const llm = useTTG((s) => s.llm);
  const setLlmConfig = useTTG((s) => s.setLlmConfig);
  const resetAll = useTTG((s) => s.resetAll);

  const [urlOpen, setUrlOpen] = useState(false);
  const [urlValue, setUrlValue] = useState("");
  const [llmOpen, setLlmOpen] = useState(false);
  const [baseUrl, setBaseUrl] = useState(llm.baseUrl);
  const [model, setModel] = useState(llm.model);
  const [apiKey, setApiKey] = useState(llm.apiKey);
  const [resetOpen, setResetOpen] = useState(false);

  const checkUpdates = async () => {
    const result = await checkForUpdates();
    if (result === "simulated") {
      toast("Демо-режим: баннер обновления показан сверху");
    } else if (result === "available") {
      const v = useTTG.getState().availableUpdate?.latest_version;
      toast(`Доступна версия ${v}`);
    } else if (result === "error") {
      toast.error(useTTG.getState().updateLastError ?? "Ошибка проверки");
    } else {
      toast(`У вас последняя версия ${useTTG.getState().appVersion}`);
    }
  };

  return (
    <div className="h-full overflow-y-auto bg-[#FFFDF7] px-4 pb-8 pt-2">
      <div className="grid grid-cols-2 gap-3">
        <StatTile
          icon={Clock}
          value={formatDurationMinutes(totalMinutes)}
          label="вне телефона всего"
        />
        <StatTile
          icon={Flame}
          value={`${streakDays}`}
          label="дней серии"
          color={C.orange}
        />
        <StatTile
          icon={Coins}
          value={`${coins}`}
          label="монеток 🪙"
          color={C.yellowDark}
        />
        <StatTile
          icon={PawPrint}
          value={`${adultCount(pets)}`}
          label="взрослых питомцев"
          color={C.purple}
        />
        <StatTile
          icon={NotebookPen}
          value={`${diaryCount}`}
          label="записей в дневнике"
          color={C.blue}
        />
      </div>

      {/* Достижения (v1.5.0) */}
      <AchievementsCard />

      {/* Открытки (v1.7.0) */}
      <PostcardsCard />

      {/* Погода в мире (v1.7.0) */}
      <WeatherCard />

      {/* Обновления */}
      <InfoCard className="mt-4">
        <p className="text-[16px] font-extrabold" style={{ color: C.ink }}>
          Обновления
        </p>
        <p className="mt-1 text-[13px]" style={{ color: C.inkSoft }}>
          Версия {appVersion} (сборка {K_APP_BUILD_NUMBER})
        </p>
        <div className="mt-2.5">
          <OutlineButton
            label={checking ? "Проверяем…" : "Проверить обновления"}
            icon={Download}
            onClick={checkUpdates}
          />
        </div>
        <label className="mt-3 flex cursor-pointer items-center justify-between gap-3">
          <span>
            <span className="block text-[14.5px] font-semibold" style={{ color: C.ink }}>
              Симулировать обновление
            </span>
            <span className="block text-[12.5px]" style={{ color: C.inkSoft }}>
              Демо: показать баннер без сервера
            </span>
          </span>
          <Switch
            checked={simulateUpdate}
            onCheckedChange={(v) => setSimulateUpdate(v)}
            style={{ backgroundColor: simulateUpdate ? C.green : undefined }}
          />
        </label>
        <button
          type="button"
          onClick={() => {
            setUrlValue(customUrl);
            setUrlOpen(true);
          }}
          className="mt-3 flex w-full items-center gap-2 text-left"
        >
          <Link2 size={20} style={{ color: C.inkSoft }} />
          <span className="min-w-0">
            <span className="block text-[14.5px] font-semibold" style={{ color: C.ink }}>
              URL проверки обновлений
            </span>
            <span className="block truncate text-[12.5px]" style={{ color: C.inkSoft }}>
              {customUrl || "по умолчанию — из кода приложения"}
            </span>
          </span>
        </button>
      </InfoCard>

      {/* Настройки */}
      <InfoCard className="mt-4">
        <p className="text-[16px] font-extrabold" style={{ color: C.ink }}>
          Настройки
        </p>
        <button
          type="button"
          onClick={() => {
            setBaseUrl(llm.baseUrl);
            setModel(llm.model);
            setApiKey(llm.apiKey);
            setLlmOpen(true);
          }}
          className="mt-2 flex w-full items-center gap-2 text-left"
        >
          <Bot size={20} style={{ color: C.purple }} />
          <span>
            <span className="block text-[14.5px] font-semibold" style={{ color: C.ink }}>
              ИИ-дневник (LLM)
            </span>
            <span className="block text-[12.5px]" style={{ color: C.inkSoft }}>
              {llm.apiKey.trim()
                ? `Подключена модель: ${llm.model}`
                : "Не настроено — работает офлайн-анализ"}
            </span>
          </span>
        </button>
        <label className="mt-3 flex cursor-pointer items-center justify-between gap-3">
          <span>
            <span className="block text-[14.5px] font-semibold" style={{ color: C.ink }}>
              Машина времени ×60
            </span>
            <span className="block text-[12.5px]" style={{ color: C.inkSoft }}>
              1 сек = 1 мин, считает всё время (обходит экранный учёт) — для быстрого теста
            </span>
          </span>
          <Switch
            checked={focusTimeMachine}
            onCheckedChange={(v) => setTimeMachine(v)}
            style={{ backgroundColor: focusTimeMachine ? C.green : undefined }}
          />
        </label>
        <button
          type="button"
          onClick={() => setResetOpen(true)}
          className="mt-3 flex w-full items-center gap-2 text-left"
        >
          <Trash2 size={20} style={{ color: C.coral }} />
          <span className="text-[14.5px] font-semibold" style={{ color: C.coral }}>
            Сбросить прогресс
          </span>
        </button>
      </InfoCard>

      {/* О приложении */}
      <InfoCard className="mt-4">
        <p className="text-[16px] font-extrabold" style={{ color: C.ink }}>
          О приложении
        </p>
        <p className="mt-1.5 text-[13.5px] leading-relaxed" style={{ color: C.inkSoft }}>
          «Росток» — цифровая гигиена в игровой форме: откладываете телефон
          — растёт питомец, вечером ведёте дневник с ИИ-садовником, а в
          челленджах соревнуетесь с друзьями по часам цифрового детокса.
        </p>
        <p className="mt-2 text-[12.5px] leading-relaxed" style={{ color: C.inkSoft }}>
          С v1.1.0 рост привязан к экранному времени: засчитываются только минуты
          с погашенным экраном (в демо — время со скрытой вкладкой), а питомец
          выбирается на большом экране выбора. С v1.2.0 видов питомцев стало
          десять, а яйцо выросло и трескается перед вылуплением. Это
          веб-демонстратор Flutter-приложения v1.2.0: вся логика перенесена 1:1.{" "}
          <a
            href="/time_to_grow_v1.2.0.zip"
            download
            className="font-bold underline"
            style={{ color: C.blue }}
          >
            Скачать исходники Flutter (zip)
          </a>
          . Подсказка: в демо доступен свой файл обновлений — укажите URL{" "}
          <span className="font-mono">/version.json</span> и нажмите «Проверить
          обновления».
        </p>
      </InfoCard>

      {/* Диалог URL */}
      <Dialog open={urlOpen} onOpenChange={setUrlOpen}>
        <DialogContent className="max-w-[360px] rounded-3xl" aria-describedby={undefined}>
          <DialogHeader>
            <DialogTitle className="text-lg font-extrabold">
              URL проверки обновлений
            </DialogTitle>
          </DialogHeader>
          <input
            value={urlValue}
            onChange={(e) => setUrlValue(e.target.value)}
            placeholder="https://…/version.json"
            className="w-full rounded-2xl border-2 px-4 py-3 text-[15px] outline-none"
            style={{ borderColor: C.border, color: C.ink }}
          />
          <p className="text-[12.5px]" style={{ color: C.inkSoft }}>
            Например, файл на GitHub Pages. Пусто — использовать URL из кода
            ({K_DEFAULT_UPDATE_URL}). В демо можно ввести{" "}
            <span className="font-mono">/version.json</span>.
          </p>
          <div className="flex justify-end gap-4">
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.inkSoft }}
              onClick={() => setUrlOpen(false)}
            >
              Отмена
            </button>
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.green }}
              onClick={() => {
                setCustomUpdateUrl(urlValue.trim());
                setUrlOpen(false);
                toast("URL сохранён");
              }}
            >
              Сохранить
            </button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Диалог LLM */}
      <Dialog open={llmOpen} onOpenChange={setLlmOpen}>
        <DialogContent className="max-w-[380px] rounded-3xl" aria-describedby={undefined}>
          <DialogHeader>
            <DialogTitle className="text-lg font-extrabold">
              ИИ-дневник (LLM)
            </DialogTitle>
          </DialogHeader>
          <p className="text-[13px]" style={{ color: C.inkSoft }}>
            Подойдёт любой API, совместимый с OpenAI: OpenAI, OpenRouter, Groq
            или ваш прокси. В веб-демо запрос идёт через серверный прокси, поэтому
            CORS не мешает.
          </p>
          <label className="block text-[12.5px] font-semibold" style={{ color: C.inkSoft }}>
            Base URL
            <input
              value={baseUrl}
              onChange={(e) => setBaseUrl(e.target.value)}
              className="mt-1 w-full rounded-2xl border-2 px-4 py-2.5 text-[15px] font-normal outline-none"
              style={{ borderColor: C.border, color: C.ink }}
            />
          </label>
          <label className="block text-[12.5px] font-semibold" style={{ color: C.inkSoft }}>
            Модель (например, gpt-4o-mini)
            <input
              value={model}
              onChange={(e) => setModel(e.target.value)}
              className="mt-1 w-full rounded-2xl border-2 px-4 py-2.5 text-[15px] font-normal outline-none"
              style={{ borderColor: C.border, color: C.ink }}
            />
          </label>
          <label className="block text-[12.5px] font-semibold" style={{ color: C.inkSoft }}>
            API-ключ
            <input
              type="password"
              value={apiKey}
              onChange={(e) => setApiKey(e.target.value)}
              className="mt-1 w-full rounded-2xl border-2 px-4 py-2.5 text-[15px] font-normal outline-none"
              style={{ borderColor: C.border, color: C.ink }}
            />
          </label>
          <p className="text-[12px]" style={{ color: C.inkSoft }}>
            Ключ хранится только в этом браузере (localStorage) и на сервер не
            сохраняется.
          </p>
          <div className="flex justify-end gap-4">
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.inkSoft }}
              onClick={() => setLlmOpen(false)}
            >
              Отмена
            </button>
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.green }}
              onClick={() => {
                setLlmConfig({ baseUrl, apiKey, model });
                setLlmOpen(false);
                toast(
                  apiKey.trim()
                    ? `LLM подключён: ${model.trim() || "gpt-4o-mini"}`
                    : "LLM не настроен — работает офлайн-анализ"
                );
              }}
            >
              Сохранить
            </button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Диалог сброса */}
      <Dialog open={resetOpen} onOpenChange={setResetOpen}>
        <DialogContent className="max-w-[340px] rounded-3xl" aria-describedby={undefined}>
          <DialogHeader>
            <DialogTitle className="text-lg font-extrabold">
              Сбросить весь прогресс?
            </DialogTitle>
          </DialogHeader>
          <p className="text-[14px]" style={{ color: C.ink }}>
            Питомцы, дневник и статистика будут удалены безвозвратно.
          </p>
          <div className="flex justify-end gap-4">
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.inkSoft }}
              onClick={() => setResetOpen(false)}
            >
              Отмена
            </button>
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.coral }}
              onClick={() => {
                resetAll();
                setResetOpen(false);
                toast("Прогресс сброшен — выберите нового питомца 🐣");
              }}
            >
              Сбросить
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
