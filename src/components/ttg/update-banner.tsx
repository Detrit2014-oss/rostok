"use client";

// Порт lib/widgets/update_banner.dart: глобальный баннер «Доступно
// обновление» над контентом + шторка «Что нового».

import { C, AppUpdateInfo } from "@/lib/ttg/types";
import { useTTG } from "@/lib/ttg/store";
import { ArrowDownToLine, ChevronRight, Download } from "lucide-react";
import { useState } from "react";
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet";
import { OutlineButton } from "./widgets";
import { toast } from "sonner";

export function UpdateBanner() {
  const available = useTTG((s) => s.availableUpdate);
  const appVersion = useTTG((s) => s.appVersion);
  const clearAvailable = useTTG((s) => s.clearAvailableUpdate);
  const applyUpdate = useTTG((s) => s.applyUpdate);
  const [open, setOpen] = useState(false);

  if (!available) return null;
  const color: string = available.force_update ? C.coral : C.blue;

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="flex w-full items-center gap-2.5 px-4 py-2.5 text-left"
        style={{ backgroundColor: color }}
      >
        <Download size={22} color="#FFFFFF" />
        <span className="flex-1 text-[14px] font-bold text-white">
          Доступна версия {available.latest_version} — нажмите, чтобы узнать,
          что нового
        </span>
        <ChevronRight size={20} color="rgba(255,255,255,0.85)" />
      </button>

      <Sheet open={open} onOpenChange={setOpen}>
        <SheetContent side="bottom" className="rounded-t-3xl px-6 pb-8 pt-5" aria-describedby={undefined}>
          <SheetHeader className="p-0">
            <SheetTitle className="flex items-center gap-2.5 text-left text-lg font-extrabold">
              <ArrowDownToLine size={22} style={{ color }} />
              Обновление до версии {available.latest_version}
            </SheetTitle>
          </SheetHeader>
          <p className="mt-2.5 text-[13px]" style={{ color: C.inkSoft }}>
            Установлена версия {appVersion}.
          </p>
          {(available.notes ?? "").length > 0 && (
            <p className="mt-3 text-[15px] leading-relaxed" style={{ color: C.ink }}>
              {available.notes}
            </p>
          )}
          <div className="mt-4 flex flex-wrap gap-2.5">
            {available.android_url && (
              <OutlineButton
                label="Ссылка (Android)"
                onClick={() => {
                  navigator.clipboard?.writeText(available.android_url!);
                  toast("Ссылка на Google Play скопирована");
                }}
              />
            )}
            {available.ios_url && (
              <OutlineButton
                label="Ссылка (iOS)"
                onClick={() => {
                  navigator.clipboard?.writeText(available.ios_url!);
                  toast("Ссылка на App Store скопирована");
                }}
              />
            )}
          </div>
          <p className="mt-3 text-[12px]" style={{ color: C.inkSoft }}>
            В мобильных сборках кнопка открывает магазин (url_launcher); в
            веб-версии ссылка копируется.
          </p>
          <div className="mt-4 flex flex-col gap-2.5">
            <button
              type="button"
              onClick={() => {
                applyUpdate(available.latest_version);
                setOpen(false);
                toast.success(`Готово: установлена версия ${available.latest_version}`);
              }}
              className="w-full rounded-2xl py-3.5 text-base font-extrabold text-white"
              style={{
                backgroundColor: color,
                boxShadow: `0 4px 0 0 ${color === C.blue ? C.blueDark : C.coralDark}`,
              }}
            >
              Обновить (демо установки)
            </button>
            <button
              type="button"
              onClick={() => setOpen(false)}
              className="w-full py-2 text-[14px] font-bold"
              style={{ color: C.inkSoft }}
            >
              Напомнить позже
            </button>
          </div>
        </SheetContent>
      </Sheet>
    </>
  );
}
