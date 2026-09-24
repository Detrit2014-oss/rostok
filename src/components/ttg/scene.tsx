"use client";

// Порт lib/widgets/pet_canvas.dart (v2.2.0 «Мультяшные звери»).
// Вся сцена рисуется на canvas 2D: небо, солнце, облака, лужайка,
// грядка, пруд, погода — и мультяшные питомцы из cartoon.ts, которые
// ЖИВУТ: лапы шагают, хвосты виляют, уши пружинят, глаза моргают,
// на паузах зверь принюхивается, щиплет траву, сидит; птицы клюют;
// спящие звери ЛЕЖАТ. Яйцо и семечко — процедурные. 1:1 с Flutter.

import { useEffect, useRef } from "react";

import {
  GEOM,
  HOP_PETS,
  cartoonSpec,
  cartoonStageScale,
  isAquatic,
  isPlant,
  laneScales,
  laneYs,
  Pet,
  petStage,
  stageProgress,
  bodyColor,
} from "@/lib/ttg/types";
import type { PetType } from "@/lib/ttg/types";
import { paintCartoonPet } from "@/lib/ttg/cartoon";

const VB_W = 400;
const VB_H = 240;
const GROUND_Y = VB_H * GEOM.groundYF; // 177.6
const CRACK = "#C9A96E";
const SOIL = "#7A4E2D";
const STEM = "#5FA052";

// ── Повадки настоящих зверей — порт _petBehavior из Dart ──────────────
const STROLL_PERIOD = 21; // цикл «прогулка + пауза», с
const PAUSE_AT = 13.5; // начало паузы внутри цикла
const PAUSE_LEN = 3.8; // длительность паузы, с
const CROSS_SEC = 8.2; // полпути через лужайку, с

interface PetBehavior {
  x: number;
  facing: number;
  kind: "walk" | "sniff" | "graze" | "sit" | "peck" | "look";
  headPitch: number;
  stride: number;
  poseEase: number;
}

const GRAZERS: PetType[] = ["deer", "unicorn", "bunny", "squirrel", "pig", "koala", "panda", "dragon", "hedgehog"];
const PERCHERS: PetType[] = ["fox", "cat", "dog", "raccoon", "bear"];
const PECKERS: PetType[] = ["owl", "duck", "chick", "penguin"];

function strHash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) {
    h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  }
  return h;
}

function pbHash(a: number, b: number): number {
  let h = (Math.imul(a, 374761393) + Math.imul(b, 668265263)) & 0x7fffffff;
  h = Math.imul(h ^ (h >>> 13), 1274126177) & 0x7fffffff;
  return ((h ^ (h >>> 16)) & 0x7fffffff) / 0x7fffffff;
}

function petBehavior(pet: Pet, tSec: number): PetBehavior {
  const seed = strHash(pet.id) & 0x7fffffff;
  const off = (seed % 1900) / 100;
  const total = tSec + off;
  const local = total % STROLL_PERIOD;
  const cycle = Math.floor(total / STROLL_PERIOD);

  const pauseDone =
    Math.floor(total / STROLL_PERIOD) * PAUSE_LEN +
    (local >= PAUSE_AT ? Math.min(local - PAUSE_AT, PAUSE_LEN) : 0);
  const walkT = tSec - pauseDone;

  const tri = ((walkT + off) / CROSS_SEC) % 2;
  const x = tri < 1 ? tri : 2 - tri;
  const facing = tri < 1 ? 1 : -1;
  const stride = ((walkT + off) * 2 * Math.PI) / 0.8;

  if (local < PAUSE_AT || local >= PAUSE_AT + PAUSE_LEN) {
    return { x, facing, kind: "walk", headPitch: 0.05 + Math.sin(stride * 2) * 0.03, stride, poseEase: 0 };
  }

  const r = pbHash(seed, cycle);
  let kind: PetBehavior["kind"];
  if (PECKERS.includes(pet.type)) {
    kind = r < 0.62 ? "peck" : "look";
  } else if (PERCHERS.includes(pet.type)) {
    kind = r < 0.4 ? "sniff" : r < 0.78 ? "sit" : "look";
  } else if (GRAZERS.includes(pet.type)) {
    kind = r < 0.55 ? "graze" : r < 0.85 ? "sniff" : "look";
  } else {
    kind = r < 0.5 ? "sniff" : "look";
  }

  const tin = Math.min(1, Math.max(0, (local - PAUSE_AT) / 0.7));
  const tout = Math.min(1, Math.max(0, (PAUSE_AT + PAUSE_LEN - local) / 0.7));
  const e = Math.min(tin, tout);
  const ease = e * e * (3 - 2 * e);

  let target: number;
  switch (kind) {
    case "graze":
      target = 1.0 + Math.sin(tSec * 8.5) * 0.06;
      break;
    case "sniff":
      target = 0.62 + Math.sin(tSec * 7.0) * 0.07;
      break;
    case "peck": {
      const pp = (((local - PAUSE_AT) / PAUSE_LEN) * 3) % 1;
      target = Math.sin(pp * Math.PI) * 0.85;
      break;
    }
    default:
      target = 0.1 + Math.sin(tSec * 1.6) * 0.12;
  }
  return { x, facing, kind, headPitch: target * ease, stride, poseEase: ease };
}

// ── Рисовальные помощники ──────────────────────────────────────────────

interface DrawOpts {
  pets: Pet[];
  sleeping: boolean;
  weather?: string | null;
  frame: string;
  tSec: number;
  phase: number; // 0..1, цикл 4 c — как AnimationController во Flutter
}

/** Питомец мультяшным движком: флип, наклон, повадки. */
function drawPet(
  cv: CanvasRenderingContext2D,
  pet: Pet,
  gx: number,
  gy: number,
  h: number,
  o: {
    tSec: number;
    facing?: number;
    tilt?: number;
    kind?: string;
    stride?: number;
    headPitch?: number;
    poseEase?: number;
    sleeping?: boolean;
    index?: number;
  },
) {
  cv.save();
  cv.translate(gx, gy);
  cv.scale(o.facing ?? 1, 1);
  cv.rotate(o.tilt ?? 0);
  paintCartoonPet(cv, pet, h, {
    tSec: o.tSec,
    kind: o.kind ?? "idle",
    stride: o.stride ?? 0,
    headPitch: o.headPitch ?? 0,
    poseEase: o.poseEase ?? 0,
    sleeping: o.sleeping ?? false,
    index: o.index ?? 0,
  });
  cv.restore();
}

function drawShadow(cv: CanvasRenderingContext2D, x: number, y: number, w: number) {
  cv.beginPath();
  cv.ellipse(x, y + 2, w / 2, (w * 0.16) / 2, 0, 0, Math.PI * 2);
  cv.fillStyle = "rgba(46,125,50,0.18)";
  cv.fill();
}

function drawCloud(cv: CanvasRenderingContext2D, cx: number, cy: number, r: number) {
  cv.fillStyle = "rgba(255,255,255,0.9)";
  cv.beginPath();
  cv.arc(cx - r * 0.8, cy + r * 0.25, r * 0.65, 0, Math.PI * 2);
  cv.arc(cx, cy, r, 0, Math.PI * 2);
  cv.arc(cx + r * 0.8, cy + r * 0.25, r * 0.6, 0, Math.PI * 2);
  cv.fill();
}

function drawGrassTuft(cv: CanvasRenderingContext2D, x: number, y: number, h: number, sway: number, color: string) {
  cv.strokeStyle = color;
  cv.lineWidth = 2.2;
  cv.lineCap = "round";
  for (const dx of [-5, -1.5, 2.5, 6]) {
    cv.beginPath();
    cv.moveTo(x + dx, y);
    cv.quadraticCurveTo(x + dx + sway, y - h * 0.6, x + dx + sway * 1.8 + dx * 0.35, y - h);
    cv.stroke();
  }
}

function drawZzz(cv: CanvasRenderingContext2D, x: number, y: number, s: number) {
  const zs: [string, number, number, number, number][] = [
    // текст, dx, dy, fontSize, alpha
    ["z", 0, 0, 11, 0.9],
    ["z", 9, -10, 14, 0.7],
    ["Z", 18, -20, 17, 0.5],
  ];
  for (const [t, dx, dy, fs, a] of zs) {
    cv.font = `800 ${fs * s}px inherit, sans-serif`;
    cv.fillStyle = `rgba(107,123,140,${a})`;
    cv.fillText(t, x + dx * s, y + dy * s);
  }
}

/** Большое яйцо: растёт с прогрессом, покачивается, трескается. */
function drawEgg(cv: CanvasRenderingContext2D, spot: string, progress: number, phase: number) {
  const eggS = 0.95 + 0.45 * progress;
  const w = 34 * eggS;
  const h = 44 * eggS;
  const wobble = Math.sin(phase * Math.PI * 2 * 1.6) * 0.06 * (0.35 + progress);
  cv.save();
  cv.rotate(wobble);
  // Тень.
  cv.beginPath();
  cv.ellipse(0, 2, (w * 1.15) / 2, (h * 0.14) / 2, 0, 0, Math.PI * 2);
  cv.fillStyle = "rgba(46,125,50,0.15)";
  cv.fill();
  cv.beginPath();
  cv.ellipse(0, -h / 2, w / 2, h / 2, 0, 0, Math.PI * 2);
  cv.fillStyle = "#FFF6E3";
  cv.fill();
  cv.beginPath();
  cv.ellipse(0, -h / 2, w / 2 - w * 0.12, h / 2 - w * 0.12, 0, 0, Math.PI * 2);
  cv.fillStyle = "#FFFBF0";
  cv.fill();
  cv.fillStyle = spot;
  cv.globalAlpha = 0.65;
  cv.beginPath();
  cv.arc(-w * 0.18, -h * 0.55, 3.5 * eggS, 0, Math.PI * 2);
  cv.arc(w * 0.15, -h * 0.35, 2.6 * eggS, 0, Math.PI * 2);
  cv.arc(-w * 0.05, -h * 0.75, 2.0 * eggS, 0, Math.PI * 2);
  cv.fill();
  cv.globalAlpha = 1;
  cv.strokeStyle = CRACK;
  cv.lineWidth = 2.2;
  cv.lineCap = "round";
  cv.lineJoin = "round";
  if (progress > 0.45) {
    cv.beginPath();
    cv.moveTo(0, -h * 0.78);
    cv.lineTo(w * 0.14, -h * 0.66);
    cv.lineTo(-w * 0.07, -h * 0.54);
    cv.lineTo(w * 0.1, -h * 0.44);
    cv.stroke();
  }
  if (progress > 0.75) {
    cv.beginPath();
    cv.moveTo(-w * 0.05, -h * 0.52);
    cv.lineTo(-w * 0.2, -h * 0.4);
    cv.lineTo(w * 0.02, -h * 0.28);
    cv.stroke();
  }
  cv.restore();
}

/** Семечко на грядке (растения, стадия 0). */
function drawSeedBed(cv: CanvasRenderingContext2D, progress: number, phase: number) {
  const s = 1;
  cv.beginPath();
  cv.ellipse(0, -6 * s, 26 * s, 9 * s, 0, 0, Math.PI * 2);
  cv.fillStyle = SOIL;
  cv.fill();
  cv.beginPath();
  cv.ellipse(0, -9 * s, 22 * s, 6 * s, 0, 0, Math.PI * 2);
  cv.fillStyle = "#96683F";
  cv.fill();
  cv.save();
  cv.translate(2 * s, -12 * s);
  cv.rotate(-0.35 + Math.sin(phase * Math.PI * 2) * 0.04);
  cv.beginPath();
  cv.ellipse(0, 0, 4.5 * s, 6.5 * s, 0, 0, Math.PI * 2);
  cv.fillStyle = "#C89B62";
  cv.fill();
  cv.beginPath();
  cv.ellipse(-1.6 * s, -2.4 * s, 1.7 * s, 2.5 * s, 0, 0, Math.PI * 2);
  cv.fillStyle = "#E5C793";
  cv.fill();
  cv.restore();
  if (progress > 0.4) {
    cv.strokeStyle = "#5E3D22";
    cv.lineWidth = 2;
    cv.lineCap = "round";
    cv.beginPath();
    cv.moveTo(-14 * s, -4 * s);
    cv.lineTo(-8 * s, -8 * s);
    cv.lineTo(-11 * s, -13 * s);
    cv.stroke();
  }
  if (progress > 0.62) {
    const h = 8 * s + 8 * s * ((progress - 0.62) / 0.38);
    cv.fillStyle = STEM;
    cv.fillRect(-1.3 * s, -12 * s - h, 2.6 * s, h);
    cv.fillStyle = "#7FC45C";
    cv.beginPath();
    cv.ellipse(-5 * s, -12 * s - h + 1, 4 * s, 1.8 * s, 0, 0, Math.PI * 2);
    cv.fill();
    cv.globalAlpha = 0.85;
    cv.beginPath();
    cv.ellipse(5 * s, -12 * s - h + 3, 4 * s, 1.8 * s, 0, 0, Math.PI * 2);
    cv.fill();
    cv.globalAlpha = 1;
  }
  if (progress > 0.85) {
    cv.fillStyle = "#FFD166";
    cv.beginPath();
    cv.arc(-16 * s, -26 * s + Math.sin(phase * Math.PI * 2) * 2, 2.2 * s, 0, Math.PI * 2);
    cv.fill();
    cv.fillStyle = "#FFFFFF";
    cv.beginPath();
    cv.arc(-16 * s, -26 * s + Math.sin(phase * Math.PI * 2) * 2, 0.9 * s, 0, Math.PI * 2);
    cv.fill();
  }
}

// ── Группы питомцев ────────────────────────────────────────────────────

function drawPlants(cv: CanvasRenderingContext2D, plants: Pet[], sleeping: boolean, tSec: number) {
  const x0 = VB_W * GEOM.bedX0F;
  const x1 = VB_W * GEOM.bedX1F;
  const bedY = VB_H * GEOM.bedYF;
  for (let i = 0; i < plants.length; i++) {
    const pet = plants[i];
    const slotX = x0 + (x1 - x0) * (plants.length === 1 ? 0.5 : i / (plants.length - 1));
    const baseX = slotX;
    const baseY = bedY - 2;
    if (petStage(pet) === 0) {
      cv.save();
      cv.translate(baseX, baseY);
      drawSeedBed(cv, stageProgress(pet), (tSec % 4) / 4);
      if (sleeping) drawZzz(cv, 22, -26, 1);
      cv.restore();
      continue;
    }
    const h = VB_H * cartoonSpec(pet.type).heightF * cartoonStageScale(petStage(pet));
    const sway = Math.sin(tSec * 1.5 + i * 1.9) * 0.045 * (sleeping ? 0.4 : 1);
    drawPet(cv, pet, baseX, baseY, h, { tSec, tilt: sway, index: i });
    if (sleeping) drawZzz(cv, baseX + h * 0.5, baseY - h * 0.95, 1);
  }
}

function drawAquatic(
  cv: CanvasRenderingContext2D,
  water: Pet[],
  sleeping: boolean,
  tSec: number,
  phase: number,
) {
  const pondCX = VB_W * GEOM.pondCXF;
  const pondCY = VB_H * GEOM.pondCYF;
  const pondRW = VB_W * GEOM.pondRWF;
  const pondRH = VB_H * GEOM.pondRHF;
  for (let i = 0; i < water.length; i++) {
    const pet = water[i];
    const spec = cartoonSpec(pet.type);
    let h = VB_H * spec.heightF * cartoonStageScale(petStage(pet));
    if (h * spec.aspect > pondRW * 1.3) h = (pondRW * 1.3) / spec.aspect;

    const seed = strHash(pet.id) & 0x7fffffff;
    const off = (seed % 1000) / 100;
    const swimT = tSec * (pet.type === "crab" ? 0.14 : 0.22) + off;
    const dx = Math.sin(swimT) * pondRW * 0.45;
    const dy = Math.sin(tSec * 1.2 + off * 2) * pondRH * 0.1;
    const goingRight = Math.cos(swimT) > 0;
    const baseY = pet.type === "crab" ? pondCY + pondRH * 0.42 + dy : pondCY - pondRH * 0.22 + dy;

    drawPet(cv, pet, pondCX + dx, baseY, h, {
      tSec,
      facing: goingRight ? 1 : -1,
      tilt: Math.sin(tSec * 1.1 + off) * 0.03,
      sleeping,
      index: i,
    });

    // Фонтанчик у кита каждые ~7 с.
    if (pet.type === "whale" && !sleeping) {
      const cyc = (tSec + off) % 7;
      if (cyc < 1.4) {
        const t = cyc / 1.4;
        const fh = h * (0.16 + 0.14 * Math.sin(t * Math.PI));
        const fx = pondCX + dx - h * spec.aspect * 0.18 * (goingRight ? 1 : -1);
        const fy = baseY - h * 0.95;
        cv.strokeStyle = `rgba(191,230,247,${0.85 * (1 - t * 0.6)})`;
        cv.lineWidth = 2.4;
        cv.lineCap = "round";
        cv.beginPath();
        cv.moveTo(fx, fy);
        cv.lineTo(fx, fy - fh);
        cv.stroke();
        for (let j = 0; j < 4; j++) {
          const dt = (t * 1.3 + j * 0.22) % 1;
          const ang = -0.5 + j * 0.34;
          cv.fillStyle = `rgba(159,212,239,${0.8 * (1 - dt)})`;
          cv.beginPath();
          cv.arc(fx - Math.sin(ang) * fh * 0.5 * dt, fy - fh * 0.9 * dt, 1.6, 0, Math.PI * 2);
          cv.fill();
        }
      }
    }
    if (sleeping) drawZzz(cv, pondCX + dx + h * spec.aspect * 0.4, baseY - h, 1);
  }
  void phase;
}

function drawLandPets(
  cv: CanvasRenderingContext2D,
  land: Pet[],
  sleeping: boolean,
  tSec: number,
) {
  const ys = laneYs(land.length);
  const scales = laneScales(land.length);
  let eggCounter = 0;
  for (let i = 0; i < land.length; i++) {
    const pet = land[i];
    const laneY = VB_H * ys[i];
    const depth = scales[i];
    const stage = petStage(pet);

    if (stage === 0) {
      const ex = VB_W * (0.12 + 0.09 * eggCounter++);
      cv.save();
      cv.translate(ex, laneY);
      drawEgg(cv, bodyColor(pet.type), stageProgress(pet), (tSec % 4) / 4);
      cv.restore();
      continue;
    }

    const h = VB_H * cartoonSpec(pet.type).heightF * cartoonStageScale(stage) * depth;

    if (sleeping) {
      const spotX = VB_W * (land.length === 1 ? 0.5 : 0.14 + (0.72 * i) / Math.max(1, land.length - 1));
      drawShadow(cv, spotX, laneY, h * cartoonSpec(pet.type).aspect * 0.6);
      drawPet(cv, pet, spotX, laneY, h, { tSec, sleeping: true, index: i });
      drawZzz(cv, spotX + h * cartoonSpec(pet.type).aspect * 0.42, laneY - h * 0.55, depth);
      continue;
    }

    const bhv = petBehavior(pet, tSec);
    const gx = VB_W * (0.13 + 0.74 * bhv.x);

    let tilt = 0;
    let lift = 0;
    if (HOP_PETS.includes(pet.type)) {
      const hopP = ((tSec * 2 * Math.PI) / 0.85) % (2 * Math.PI);
      const hop = bhv.kind === "walk" ? Math.abs(Math.sin(hopP)) : 0;
      lift = -hop * h * 0.28;
      tilt = Math.sin(hopP + 0.6) * 0.1 * (bhv.kind === "walk" ? 1 : 0);
    } else if (bhv.kind === "walk") {
      tilt = Math.sin(bhv.stride) * 0.03;
      lift = -Math.abs(Math.sin(bhv.stride * 2)) * h * 0.02;
    }

    drawShadow(cv, gx, laneY, h * cartoonSpec(pet.type).aspect * 0.55);
    drawPet(cv, pet, gx, laneY + lift, h, {
      tSec,
      facing: bhv.facing,
      tilt,
      kind: bhv.kind,
      stride: bhv.stride,
      headPitch: bhv.headPitch,
      poseEase: bhv.poseEase,
      index: i,
    });
  }
}

function drawButterflies(cv: CanvasRenderingContext2D, tSec: number, phase: number) {
  for (let i = 0; i < 2; i++) {
    const speed = 0.1 + i * 0.05;
    const t = (phase * speed + i * 0.45) % 2;
    const tri = t < 1 ? t : 2 - t;
    const px = VB_W * (0.14 + 0.72 * tri);
    const py = VB_H * (0.34 + 0.07 * Math.sin(tSec * (1.4 + i) + i * 2.4));
    const flap = Math.min(1, Math.max(0.3, Math.abs(Math.sin(tSec * (7 + i * 2)))));
    const sz = 7 + i * 1.5;
    const wingA = i === 0 ? "#FF9F45" : "#B892E0";
    const wingB = i === 0 ? "#FFD166" : "#8FBFF2";
    cv.save();
    cv.translate(px, py);
    cv.scale(flap, 1);
    cv.fillStyle = wingA;
    cv.beginPath();
    cv.ellipse(-sz * 0.55, -sz * 0.2, sz / 2, (sz * 0.7) / 2, 0, 0, Math.PI * 2);
    cv.ellipse(sz * 0.55, -sz * 0.2, sz / 2, (sz * 0.7) / 2, 0, 0, Math.PI * 2);
    cv.fill();
    cv.fillStyle = wingB;
    cv.beginPath();
    cv.ellipse(-sz * 0.42, sz * 0.28, (sz * 0.62) / 2, (sz * 0.46) / 2, 0, 0, Math.PI * 2);
    cv.ellipse(sz * 0.42, sz * 0.28, (sz * 0.62) / 2, (sz * 0.46) / 2, 0, 0, Math.PI * 2);
    cv.fill();
    cv.restore();
    cv.strokeStyle = "#5A4632";
    cv.lineWidth = 1.8;
    cv.lineCap = "round";
    cv.beginPath();
    cv.moveTo(px, py - sz * 0.35);
    cv.lineTo(px, py + sz * 0.45);
    cv.stroke();
  }
}

function drawWeather(cv: CanvasRenderingContext2D, weather: string | null | undefined, tSec: number, phase: number) {
  switch (weather) {
    case "fog":
      for (let i = 0; i < 3; i++) {
        const y = VB_H * (0.45 + 0.16 * i) + Math.sin(phase * Math.PI * 2 + i) * 8;
        const x = -20 + Math.sin(phase * Math.PI * 2 + i * 2) * 14;
        cv.fillStyle = `rgba(255,255,255,${0.38 - i * 0.07})`;
        cv.beginPath();
        cv.roundRect(x, y, VB_W + 40, VB_H * 0.075, 20);
        cv.fill();
      }
      break;
    case "rain":
      cv.strokeStyle = "rgba(159,212,239,0.75)";
      cv.lineWidth = 2.2;
      cv.lineCap = "round";
      for (let i = 0; i < 34; i++) {
        const fx = ((i * 97) % 100) / 100;
        const fall = (phase * 2.2 + fx * 3.0) % 1;
        const x = VB_W * fx + fall * 18;
        const y = VB_H * (fall - 0.08);
        cv.beginPath();
        cv.moveTo(x, y);
        cv.lineTo(x - 5, y + 16);
        cv.stroke();
      }
      break;
    case "snow":
      cv.fillStyle = "rgba(255,255,255,0.9)";
      for (let i = 0; i < 26; i++) {
        const fx = ((i * 61) % 100) / 100;
        const fall = (phase * 0.9 + fx * 2.4) % 1;
        const x = VB_W * fx + Math.sin(fall * 9 + i) * 14;
        const y = VB_H * fall;
        cv.beginPath();
        cv.arc(x, y, 2.4 + (i % 3), 0, Math.PI * 2);
        cv.fill();
      }
      break;
    case "thunder": {
      cv.fillStyle = "rgba(46,58,85,0.22)";
      cv.fillRect(0, 0, VB_W, VB_H);
      const cyc = (phase * 1.35) % 1;
      if (cyc < 0.09) {
        const flash = 1 - cyc / 0.09;
        cv.fillStyle = `rgba(255,255,255,${0.3 * flash})`;
        cv.fillRect(0, 0, VB_W, VB_H);
        cv.strokeStyle = "#FFE45C";
        cv.lineWidth = 4.5;
        cv.lineJoin = "round";
        cv.lineCap = "round";
        const bx = VB_W * 0.68;
        cv.beginPath();
        cv.moveTo(bx, VB_H * 0.06);
        cv.lineTo(bx - 26, VB_H * 0.3);
        cv.lineTo(bx + 6, VB_H * 0.32);
        cv.lineTo(bx - 20, VB_H * 0.62);
        cv.stroke();
      }
      break;
    }
    default:
      break;
  }
  void tSec;
}

// ── Главная отрисовка сцены (порт _PetScenePainter.paint) ──────────────

function drawScene(cv: CanvasRenderingContext2D, o: DrawOpts) {
  const { pets, sleeping, weather, frame, tSec, phase } = o;
  const dimSky = weather === "cloudy" || weather === "rain" || weather === "thunder";
  const hasPond = pets.some((p) => isAquatic(p.type));
  const hasBed = pets.some((p) => isPlant(p.type));

  const skyColors: [string, string] =
    weather === "thunder"
      ? ["#6B7B95", "#B9C6A8"]
      : weather === "rain"
        ? ["#8FB8CF", "#CBE3C8"]
        : weather === "cloudy"
          ? ["#AFC6D6", "#E2EFD8"]
          : weather === "snow"
            ? ["#BAD8EE", "#EFF7EF"]
            : ["#A6E4FF", "#EAF9E0"];

  // Небо.
  const sky = cv.createLinearGradient(0, 0, 0, VB_H);
  sky.addColorStop(0, skyColors[0]);
  sky.addColorStop(1, skyColors[1]);
  cv.fillStyle = sky;
  cv.fillRect(0, 0, VB_W, VB_H);

  // Солнце.
  if (!dimSky) {
    cv.fillStyle = "rgba(255,200,0,0.25)";
    cv.beginPath();
    cv.arc(VB_W * 0.16, VB_H * 0.14, VB_W * 0.085, 0, Math.PI * 2);
    cv.fill();
    cv.fillStyle = "#FFC800";
    cv.beginPath();
    cv.arc(VB_W * 0.16, VB_H * 0.14, VB_W * 0.055, 0, Math.PI * 2);
    cv.fill();
  }

  // Облака с лёгким дрейфом.
  const drift = Math.sin(tSec * 0.12) * 8;
  drawCloud(cv, VB_W * 0.55 + drift, VB_H * 0.14, VB_W * 0.045);
  drawCloud(cv, VB_W * 0.78 - drift, VB_H * 0.24, VB_W * 0.035);
  if (weather === "partly" || weather === "cloudy" || weather === "rain") {
    drawCloud(cv, VB_W * 0.32 + drift * 1.4, VB_H * 0.1, VB_W * 0.038);
    drawCloud(cv, VB_W * 0.92 - drift, VB_H * 0.09, VB_W * 0.03);
  }

  // Лужайка.
  cv.fillStyle = "#90D26D";
  cv.beginPath();
  cv.roundRect(0, GROUND_Y, VB_W, VB_H - GROUND_Y, [28, 28, 0, 0]);
  cv.fill();
  cv.fillStyle = "#7FC45C";
  cv.beginPath();
  cv.arc(VB_W * 0.12, GROUND_Y + VB_H * 0.09, 22, 0, Math.PI * 2);
  cv.arc(VB_W * 0.9, GROUND_Y + VB_H * 0.07, 18, 0, Math.PI * 2);
  cv.fill();

  // Цветочки.
  const flowers: [number, number, string][] = [
    [VB_W * 0.06, GROUND_Y + VB_H * 0.14, "#FF8FB1"],
    [VB_W * 0.36, GROUND_Y + VB_H * 0.1, "#FFD166"],
    [VB_W * 0.72, GROUND_Y + VB_H * 0.16, "#EF476F"],
    [VB_W * 0.95, GROUND_Y + VB_H * 0.12, "#FFD166"],
  ];
  for (const [fx, fy, fc] of flowers) {
    cv.fillStyle = fc;
    cv.beginPath();
    cv.arc(fx, fy, 4, 0, Math.PI * 2);
    cv.fill();
    cv.fillStyle = "#FFFFFF";
    cv.beginPath();
    cv.arc(fx, fy, 1.6, 0, Math.PI * 2);
    cv.fill();
  }

  // Трава пучками.
  for (let i = 0; i < 7; i++) {
    const fx = VB_W * (0.05 + 0.135 * i);
    const fy = GROUND_Y + VB_H * (0.035 + (0.05 * ((i * 7) % 3)) / 3);
    drawGrassTuft(
      cv,
      fx,
      fy,
      13 + (i % 3) * 5,
      Math.sin(tSec * 1.8 + i * 1.7) * 2.6,
      i % 2 === 0 ? "#5FA852" : "#6FBC5E",
    );
  }

  // Грядка растений.
  if (hasBed) {
    const x0 = VB_W * GEOM.bedX0F;
    const x1 = VB_W * GEOM.bedX1F;
    const y = VB_H * GEOM.bedYF;
    cv.fillStyle = "#A9744F";
    cv.beginPath();
    cv.roundRect(x0 - 4, y - VB_H * 0.055 - 4, x1 - x0 + 8, VB_H * 0.055 + 10, 12);
    cv.fill();
    cv.fillStyle = SOIL;
    cv.beginPath();
    cv.roundRect(x0, y - VB_H * 0.055, x1 - x0, VB_H * 0.055 + 6, 12);
    cv.fill();
    cv.fillStyle = "#96683F";
    cv.beginPath();
    cv.roundRect(x0 + 4, y - VB_H * 0.055 + 4, x1 - x0 - 8, VB_H * 0.055 - 2, 12);
    cv.fill();
    cv.fillStyle = SOIL;
    for (let i = 0; i < 6; i++) {
      const px = x0 + 10 + (((i * 53) % 90) / 90) * (x1 - x0 - 20);
      const py = y - 8 + ((i * 31) % 10) - 4;
      cv.beginPath();
      cv.arc(px, py, 2 + (i % 2), 0, Math.PI * 2);
      cv.fill();
    }
  }

  // Пруд.
  const pondCX = VB_W * GEOM.pondCXF;
  const pondCY = VB_H * GEOM.pondCYF;
  const pondRW = VB_W * GEOM.pondRWF;
  const pondRH = VB_H * GEOM.pondRHF;
  if (hasPond) {
    cv.fillStyle = "#E8D8A8";
    cv.beginPath();
    cv.ellipse(pondCX, pondCY, pondRW * 1.08, pondRH * 1.08, 0, 0, Math.PI * 2);
    cv.fill();
    cv.fillStyle = "#6EC1E4";
    cv.beginPath();
    cv.ellipse(pondCX, pondCY, pondRW, pondRH, 0, 0, Math.PI * 2);
    cv.fill();
    cv.strokeStyle = "rgba(255,255,255,0.5)";
    cv.lineWidth = 2;
    cv.lineCap = "round";
    for (let i = 0; i < 3; i++) {
      const wy = pondCY - pondRH * 0.4 + i * pondRH * 0.42;
      const wx = pondCX + (i - 1) * pondRW * 0.18;
      cv.beginPath();
      cv.arc(wx, wy, pondRW * 0.25, 0.15 * Math.PI, 0.85 * Math.PI);
      cv.stroke();
    }
  }

  // Питомцы: растения → вода → передняя вода → суша.
  const plants = pets.filter((p) => isPlant(p.type));
  const water = pets.filter((p) => isAquatic(p.type));
  const land = pets.filter((p) => !isAquatic(p.type) && !isPlant(p.type));

  if (plants.length > 0) drawPlants(cv, plants, sleeping, tSec);

  if (water.length > 0) {
    drawAquatic(cv, water, sleeping, tSec, phase);
    // Передняя кромка воды.
    cv.fillStyle = "rgba(110,193,228,0.45)";
    cv.beginPath();
    cv.ellipse(pondCX, pondCY, pondRW, pondRH, 0, 0, Math.PI * 2);
    cv.fill();
    cv.strokeStyle = "rgba(255,255,255,0.5)";
    cv.lineWidth = 2;
    for (let i = 0; i < 2; i++) {
      const t = (phase * 1.2 + i * 0.5) % 1;
      cv.strokeStyle = `rgba(255,255,255,${0.55 * (1 - t)})`;
      cv.beginPath();
      cv.ellipse(pondCX, pondCY + pondRH * 0.3, pondRW * (0.35 + t * 0.45), pondRH * (0.35 + t * 0.45) * 0.42, 0, 0, Math.PI * 2);
      cv.stroke();
    }
  }

  if (land.length > 0) drawLandPets(cv, land, sleeping, tSec);

  // Погода поверх сцены.
  drawWeather(cv, weather, tSec, phase);

  // Бабочки.
  if (!sleeping && weather !== "thunder" && weather !== "rain") {
    drawButterflies(cv, tSec, phase);
  }

  // Декоративная рамка магазина.
  if (frame !== "none") {
    const frameColor =
      frame === "gold" ? "#FFC800" : frame === "neon" ? "#1CB0F6" : frame === "flower" ? "#7FC45C" : null;
    if (frameColor) {
      cv.strokeStyle = frameColor;
      cv.lineWidth = 6;
      cv.beginPath();
      cv.roundRect(7, 7, VB_W - 14, VB_H - 14, 18);
      cv.stroke();
      for (const [cx, cy] of [[17, 17], [383, 17], [17, 223], [383, 223]]) {
        cv.fillStyle = frameColor;
        cv.beginPath();
        cv.arc(cx, cy, 4.5, 0, Math.PI * 2);
        cv.fill();
      }
    }
  }
}

// ── React-компонент ────────────────────────────────────────────────────

export function PetScene({
  pets,
  sleeping,
  weather,
  frame = "none",
}: {
  pets: Pet[];
  sleeping: boolean;
  weather?: string | null;
  frame?: string;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const optsRef = useRef<DrawOpts>({ pets, sleeping, weather, frame, tSec: 0, phase: 0 });

  useEffect(() => {
    optsRef.current = { pets, sleeping, weather, frame, tSec: 0, phase: 0 };
  });

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    const t0 = performance.now();
    let raf = 0;
    const loop = (now: number) => {
      const tSec = (now - t0) / 1000;
      const o = optsRef.current;
      o.tSec = tSec;
      o.phase = (tSec % 4) / 4;
      const dpr = Math.min(2, window.devicePixelRatio || 1);
      const w = canvas.clientWidth;
      const h = canvas.clientHeight;
      if (w > 0 && h > 0) {
        if (canvas.width !== Math.round(w * dpr) || canvas.height !== Math.round(h * dpr)) {
          canvas.width = Math.round(w * dpr);
          canvas.height = Math.round(h * dpr);
        }
        // «cover»-кроп, как preserveAspectRatio="xMidYMid slice".
        const s = Math.max(w / VB_W, h / VB_H);
        ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
        ctx.clearRect(0, 0, w, h);
        ctx.translate((w - VB_W * s) / 2, (h - VB_H * s) / 2);
        ctx.scale(s, s);
        drawScene(ctx, o);
      }
      raf = requestAnimationFrame(loop);
    };
    raf = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(raf);
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="h-full w-full"
      role="img"
      aria-label="Сцена с питомцем"
    />
  );
}
