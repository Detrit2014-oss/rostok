"use client";

// Порт lib/screens/challenge_screen.dart: «Детокс-неделя», лидерборд,
// свой челлендж, вступление по коду (демо).

import { useTTG, leaderboard, daysLeft } from "@/lib/ttg/store";
import { C, ChallengeParticipant } from "@/lib/ttg/types";
import { formatDurationMinutes } from "@/lib/ttg/format";
import { BigButton, InfoCard, OutlineButton, ProgressBar } from "./widgets";
import { Plus, UserPlus } from "lucide-react";
import { useEffect, useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { toast } from "sonner";

const GOALS = [3, 5, 7, 10, 15, 20];

export function ChallengeScreen() {
  const weekly = useTTG((s) => s.weekly);
  const refreshChallenge = useTTG((s) => s.refreshChallenge);
  const createChallenge = useTTG((s) => s.createChallenge);

  const [createOpen, setCreateOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [goal, setGoal] = useState(10);
  const [joinOpen, setJoinOpen] = useState(false);
  const [code, setCode] = useState("");

  // Обновляем ботов и свои минуты при входе на вкладку
  useEffect(() => {
    refreshChallenge();
  }, [refreshChallenge]);

  if (!weekly) return null;
  const board = leaderboard(weekly);
  const goalMinutes = weekly.goalHours * 60;

  return (
    <div className="h-full overflow-y-auto bg-[#FFFDF7] px-4 pb-6 pt-2">
      <InfoCard>
        <div className="flex items-center gap-2">
          <span className="flex-1 text-lg font-extrabold" style={{ color: C.ink }}>
            {weekly.title}
          </span>
          <span
            className="rounded-full px-2 py-1 text-[11px]"
            style={{ backgroundColor: "#F4F1E6", color: C.inkSoft }}
          >
            Демо-режим
          </span>
        </div>
        <p className="mt-1.5 text-[13px]" style={{ color: C.inkSoft }}>
          Цель недели: {weekly.goalHours} ч вне телефона · осталось {daysLeft()} дн.
        </p>
        <div className="mt-3.5 space-y-3">
          {board.map((p, i) => (
            <LeaderTile
              key={p.name + i}
              p={p}
              place={i}
              goalMinutes={goalMinutes}
            />
          ))}
        </div>
      </InfoCard>

      <div className="mt-4 flex gap-3">
        <BigButton
          label="Свой челлендж"
          icon={Plus}
          fullWidth
          onClick={() => setCreateOpen(true)}
        />
        <OutlineButton
          label="По коду"
          icon={UserPlus}
          fullWidth
          onClick={() => setJoinOpen(true)}
        />
      </div>

      <p
        className="mt-3 text-center text-[12.5px] leading-relaxed"
        style={{ color: C.inkSoft }}
      >
        В демо-режиме соперники — дружелюбные боты, а ваш прогресс считается из
        реальных минут детокса. Настоящие комнаты друзей появятся в v2.0 вместе
        с Firebase-синхронизацией.
      </p>

      {/* Создание челленджа */}
      <Dialog open={createOpen} onOpenChange={setCreateOpen}>
        <DialogContent className="max-w-[340px] rounded-3xl" aria-describedby={undefined}>
          <DialogHeader>
            <DialogTitle className="text-lg font-extrabold">Новый челлендж</DialogTitle>
          </DialogHeader>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Например: «Без ленты перед сном»"
            className="w-full rounded-2xl border-2 px-4 py-3 text-[15px] outline-none"
            style={{ borderColor: C.border, color: C.ink }}
          />
          <div className="flex items-center gap-2">
            <span className="text-[14px]" style={{ color: C.ink }}>
              Цель, часов в неделю:
            </span>
            <select
              value={goal}
              onChange={(e) => setGoal(Number(e.target.value))}
              className="rounded-xl border-2 px-2 py-1.5 text-[14px]"
              style={{ borderColor: C.border, color: C.ink }}
            >
              {GOALS.map((g) => (
                <option key={g} value={g}>
                  {g}
                </option>
              ))}
            </select>
          </div>
          <div className="flex justify-end gap-4">
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.inkSoft }}
              onClick={() => setCreateOpen(false)}
            >
              Отмена
            </button>
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.green }}
              onClick={() => {
                createChallenge(title, goal);
                setCreateOpen(false);
                toast("Челлендж создан — удачной недели! 🌱");
              }}
            >
              Создать
            </button>
          </div>
        </DialogContent>
      </Dialog>

      {/* Вступление по коду */}
      <Dialog open={joinOpen} onOpenChange={setJoinOpen}>
        <DialogContent className="max-w-[340px] rounded-3xl" aria-describedby={undefined}>
          <DialogHeader>
            <DialogTitle className="text-lg font-extrabold">Вступить по коду</DialogTitle>
          </DialogHeader>
          <p className="text-[13.5px]" style={{ color: C.ink }}>
            Попросите у друга код комнаты и введите его здесь.
          </p>
          <input
            value={code}
            onChange={(e) => setCode(e.target.value.toUpperCase())}
            placeholder="Например: GARDEN-42"
            className="w-full rounded-2xl border-2 px-4 py-3 text-[15px] outline-none"
            style={{ borderColor: C.border, color: C.ink }}
          />
          <div className="flex justify-end gap-4">
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.inkSoft }}
              onClick={() => setJoinOpen(false)}
            >
              Отмена
            </button>
            <button
              type="button"
              className="text-[14px] font-bold"
              style={{ color: C.green }}
              onClick={() => {
                setJoinOpen(false);
                toast("Демо: реальные комнаты друзей появятся в v2.0 вместе с Firebase");
              }}
            >
              Вступить
            </button>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function LeaderTile({
  p,
  place,
  goalMinutes,
}: {
  p: ChallengeParticipant;
  place: number;
  goalMinutes: number;
}) {
  const progress = Math.min(1, Math.max(0, p.minutes / goalMinutes));
  const medal = place === 0 ? "🥇" : place === 1 ? "🥈" : place === 2 ? "🥉" : `${place + 1}`;
  return (
    <div>
      <div className="flex items-center gap-2">
        <span className="w-[26px] text-[14px] font-bold" style={{ color: C.ink }}>
          {medal}
        </span>
        <span className="text-[16px]">{p.emoji}</span>
        <span
          className="flex-1 text-[14.5px]"
          style={{
            fontWeight: p.isUser ? 800 : 600,
            color: p.isUser ? C.greenDark : C.ink,
          }}
        >
          {p.isUser ? "Вы" : p.name}
        </span>
        <span className="text-[13px]" style={{ color: C.inkSoft }}>
          {formatDurationMinutes(p.minutes)}
        </span>
      </div>
      <div className="mt-1.5">
        <ProgressBar
          value={progress}
          height={8}
          bg="#EEE9D8"
          color={p.isUser ? C.green : "#B9CDBB"}
        />
      </div>
    </div>
  );
}
