"use client";

// Порт lib/screens/diary_screen.dart: вечерний дневник настроения,
// шторка с ответом ИИ-садовника, «печатающийся» текст.

import { useTTG } from "@/lib/ttg/store";
import { C, DiaryEntry } from "@/lib/ttg/types";
import { formatRuDateTime } from "@/lib/ttg/format";
import { BigButton, InfoCard } from "./widgets";
import {
  Angry,
  Frown,
  Laugh,
  Meh,
  Mic,
  Moon,
  Smile,
  Sparkles,
  Sprout,
} from "lucide-react";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { createElement, useEffect, useState } from "react";
import { toast } from "sonner";

const K_DIARY_SYSTEM_PROMPT =
  "Ты — тёплый и заботливый ИИ-садовник приложения «Время Расти» " +
  "о цифровой гигиене и ментальном здоровье. Пользователь вечером пишет " +
  "короткую заметку о своём дне. Ответь на русском: 2–4 предложения. " +
  "Поддержи человека, мягко отрази его чувства без осуждения и дай одну " +
  "практичную рекомендацию для улучшения сна или снижения стресса. " +
  "Без диагнозов, без канцелярита, обращение на «вы».";

function moodIcon(score: number) {
  if (score >= 40) return Laugh;
  if (score >= 10) return Smile;
  if (score > -30) return Meh;
  if (score > -60) return Frown;
  return Angry;
}

function moodColor(score: number): string {
  if (score >= 40) return C.green;
  if (score >= 10) return C.grass;
  if (score > -30) return C.yellowDark;
  if (score > -60) return C.orange;
  return C.coral;
}

/** Иконка настроения (createElement — чтобы не создавать компонент в рендере). */
function MoodGlyph({ score, size = 22 }: { score: number; size?: number }) {
  return createElement(moodIcon(score), {
    size,
    style: { color: moodColor(score) },
  });
}

/** Вызов LLM через наш серверный прокси (обход CORS, ключ не хранится). */
async function llmDiaryReply(
  text: string,
  cfg: { baseUrl: string; apiKey: string; model: string }
): Promise<string | null> {
  if (!cfg.apiKey.trim()) return null;
  try {
    const res = await fetch("/api/llm", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        baseUrl: cfg.baseUrl,
        apiKey: cfg.apiKey,
        model: cfg.model,
        messages: [
          { role: "system", content: K_DIARY_SYSTEM_PROMPT },
          { role: "user", content: text },
        ],
      }),
    });
    const data = await res.json();
    if (data?.ok && typeof data.content === "string" && data.content.trim()) {
      return data.content;
    }
    return null;
  } catch {
    return null;
  }
}

export function DiaryScreen() {
  const entries = useTTG((s) => s.diaryEntries);
  const llm = useTTG((s) => s.llm);
  const addDiaryEntry = useTTG((s) => s.addDiaryEntry);
  const applyLlmReply = useTTG((s) => s.applyLlmReply);

  const [text, setText] = useState("");
  const [openEntryId, setOpenEntryId] = useState<string | null>(null);
  const [thinking, setThinking] = useState(false);
  const openEntry = entries.find((e) => e.id === openEntryId) ?? null;
  const llmConfigured = llm.apiKey.trim().length > 0;

  const save = () => {
    const t = text.trim();
    if (!t) return;
    setText("");
    const entry = addDiaryEntry(t);
    setOpenEntryId(entry.id);
    if (llmConfigured) {
      setThinking(true);
      llmDiaryReply(t, llm).then((reply) => {
        setThinking(false);
        if (reply) {
          applyLlmReply(entry.id, reply.trim());
        } else {
          toast("LLM недоступен — показан офлайн-анализ");
        }
      });
    }
  };

  return (
    <div className="flex h-full flex-col bg-[#FFFDF7]">
      <div className="flex-1 overflow-y-auto px-4 pb-3 pt-2">
        {entries.length === 0 ? (
          <EmptyHint />
        ) : (
          <div className="space-y-3">
            <MoodStrip entries={entries.slice(0, 7)} />
            {entries.map((e) => (
              <EntryCard key={e.id} entry={e} />
            ))}
          </div>
        )}
      </div>

      {/* Композер */}
      <div className="shrink-0 border-t-2 bg-white" style={{ borderColor: C.border }}>
        <div className="flex items-end gap-2 px-3 py-2.5">
          <span title="Голосовые заметки появятся в v1.1 (на телефонах)">
            <Mic size={24} className="cursor-not-allowed" style={{ color: "#C9C9C9" }} />
          </span>
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            rows={1}
            placeholder="Как прошёл день? Пара честных предложений…"
            className="max-h-28 min-h-[42px] flex-1 resize-none rounded-2xl border-2 bg-[#F7F7F2] px-3.5 py-2.5 text-[15px] outline-none placeholder:text-[13.5px]"
            style={{ borderColor: C.border, color: C.ink }}
            onFocus={(e) => (e.target.style.borderColor = C.blue)}
            onBlur={(e) => (e.target.style.borderColor = C.border)}
          />
          <button
            type="button"
            aria-label="Спросить ИИ-садовника"
            onClick={save}
            className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full"
            style={{ backgroundColor: C.green }}
          >
            <Sparkles size={22} color="#FFFFFF" />
          </button>
        </div>
      </div>

      {/* Шторка ответа */}
      <Sheet open={openEntryId !== null} onOpenChange={(v) => !v && setOpenEntryId(null)}>
        <SheetContent side="bottom" className="rounded-t-3xl px-6 pb-8 pt-5" aria-describedby={undefined}>
          {openEntry && (
            <ReplyContent
              key={`${openEntry.id}:${openEntry.source}:${openEntry.aiReply.length}`}
              entry={openEntry}
              thinking={thinking}
              onClose={() => setOpenEntryId(null)}
            />
          )}
        </SheetContent>
      </Sheet>
    </div>
  );
}

function ReplyContent({
  entry,
  thinking,
  onClose,
}: {
  entry: DiaryEntry;
  thinking: boolean;
  onClose: () => void;
}) {
  const [shown, setShown] = useState(0);
  const reply = entry.aiReply;
  const sourceLabel = entry.source === "llm" ? "LLM" : "офлайн-ИИ";
  const sourceBg = entry.source === "llm" ? C.greenSoft : "#F1F1F1";

  useEffect(() => {
    const t = setInterval(() => {
      setShown((s) => Math.min(s + 2, reply.length));
    }, 22);
    return () => clearInterval(t);
  }, [reply]);

  return (
    <div>
      <SheetHeader className="p-0">
        <SheetTitle className="flex items-center gap-2.5 text-left text-lg font-extrabold">
          <Sprout size={22} style={{ color: C.green }} />
          <span className="flex-1">ИИ-садовник</span>
          {thinking ? (
            <span
              className="rounded-full px-2 py-1 text-[11px] font-bold"
              style={{ backgroundColor: "#F1F1F1", color: C.inkSoft }}
            >
              LLM отвечает…
            </span>
          ) : (
            <span
              className="rounded-full px-2 py-1 text-[11px] font-bold"
              style={{ backgroundColor: sourceBg, color: C.inkSoft }}
            >
              {sourceLabel}
            </span>
          )}
        </SheetTitle>
      </SheetHeader>
      <p className="mt-3.5 min-h-[80px] text-[15px] leading-relaxed" style={{ color: C.ink }}>
        {reply.slice(0, shown)}
      </p>
      <div className="mt-4">
        <BigButton
          label="Спасибо, спокойной ночи"
          fullWidth
          onClick={onClose}
        />
      </div>
    </div>
  );
}

function EntryCard({ entry }: { entry: DiaryEntry }) {
  return (
    <InfoCard>
      <div className="flex items-center gap-2">
        <MoodGlyph score={entry.moodScore} />
        <span className="text-[12.5px]" style={{ color: C.inkSoft }}>
          {formatRuDateTime(entry.createdAt)}
        </span>
      </div>
      <p className="mt-2 line-clamp-3 text-[14.5px] leading-snug" style={{ color: C.ink }}>
        {entry.text}
      </p>
      {entry.tags.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-1.5">
          {entry.tags.map((tag) => (
            <span
              key={tag}
              className="rounded-full px-2 py-1 text-[11.5px]"
              style={{ backgroundColor: "#F4F1E6", color: C.inkSoft }}
            >
              {tag}
            </span>
          ))}
        </div>
      )}
      <div
        className="mt-2.5 flex items-start gap-2 rounded-xl p-2.5"
        style={{ backgroundColor: C.greenSoft }}
      >
        <Sprout size={16} className="mt-0.5 shrink-0" style={{ color: C.greenDark }} />
        <p className="text-[13px] leading-snug" style={{ color: C.ink }}>
          {entry.aiReply}
        </p>
      </div>
    </InfoCard>
  );
}

function MoodStrip({ entries }: { entries: DiaryEntry[] }) {
  return (
    <InfoCard>
      <p className="text-[14px] font-extrabold" style={{ color: C.ink }}>
        Настроение за последние дни
      </p>
      <div className="mt-2.5 flex justify-around">
        {[...entries].reverse().map((e) => (
          <div key={e.id} className="flex flex-col items-center">
            <MoodGlyph score={e.moodScore} size={20} />
            <span className="mt-1 text-[10px]" style={{ color: C.inkSoft }}>
              {new Date(e.createdAt).getDate()}
            </span>
          </div>
        ))}
      </div>
    </InfoCard>
  );
}

function EmptyHint() {
  return (
    <div className="flex h-full flex-col items-center justify-center px-8 text-center">
      <Moon size={44} style={{ color: C.purple }} />
      <p className="mt-3 text-[16px] font-bold" style={{ color: C.ink }}>
        Здесь появится история ваших вечеров
      </p>
      <p className="mt-2 text-[14px] leading-relaxed" style={{ color: C.inkSoft }}>
        Каждый вечер — пара честных предложений о том, как прошёл день.
        ИИ-садовник мягко подскажет, как лучше спать и меньше тревожиться.
      </p>
    </div>
  );
}
