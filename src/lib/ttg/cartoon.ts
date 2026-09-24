// ─────────────────────────────────────────────────────────────────────
// «Росток» v2.2.0 «Мультяшные звери» — canvas-порт процедурного
// рисовальщика lib/widgets/cartoon_pet.dart. Числа совпадают 1:1.
//
// Контракт: рисует ВПРАВО в локальных координатах — (0,0) точка опоры
// (земля), вверх — отрицательный Y. Вызывающий код делает
// translate/scale(facing)/rotate. Единица u = h/10 (quad/bird/hop),
// h/3.6 (pond), h/7.2 (plant).
// ─────────────────────────────────────────────────────────────────────

import { mixColors, Pet, cartoonSpec, CartoonSpec } from "./types";

const INK_WARM = "#46362A";

export interface PetDrawOpts {
  tSec: number;
  kind?: string; // walk|sniff|graze|sit|peck|look|idle
  stride?: number;
  headPitch?: number;
  poseEase?: number;
  sleeping?: boolean;
  chewing?: boolean;
  index?: number;
}

// ── Контекст рисовальщика ───────────────────────────────────────────────

interface C {
  cv: CanvasRenderingContext2D;
  pet: Pet;
  spec: CartoonSpec;
  u: number;
  tSec: number;
  kind: string;
  stride: number;
  headPitch: number;
  poseEase: number;
  sleeping: boolean;
  chewing: boolean;
  index: number;
  inkW: number;
  blinkSeed: number;
  body: string;
  belly: string;
  accent: string;
  dark: string;
  ink: string;
}

function makeC(cv: CanvasRenderingContext2D, pet: Pet, h: number, o: PetDrawOpts): C {
  const spec = cartoonSpec(pet.type);
  const u = h / (spec.build === "pond" ? 3.6 : spec.build === "plant" ? 7.2 : 10);
  let seed = 0;
  for (let i = 0; i < pet.id.length; i++) {
    seed = (Math.imul(31, seed) + pet.id.charCodeAt(i)) | 0;
  }
  seed = seed & 0x7fffffff;
  const inkW = u * 0.42;
  let body = spec.body;
  if (pet.skin === "golden") body = mixColors(spec.body, "#FFC800", 0.45);
  if (pet.skin === "mint") body = mixColors(spec.body, "#7FD8C0", 0.45);
  if (pet.skin === "rose") body = mixColors(spec.body, "#FF9FB2", 0.45);
  return {
    cv,
    pet,
    spec,
    u,
    tSec: o.tSec,
    kind: o.kind ?? "idle",
    stride: o.stride ?? 0,
    headPitch: o.headPitch ?? 0,
    poseEase: o.poseEase ?? 0,
    sleeping: o.sleeping ?? false,
    chewing: o.chewing ?? false,
    index: o.index ?? 0,
    inkW,
    blinkSeed: (seed % 340) / 100,
    body,
    belly: spec.belly,
    accent: spec.accent ?? spec.belly,
    dark: spec.dark ?? mixColors(spec.body, INK_WARM, 0.28),
    ink: mixColors(spec.body, INK_WARM, 0.45),
  };
}

const blinkOf = (c: C) => ((c.tSec * 0.7 + c.blinkSeed) % 3.4) < 0.12;
const breathOf = (c: C) => 1 + Math.sin(c.tSec * 1.15 + c.index * 1.3) * 0.014;
const wagOf = (c: C) =>
  c.kind === "walk" ? Math.sin(c.stride) * 0.35 : Math.sin(c.tSec * 2.1 + c.index) * 0.14;

// ── Кисти ───────────────────────────────────────────────────────────────

function withAlpha(cv: CanvasRenderingContext2D, alpha: number, fn: () => void) {
  const old = cv.globalAlpha;
  cv.globalAlpha = old * alpha;
  fn();
  cv.globalAlpha = old;
}

function shape(cv: CanvasRenderingContext2D, path: Path2D, color: string, ink: string, w: number) {
  if (color !== "none" && color !== "transparent") {
    cv.fillStyle = color;
    cv.fill(path);
  }
  if (w > 0) {
    cv.strokeStyle = ink;
    cv.lineWidth = w;
    cv.lineJoin = "round";
    cv.lineCap = "round";
    cv.stroke(path);
  }
}

function circleD(cv: CanvasRenderingContext2D, x: number, y: number, r: number, color: string, ink: string, w: number) {
  cv.beginPath();
  cv.arc(x, y, r, 0, Math.PI * 2);
  if (color !== "none" && color !== "transparent") {
    cv.fillStyle = color;
    cv.fill();
  }
  if (w > 0) {
    cv.strokeStyle = ink;
    cv.lineWidth = w;
    cv.stroke();
  }
}

function ellipseD(
  cv: CanvasRenderingContext2D, x: number, y: number, rx: number, ry: number,
  color: string, ink: string, w: number, rot = 0,
) {
  cv.beginPath();
  cv.ellipse(x, y, rx, ry, rot, 0, Math.PI * 2);
  if (color !== "none" && color !== "transparent") {
    cv.fillStyle = color;
    cv.fill();
  }
  if (w > 0) {
    cv.strokeStyle = ink;
    cv.lineWidth = w;
    cv.stroke();
  }
}

function dot(cv: CanvasRenderingContext2D, x: number, y: number, r: number, color: string) {
  cv.beginPath();
  cv.arc(x, y, r, 0, Math.PI * 2);
  cv.fillStyle = color;
  cv.fill();
}

function line(cv: CanvasRenderingContext2D, x1: number, y1: number, x2: number, y2: number, color: string, w: number) {
  cv.beginPath();
  cv.moveTo(x1, y1);
  cv.lineTo(x2, y2);
  cv.strokeStyle = color;
  cv.lineWidth = w;
  cv.lineCap = "round";
  cv.stroke();
}

function tube(cv: CanvasRenderingContext2D, path: Path2D, color: string, ink: string, w: number, inkW: number) {
  cv.lineCap = "round";
  cv.lineJoin = "round";
  cv.strokeStyle = ink;
  cv.lineWidth = w + inkW * 0.9;
  cv.stroke(path);
  cv.strokeStyle = color;
  cv.lineWidth = w;
  cv.stroke(path);
}

/** Капсула между двумя точками (лапы, уши, хвосты). */
function capsulePath(a: [number, number], r1: number, b: [number, number], r2: number): Path2D {
  const ang = Math.atan2(b[1] - a[1], b[0] - a[0]);
  const nx = -Math.sin(ang), ny = Math.cos(ang);
  const p = new Path2D();
  p.moveTo(a[0] + nx * r1, a[1] + ny * r1);
  p.lineTo(b[0] + nx * r2, b[1] + ny * r2);
  p.arc(b[0], b[1], r2, ang - Math.PI / 2, ang + Math.PI / 2);
  p.lineTo(a[0] - nx * r1, a[1] - ny * r1);
  p.arc(a[0], a[1], r1, ang + Math.PI / 2, ang - Math.PI / 2);
  p.closePath();
  return p;
}

/** Лист/слеза из основания к кончику. */
function leafPath(base: [number, number], tip: [number, number], w: number): Path2D {
  const mx = (base[0] + tip[0]) / 2, my = (base[1] + tip[1]) / 2;
  const dx = tip[0] - base[0], dy = tip[1] - base[1];
  const len = Math.max(0.001, Math.sqrt(dx * dx + dy * dy));
  const nx = (-dy / len) * w, ny = (dx / len) * w;
  const p = new Path2D();
  p.moveTo(base[0], base[1]);
  p.quadraticCurveTo(mx + nx, my + ny, tip[0], tip[1]);
  p.quadraticCurveTo(mx - nx, my - ny, base[0], base[1]);
  p.closePath();
  return p;
}

// ── Глаза ───────────────────────────────────────────────────────────────

function eyeProfile(c: C, x: number, y: number, r: number) {
  const { cv } = c;
  if (c.sleeping || blinkOf(c)) {
    cv.beginPath();
    cv.moveTo(x - r * 0.9, y);
    cv.quadraticCurveTo(x, y + r, x + r * 0.9, y);
    cv.strokeStyle = c.ink;
    cv.lineWidth = c.inkW * 0.7;
    cv.lineCap = "round";
    cv.stroke();
    return;
  }
  circleD(cv, x, y, r, "#FFFFFF", c.ink, c.inkW * 0.45);
  dot(cv, x + r * 0.24, y + r * 0.04, r * 0.6, "#33261A");
  dot(cv, x + r * 0.02, y - r * 0.3, r * 0.22, "#FFFFFF");
}

function eyesFront(c: C, pts: [number, number][], r: number) {
  const { cv } = c;
  for (const [x, y] of pts) {
    if (c.sleeping || blinkOf(c)) {
      cv.beginPath();
      cv.moveTo(x - r * 0.85, y);
      cv.quadraticCurveTo(x, y + r * 0.9, x + r * 0.85, y);
      cv.strokeStyle = c.ink;
      cv.lineWidth = c.inkW * 0.7;
      cv.lineCap = "round";
      cv.stroke();
      continue;
    }
    circleD(cv, x, y, r, "#FFFFFF", c.ink, c.inkW * 0.45);
    dot(cv, x + r * 0.16, y + r * 0.05, r * 0.58, "#33261A");
    dot(cv, x - r * 0.1, y - r * 0.26, r * 0.2, "#FFFFFF");
  }
}

function blush(c: C, x: number, y: number, r: number) {
  dot(c.cv, x, y, r, "rgba(255,159,178,0.45)");
}

function mouth(c: C, x: number, y: number, w: number) {
  const { cv } = c;
  if (c.chewing && !c.sleeping) {
    ellipseD(cv, x, y, w * 0.35, w * 0.275, "#7A4238", c.ink, c.inkW * 0.5);
    return;
  }
  cv.beginPath();
  cv.moveTo(x - w / 2, y);
  cv.quadraticCurveTo(x, y + w * 0.55, x + w / 2, y);
  cv.strokeStyle = c.ink;
  cv.lineWidth = c.inkW * 0.55;
  cv.lineCap = "round";
  cv.stroke();
}

// ── Публичный вход ─────────────────────────────────────────────────────

/** Рисует питомца в мультяшном стиле (порт paintCartoonPet). */
export function paintCartoonPet(
  cv: CanvasRenderingContext2D,
  pet: Pet,
  h: number,
  o: PetDrawOpts,
) {
  const c = makeC(cv, pet, h, o);
  switch (c.spec.build) {
    case "bird":
      paintBird(c);
      break;
    case "hop":
      paintHop(c);
      break;
    case "pond":
      paintPond(c);
      break;
    case "plant":
      paintPlant(c);
      break;
    default:
      paintQuad(c);
  }
}

// ── ЧЕТВЕРОНОГИЕ ───────────────────────────────────────────────────────

const qBodyC = (c: C): [number, number] => [0.1 * c.u, -4.5 * c.u];
const qNeckBase = (c: C): [number, number] => [2.45 * c.u, -5.5 * c.u];

function qHeadC(c: C, pitch: number): [number, number] {
  const theta = -0.95 + pitch * 1.85;
  const len = (1.72 + (pitch > 0.3 ? (pitch - 0.3) * 0.9 : 0)) * c.u;
  const b = qNeckBase(c);
  return [b[0] + Math.cos(theta) * len, b[1] + Math.sin(theta) * len];
}

function paintQuad(c: C) {
  if (c.sleeping) {
    withAlpha(c.cv, 1, () => quadSleep(c));
    return;
  }
  if (c.kind === "sit" && c.poseEase > 0.01) {
    withAlpha(c.cv, Math.max(0.05, 1 - c.poseEase), () => quadStand(c));
    withAlpha(c.cv, Math.max(0.05, c.poseEase), () => quadSit(c));
    return;
  }
  quadStand(c);
}

function quadLeg(c: C, hip: [number, number], phase: number, color: string) {
  const { cv, u, inkW } = c;
  const amt = c.kind === "walk" ? 1 : 0;
  const a = Math.sin(phase) * 0.45 * amt;
  const lift = Math.max(0, Math.sin(phase + Math.PI / 2)) * 0.55 * u * amt;
  const knee: [number, number] = [
    hip[0] + 0.35 * u * 0.3 + Math.sin(a) * 2.3 * u * 0.55,
    hip[1] + Math.cos(a) * 2.3 * u * 0.55,
  ];
  const foot: [number, number] = [
    knee[0] + Math.sin(a) * 2.1 * u * 0.7,
    knee[1] + Math.cos(a) * 2.1 * u - lift,
  ];
  shape(cv, capsulePath(hip, 0.52 * u, knee, 0.4 * u), color, c.ink, inkW);
  shape(cv, capsulePath(knee, 0.4 * u, foot, 0.36 * u), color, c.ink, inkW);
  circleD(cv, foot[0] + 0.12 * u, foot[1], 0.46 * u, color, c.ink, inkW);
}

function quadStand(c: C) {
  const { cv, u, inkW } = c;
  const bodyC = qBodyC(c);
  const br = breathOf(c);
  const farC = mixColors(c.body, INK_WARM, 0.2);

  quadLeg(c, [-1.9 * u, -4.7 * u], c.stride + Math.PI, farC);
  quadLeg(c, [2.0 * u, -4.7 * u], c.stride + Math.PI, farC);

  // Дальнее крыло дракона.
  if (c.spec.extras.includes("wings")) {
    cv.save();
    cv.translate(1.1 * u, -5.7 * u);
    cv.rotate(Math.sin(c.tSec * 2.6) * 0.12 - 0.15);
    const fw = new Path2D();
    fw.moveTo(0, 0);
    fw.quadraticCurveTo(-1.6 * u, -2.6 * u, -3.0 * u, -3.1 * u);
    fw.quadraticCurveTo(-2.0 * u, -2.2 * u, -1.7 * u, -1.2 * u);
    fw.quadraticCurveTo(-0.9 * u, -1.9 * u, 0, -0.6 * u);
    fw.closePath();
    shape(cv, fw, mixColors(c.accent, INK_WARM, 0.28), c.ink, inkW * 0.8);
    cv.restore();
  }

  quadTail(c, bodyC);

  ellipseD(cv, bodyC[0], bodyC[1] + (1 - br) * 0.8 * u,
    3.0 * u * (2 - br), 1.65 * u * br, c.body, c.ink, inkW);
  ellipseD(cv, bodyC[0] + 0.4 * u, bodyC[1] + 0.7 * u,
    3.0 * u * 0.58, 1.65 * u * 0.42, c.belly, "transparent", 0);

  if (c.spec.extras.includes("spikesBack")) quadSpikes(c);
  if (c.spec.extras.includes("spots")) {
    for (const [sx, sy] of [[0.7 * u, -5.6 * u], [-0.5 * u, -5.95 * u], [-1.5 * u, -5.6 * u]]) {
      dot(cv, sx, sy, 0.24 * u, "rgba(255,255,255,0.85)");
    }
  }

  // Шея.
  const base = qNeckBase(c);
  const headC = qHeadC(c, c.headPitch);
  const theta = Math.atan2(headC[1] - base[1], headC[0] - base[0]);
  shape(
    cv,
    capsulePath(
      [base[0] - 0.2 * u, base[1] + 0.3 * u], 0.85 * u,
      [headC[0] - Math.cos(theta) * 0.9 * u, headC[1] - Math.sin(theta) * 0.9 * u], 0.7 * u,
    ),
    c.body, c.ink, inkW,
  );

  quadHead(c, headC, Math.max(0, theta) * 0.9);

  quadLeg(c, [-1.9 * u, -4.7 * u], c.stride, c.body);
  quadLeg(c, [2.0 * u, -4.7 * u], c.stride, c.body);

  accNeck(c, 2.35 * u, -5.15 * u);
}

function quadTail(c: C, bodyC: [number, number]) {
  const { cv, u, inkW } = c;
  const rump: [number, number] = [-2.6 * u, -4.9 * u];
  const tail = c.spec.tail;
  if (tail === "bushy") {
    const up = c.pet.type === "squirrel";
    const tip: [number, number] = up ? [-3.8 * u, -8.4 * u] : [-5.6 * u, -5.2 * u];
    cv.save();
    cv.translate(rump[0], rump[1]);
    cv.rotate(wagOf(c) * 0.5);
    cv.translate(-rump[0], -rump[1]);
    shape(cv, leafPath(rump, tip, 1.25 * u), c.body, c.ink, inkW);
    dot(cv, tip[0] - 0.1 * u, tip[1] + 0.25 * u, 0.6 * u, c.belly);
    if (c.spec.extras.includes("rings")) {
      for (const t of [0.35, 0.62]) {
        const mx = rump[0] + (tip[0] - rump[0]) * t;
        const my = rump[1] + (tip[1] - rump[1]) * t;
        line(cv, mx, my - 0.9 * u, mx, my + 0.9 * u, mixColors(c.body, INK_WARM, 0.28), 0.5 * u);
      }
    }
    cv.restore();
  } else if (tail === "cat") {
    const cur = new Path2D();
    cur.moveTo(-2.7 * u, -4.8 * u);
    cur.quadraticCurveTo(-4.3 * u, -5.2 * u, -4.2 * u, -7.2 * u);
    cur.quadraticCurveTo(-4.15 * u, -8.1 * u, -3.5 * u, -8.2 * u);
    cv.save();
    cv.translate(-2.7 * u, -4.8 * u);
    cv.rotate(wagOf(c) * 0.4);
    cv.translate(2.7 * u, 4.8 * u);
    tube(cv, cur, c.body, c.ink, 0.75 * u, inkW);
    dot(cv, -3.5 * u, -8.2 * u, 0.4 * u, c.accent);
    cv.restore();
  } else if (tail === "long") {
    cv.save();
    cv.translate(rump[0], rump[1]);
    cv.rotate(wagOf(c));
    cv.translate(-rump[0], -rump[1]);
    shape(cv, leafPath(rump, [-4.4 * u, -6.1 * u], 0.45 * u), c.body, c.ink, inkW * 0.8);
    cv.restore();
  } else if (tail === "mane") {
    cv.save();
    cv.translate(rump[0], rump[1]);
    cv.rotate(wagOf(c) * 0.6);
    cv.translate(-rump[0], -rump[1]);
    shape(cv, leafPath(rump, [-4.9 * u, -7.4 * u], 0.85 * u), c.accent, c.ink, inkW * 0.8);
    shape(cv, leafPath(rump, [-4.3 * u, -6.4 * u], 0.55 * u), "#FFD166", "transparent", 0);
    cv.restore();
  } else if (tail === "curl") {
    const cur = new Path2D();
    cur.moveTo(-3.0 * u, -4.7 * u);
    cur.quadraticCurveTo(-4.0 * u, -5.4 * u, -3.6 * u, -4.2 * u);
    cur.quadraticCurveTo(-3.3 * u, -3.4 * u, -2.9 * u, -4.0 * u);
    tube(cv, cur, c.body, c.ink, 0.42 * u, inkW);
  } else if (tail === "puff") {
    circleD(cv, -3.15 * u, -4.95 * u, 0.58 * u, c.body, c.ink, inkW * 0.8);
  }
}

function quadSpikes(c: C) {
  const { cv, u, inkW } = c;
  for (let i = 0; i < 7; i++) {
    const t = i / 6;
    const x = 1.5 * u - t * 4.0 * u;
    const y = -6.0 * u + Math.sin(t * Math.PI) * 0.25 * u;
    const tri = new Path2D();
    tri.moveTo(x - 0.42 * u, y + 0.25 * u);
    tri.lineTo(x, y - 1.05 * u + (i % 2 === 1 ? 0.18 * u : 0));
    tri.lineTo(x + 0.42 * u, y + 0.25 * u);
    tri.closePath();
    shape(cv, tri, c.dark, c.ink, inkW * 0.7);
  }
}

function quadHead(c: C, headC: [number, number], rot: number) {
  const { cv, u, inkW } = c;
  const headR = 1.55 * u;
  cv.save();
  cv.translate(headC[0], headC[1]);
  cv.rotate(rot);

  quadEars(c, true);
  circleD(cv, 0, 0, headR, c.body, c.ink, inkW);
  dot(cv, -0.3 * u, -0.7 * u, 0.55 * u, "rgba(255,255,255,0.12)");

  if (c.spec.extras.includes("antlers")) {
    const ant = c.accent;
    for (const side of [-0.3, 0.45]) {
      const rx = side * u;
      const ry = -1.25 * u;
      const main = new Path2D();
      main.moveTo(rx, ry);
      main.lineTo(rx + 0.35 * u, ry - 1.5 * u);
      main.moveTo(rx + 0.18 * u, ry - 0.75 * u);
      main.lineTo(rx + 0.95 * u, ry - 1.15 * u);
      main.moveTo(rx + 0.28 * u, ry - 1.15 * u);
      main.lineTo(rx + 0.8 * u, ry - 1.85 * u);
      cv.strokeStyle = ant;
      cv.lineWidth = 0.34 * u;
      cv.lineCap = "round";
      cv.stroke(main);
    }
  }
  if (c.spec.extras.includes("horn")) {
    const horn = new Path2D();
    horn.moveTo(0.15 * u, -1.2 * u);
    horn.lineTo(0.45 * u, -1.3 * u);
    horn.lineTo(0.75 * u, -2.6 * u);
    horn.closePath();
    shape(cv, horn, "#FFC800", c.ink, inkW * 0.6);
    line(cv, 0.33 * u, -1.65 * u, 0.58 * u, -1.7 * u, "#E09E00", 0.2 * u);
    shape(cv, leafPath([-0.4 * u, -1.35 * u], [0.5 * u, -1.7 * u], 0.5 * u), c.accent, c.ink, inkW * 0.5);
    shape(cv, leafPath([-1.1 * u, -0.9 * u], [-0.1 * u, -1.5 * u], 0.45 * u), "#FFD166", "transparent", 0);
  }

  quadMuzzle(c);

  if (c.spec.extras.includes("mask")) {
    if (c.pet.type === "panda") {
      ellipseD(cv, 0.5 * u, 0.02 * u, 0.62 * u, 0.72 * u, c.dark, "transparent", 0, 0.25);
    } else {
      const p = new Path2D();
      const x0 = 0.55 * u - 0.95 * u, y0 = 0.05 * u - 0.375 * u;
      p.moveTo(x0 + 0.4 * u, y0);
      p.arcTo(x0 + 1.9 * u, y0, x0 + 1.9 * u, y0 + 0.75 * u, 0.4 * u);
      p.arcTo(x0 + 1.9 * u, y0 + 0.75 * u, x0, y0 + 0.75 * u, 0.4 * u);
      p.arcTo(x0, y0 + 0.75 * u, x0, y0, 0.4 * u);
      p.arcTo(x0, y0, x0 + 1.9 * u, y0, 0.4 * u);
      p.closePath();
      shape(cv, p, c.dark, "transparent", 0);
    }
  }

  eyeProfile(c, 0.5 * u, 0, 0.52 * u);
  blush(c, 0.1 * u, 0.62 * u, 0.34 * u);

  accFace(c, 0.5 * u, 0);
  accHat(c, 0, -headR - 0.15 * u);

  quadEars(c, false);
  cv.restore();
}

function quadEars(c: C, far: boolean) {
  const { cv, u, inkW } = c;
  const ear = c.spec.ear;
  const bounce = c.kind === "walk" ? Math.sin(c.stride * 2) * 0.08 : Math.sin(c.tSec * 1.4) * 0.03;
  if (ear === "pointy") {
    const tri = (x: number, s: number): Path2D => {
      const p = new Path2D();
      p.moveTo(x - 0.42 * u * s, -0.95 * u);
      p.lineTo(x + 0.15 * u, -2.35 * u * s);
      p.lineTo(x + 0.55 * u * s, -0.85 * u);
      p.closePath();
      return p;
    };
    if (far) {
      cv.save();
      cv.translate(-0.55 * u, -0.95 * u);
      cv.rotate(-0.25 + bounce);
      cv.translate(0.55 * u, 0.95 * u);
      shape(cv, tri(-0.55 * u, 0.9), mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.7);
      cv.restore();
    } else {
      cv.save();
      cv.translate(0.15 * u, -0.95 * u);
      cv.rotate(0.12 + bounce);
      cv.translate(-0.15 * u, 0.95 * u);
      shape(cv, tri(0.15 * u, 1.0), c.body, c.ink, inkW);
      const inner = new Path2D();
      inner.moveTo(0, -1.15 * u);
      inner.lineTo(0.16 * u, -1.95 * u);
      inner.lineTo(0.38 * u, -1.05 * u);
      inner.closePath();
      shape(cv, inner, c.accent, "transparent", 0);
      cv.restore();
    }
  } else if (ear === "round") {
    const col = far
      ? mixColors(c.body, INK_WARM, 0.28)
      : c.pet.type === "panda"
        ? c.dark
        : c.body;
    if (far) {
      circleD(cv, -0.72 * u, -1.15 * u, 0.72 * u, col, c.ink, inkW * 0.7);
    } else {
      const kx = 0.5 * u + (c.pet.type === "koala" ? 0.25 * u : 0);
      const kr = (c.pet.type === "koala" ? 0.95 : 0.75) * u;
      circleD(cv, kx, -1.2 * u, kr, col, c.ink, inkW);
      if (c.pet.type === "koala") dot(cv, 0.5 * u, -1.2 * u, 0.42 * u, c.accent);
    }
  } else if (ear === "floppy") {
    if (far) {
      shape(
        cv,
        capsulePath([-0.5 * u, -1.1 * u], 0.4 * u, [-1.15 * u, 0.1 * u], 0.42 * u),
        mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.7,
      );
    } else {
      const col = c.pet.type === "dog" ? c.accent : mixColors(c.body, INK_WARM, 0.28);
      cv.save();
      cv.translate(0.35 * u, -1.05 * u);
      cv.rotate(0.1 + bounce * 1.5);
      shape(cv, capsulePath([0, 0], 0.42 * u, [0.1 * u, 1.3 * u], 0.46 * u), col, c.ink, inkW);
      cv.restore();
    }
  } else if (ear === "long") {
    if (far) {
      ellipseD(cv, -0.85 * u, -1.0 * u, 0.72 * u, 0.34 * u,
        mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.6, -0.75);
    } else {
      cv.save();
      cv.translate(0.35 * u, -1.1 * u);
      cv.rotate(0.45 + bounce);
      ellipseD(cv, 0, 0, 0.78 * u, 0.36 * u, c.body, c.ink, inkW);
      ellipseD(cv, 0.06 * u, 0, 0.4 * u, 0.16 * u, c.belly, "transparent", 0);
      cv.restore();
    }
  } else if (ear === "tufts") {
    if (!far) {
      shape(cv, leafPath([-0.15 * u, -1.3 * u], [-0.45 * u, -2.15 * u], 0.22 * u), c.body, c.ink, inkW * 0.6);
      shape(cv, leafPath([0.35 * u, -1.35 * u], [0.65 * u, -2.1 * u], 0.22 * u), c.body, c.ink, inkW * 0.6);
    }
  }
}

function quadMuzzle(c: C) {
  const { cv, u, inkW } = c;
  switch (c.spec.muzzle) {
    case "fox": {
      const wedge = new Path2D();
      wedge.moveTo(0.25 * u, -0.35 * u);
      wedge.quadraticCurveTo(1.3 * u, -0.15 * u, 1.75 * u, 0.22 * u);
      wedge.quadraticCurveTo(1.15 * u, 0.8 * u, 0.3 * u, 0.75 * u);
      wedge.closePath();
      shape(cv, wedge, c.belly, c.ink, inkW * 0.7);
      dot(cv, 1.62 * u, 0.18 * u, 0.21 * u, c.ink);
      mouth(c, 1.15 * u, 0.6 * u, 0.55 * u);
      break;
    }
    case "cat": {
      ellipseD(cv, 0.85 * u, 0.42 * u, 0.55 * u, 0.42 * u, c.belly, "transparent", 0);
      const nose = new Path2D();
      nose.moveTo(0.82 * u, 0.02 * u);
      nose.lineTo(1.12 * u, 0.02 * u);
      nose.lineTo(0.97 * u, 0.22 * u);
      nose.closePath();
      shape(cv, nose, c.accent, c.ink, inkW * 0.35);
      for (const dy of [-0.12, 0.1]) {
        line(cv, 1.15 * u, 0.28 * u + dy * u, 1.7 * u, 0.18 * u + dy * u * 2.2, c.ink, inkW * 0.35);
      }
      mouth(c, 0.97 * u, 0.42 * u, 0.5 * u);
      break;
    }
    case "bear": {
      circleD(cv, 0.85 * u, 0.4 * u, 0.72 * u, c.belly, c.ink, inkW * 0.55);
      ellipseD(cv, 1.05 * u, 0.2 * u, 0.26 * u, 0.2 * u, c.ink, "transparent", 0);
      mouth(c, 1.0 * u, 0.55 * u, 0.5 * u);
      break;
    }
    case "long": {
      shape(
        cv,
        capsulePath([0.3 * u, 0.2 * u], 0.62 * u, [1.75 * u, 0.4 * u], 0.42 * u),
        c.belly, c.ink, inkW * 0.6,
      );
      dot(cv, 1.62 * u, 0.32 * u, 0.13 * u, c.ink);
      mouth(c, 1.35 * u, 0.68 * u, 0.5 * u);
      break;
    }
    case "snout": {
      ellipseD(cv, 1.0 * u, 0.3 * u, 0.6 * u, 0.48 * u, c.accent, c.ink, inkW * 0.6);
      dot(cv, 0.85 * u, 0.28 * u, 0.09 * u, c.ink);
      dot(cv, 1.16 * u, 0.28 * u, 0.09 * u, c.ink);
      break;
    }
    case "flat": {
      ellipseD(cv, 0.85 * u, 0.16 * u, 0.3 * u, 0.22 * u, c.ink, "transparent", 0);
      line(cv, 0.82 * u, 0.4 * u, 0.88 * u, 0.55 * u, c.ink, inkW * 0.4);
      line(cv, 0.88 * u, 0.55 * u, 1.0 * u, 0.62 * u, c.ink, inkW * 0.4);
      line(cv, 0.88 * u, 0.55 * u, 0.76 * u, 0.62 * u, c.ink, inkW * 0.4);
      if (c.pet.type === "bunny") {
        for (const dy of [-0.1, 0.12]) {
          line(cv, 1.05 * u, 0.3 * u + dy * u, 1.6 * u, 0.2 * u + dy * u * 2.4, c.ink, inkW * 0.35);
        }
      }
      break;
    }
    default:
      break;
  }
}

function quadSleep(c: C) {
  const { cv, u, inkW } = c;
  const br = breathOf(c);

  if (c.spec.tail === "bushy" || c.spec.tail === "mane") {
    shape(
      cv,
      leafPath([-2.2 * u, -1.5 * u], [1.2 * u, -0.55 * u], 0.8 * u),
      c.spec.tail === "mane" ? c.accent : c.body, c.ink, inkW * 0.8,
    );
    dot(cv, 1.15 * u, -0.6 * u, 0.42 * u, c.belly);
  } else if (c.spec.tail === "long") {
    shape(cv, leafPath([-2.2 * u, -1.3 * u], [0.6 * u, -0.5 * u], 0.4 * u), c.body, c.ink, inkW * 0.7);
  }

  ellipseD(cv, -0.1 * u, -1.3 * u, 3.15 * u * (2 - br) * 0.92, 1.2 * u * br, c.body, c.ink, inkW);
  ellipseD(cv, -0.4 * u, -0.9 * u, 2.2 * u, 0.72 * u, c.belly, "transparent", 0);
  if (c.spec.extras.includes("spikesBack")) {
    for (let i = 0; i < 5; i++) {
      const x = (0.9 - i * 1.05) * u;
      const tri = new Path2D();
      tri.moveTo(x - 0.4 * u, -2.15 * u);
      tri.lineTo(x, -3.0 * u);
      tri.lineTo(x + 0.4 * u, -2.15 * u);
      tri.closePath();
      shape(cv, tri, c.dark, c.ink, inkW * 0.6);
    }
  }

  shape(
    cv,
    capsulePath([1.9 * u, -0.5 * u], 0.42 * u, [3.2 * u, -0.5 * u], 0.36 * u),
    c.body, c.ink, inkW * 0.8,
  );

  circleD(cv, 2.9 * u, -1.5 * u, 1.32 * u, c.body, c.ink, inkW);
  cv.save();
  cv.translate(2.9 * u, -1.5 * u);
  cv.rotate(0.25);
  quadEars(c, true);
  quadMuzzleSleep(c);
  eyeProfile(c, 0.5 * u, 0, 0.5 * u);
  blush(c, 0.05 * u, 0.6 * u, 0.32 * u);
  quadEars(c, false);
  cv.restore();
}

function quadMuzzleSleep(c: C) {
  const { cv, u, inkW } = c;
  switch (c.spec.muzzle) {
    case "fox": {
      const wedge = new Path2D();
      wedge.moveTo(0.2 * u, -0.3 * u);
      wedge.quadraticCurveTo(1.1 * u, -0.1 * u, 1.5 * u, 0.25 * u);
      wedge.quadraticCurveTo(1.0 * u, 0.65 * u, 0.25 * u, 0.62 * u);
      wedge.closePath();
      shape(cv, wedge, c.belly, c.ink, inkW * 0.6);
      dot(cv, 1.4 * u, 0.2 * u, 0.18 * u, c.ink);
      break;
    }
    case "bear": {
      circleD(cv, 0.8 * u, 0.35 * u, 0.62 * u, c.belly, c.ink, inkW * 0.5);
      ellipseD(cv, 0.95 * u, 0.18 * u, 0.22 * u, 0.17 * u, c.ink, "transparent", 0);
      break;
    }
    case "long": {
      shape(
        cv,
        capsulePath([0.25 * u, 0.15 * u], 0.55 * u, [1.6 * u, 0.35 * u], 0.38 * u),
        c.belly, c.ink, inkW * 0.55,
      );
      break;
    }
    case "snout": {
      ellipseD(cv, 0.95 * u, 0.28 * u, 0.55 * u, 0.44 * u, c.accent, c.ink, inkW * 0.55);
      break;
    }
    default: {
      ellipseD(cv, 0.8 * u, 0.15 * u, 0.26 * u, 0.2 * u, c.ink, "transparent", 0);
      break;
    }
  }
}

function quadSit(c: C) {
  const { cv, u, inkW } = c;
  const br = breathOf(c);

  if (c.spec.tail === "bushy" || c.spec.tail === "mane") {
    shape(
      cv,
      leafPath([-1.9 * u, -0.9 * u], [0.9 * u, -0.5 * u], 0.85 * u),
      c.spec.tail === "mane" ? c.accent : c.body, c.ink, inkW * 0.8,
    );
    dot(cv, 0.85 * u, -0.55 * u, 0.45 * u, c.belly);
  } else if (c.spec.tail === "long") {
    cv.save();
    cv.translate(-1.9 * u, -1.0 * u);
    cv.rotate(wagOf(c) * 1.2);
    shape(cv, leafPath([0, 0], [2.6 * u, -0.4 * u], 0.42 * u), c.body, c.ink, inkW * 0.7);
    cv.restore();
  } else if (c.spec.tail === "cat") {
    cv.save();
    cv.translate(-1.9 * u, -1.0 * u);
    cv.rotate(wagOf(c) * 0.8);
    const cur = new Path2D();
    cur.moveTo(0, 0);
    cur.quadraticCurveTo(-1.6 * u, -0.4 * u, -2.4 * u, -1.8 * u);
    tube(cv, cur, c.body, c.ink, 0.7 * u, inkW);
    dot(cv, -2.4 * u, -1.8 * u, 0.38 * u, c.accent);
    cv.restore();
  }

  // Сложенная задняя лапа.
  shape(
    cv,
    capsulePath([-1.5 * u, -2.4 * u], 0.62 * u, [-0.1 * u, -1.5 * u], 0.5 * u),
    c.body, c.ink, inkW,
  );
  shape(
    cv,
    capsulePath([-0.1 * u, -1.5 * u], 0.42 * u, [-0.35 * u, -0.45 * u], 0.38 * u),
    c.body, c.ink, inkW,
  );
  circleD(cv, -0.4 * u, -0.35 * u, 0.42 * u, c.body, c.ink, inkW);

  // Корпус наклонно.
  cv.save();
  cv.translate(-1.7 * u, -1.6 * u);
  cv.rotate(-0.52);
  ellipseD(cv, 0.2 * u, -1.55 * u * br, 3.0 * u * 0.95 * (2 - br), 1.65 * u * br, c.body, c.ink, inkW);
  ellipseD(cv, 0.5 * u, -0.8 * u, 3.0 * u * 0.55, 1.65 * u * 0.45, c.belly, "transparent", 0);
  cv.restore();

  // Передние лапы.
  for (const dx of [-0.25, 0]) {
    const col = dx < 0 ? mixColors(c.body, INK_WARM, 0.28) : c.body;
    shape(
      cv,
      capsulePath([1.55 * u + dx * u, -4.1 * u], 0.4 * u, [1.62 * u + dx * u, -0.45 * u], 0.36 * u),
      col, c.ink, inkW,
    );
    circleD(cv, 1.66 * u + dx * u, -0.4 * u, 0.44 * u, col, c.ink, inkW);
  }

  // Шея и голова.
  const base: [number, number] = [2.1 * u, -5.0 * u];
  const pitch = c.headPitch * 0.35 + 0.12;
  const theta = -0.85 + pitch;
  const headC: [number, number] = [
    base[0] + Math.cos(theta) * 1.8 * u,
    base[1] + Math.sin(theta) * 1.8 * u,
  ];
  shape(cv, capsulePath(base, 0.8 * u, headC, 0.68 * u), c.body, c.ink, inkW);
  quadHead(c, headC, Math.max(0, pitch) * 0.9);
  accNeck(c, 1.95 * u, -4.6 * u);
}

// ── ПТИЦЫ ──────────────────────────────────────────────────────────────

function paintBird(c: C) {
  const { cv, u, inkW } = c;
  if (c.sleeping) {
    birdSleep(c);
    return;
  }
  const isOwl = c.pet.type === "owl";
  const isPenguin = c.pet.type === "penguin";

  const peck = c.kind === "peck" ? c.headPitch : 0;
  cv.save();
  if (peck > 0.01) {
    cv.translate(1.0 * u, -0.6 * u);
    cv.rotate(peck * 0.5);
    cv.translate(-1.0 * u, 0.6 * u);
  }
  cv.rotate(c.kind === "walk" ? Math.sin(c.stride) * 0.05 : 0);

  // Лапки.
  const legC = isPenguin ? c.accent : mixColors(c.accent, INK_WARM, 0.28);
  for (const dx of [-0.8, 0.8]) {
    const lift = c.kind === "walk"
      ? Math.max(0, Math.sin(c.stride + (dx > 0 ? 0 : Math.PI))) * 0.5 * u
      : 0;
    shape(
      cv,
      capsulePath([dx * u, -1.2 * u], 0.24 * u, [dx * u * 1.15, -0.3 * u - lift], 0.22 * u),
      legC, c.ink, inkW * 0.7,
    );
    line(cv, dx * u * 1.15, -0.3 * u - lift, dx * u * 1.15 + 0.4 * u, -lift, c.ink, inkW * 0.6);
    line(cv, dx * u * 1.15, -0.3 * u - lift, dx * u * 1.15 - 0.15 * u, -lift, c.ink, inkW * 0.6);
  }

  // Хвост.
  if (c.spec.tail === "plume") {
    for (const ang of [-0.5, 0, 0.5]) {
      cv.save();
      cv.translate(-1.9 * u, -3.4 * u);
      cv.rotate(ang);
      shape(
        cv,
        leafPath([0, 0], [-1.6 * u, 0.4 * u], 0.42 * u),
        mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.7,
      );
      cv.restore();
    }
  } else if (c.spec.tail === "flat") {
    cv.save();
    cv.translate(-2.0 * u, -4.4 * u);
    cv.rotate(-0.5 + wagOf(c) * 0.8);
    shape(cv, leafPath([0, 0], [-1.4 * u, -0.5 * u], 0.55 * u), c.body, c.ink, inkW * 0.8);
    cv.restore();
  }

  // Тело-яйцо.
  const br = breathOf(c);
  ellipseD(cv, 0, -4.0 * u, 2.45 * u, 3.15 * u * br, c.body, c.ink, inkW);

  // Животик.
  if (isPenguin) {
    ellipseD(cv, 0.35 * u, -3.6 * u, 1.7 * u, 2.5 * u, c.belly, "transparent", 0);
    circleD(cv, 0.55 * u, -6.5 * u, 1.25 * u, c.belly, "transparent", 0);
  } else {
    ellipseD(cv, 0.3 * u, -3.7 * u, 1.65 * u, 2.3 * u, c.belly, "transparent", 0);
    if (isOwl) {
      for (const [ox, oy] of [[-0.1 * u, -3.4 * u], [0.7 * u, -4.2 * u], [0.2 * u, -4.9 * u]]) {
        const v = new Path2D();
        v.moveTo(ox - 0.22 * u, oy - 0.2 * u);
        v.lineTo(ox, oy + 0.12 * u);
        v.lineTo(ox + 0.22 * u, oy - 0.2 * u);
        cv.strokeStyle = mixColors(c.belly, INK_WARM, 0.28);
        cv.lineWidth = inkW * 0.4;
        cv.lineCap = "round";
        cv.stroke(v);
      }
    }
  }

  // Хохолок цыплёнка.
  if (c.spec.ear === "tuft") {
    for (const dx of [-0.25, 0.05, 0.35]) {
      line(cv, dx * u, -7.2 * u, dx * u + 0.18 * u, -7.9 * u, c.accent, 0.28 * u);
    }
  }

  // Крыло.
  cv.save();
  cv.translate(-0.5 * u, -4.3 * u);
  cv.rotate(c.kind === "peck" ? -c.headPitch * 0.4 : Math.sin(c.tSec * 1.8) * 0.04);
  ellipseD(cv, -0.15 * u, 0.2 * u, 1.05 * u, 1.75 * u,
    isPenguin ? c.dark : mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.8, 0.3);
  cv.restore();

  // Голова/лицо.
  if (isOwl) {
    circleD(cv, 0.35 * u, -6.7 * u, 1.9 * u, c.body, c.ink, inkW * 0.8);
    for (const dx of [-0.85, 0.95]) {
      const tuft = new Path2D();
      tuft.moveTo(dx * u - 0.3 * u, -7.9 * u);
      tuft.lineTo(dx * u + 0.1 * u, -9.1 * u);
      tuft.lineTo(dx * u + 0.42 * u, -7.7 * u);
      tuft.closePath();
      shape(cv, tuft, c.body, c.ink, inkW * 0.6);
    }
    eyesFront(c, [[-0.15 * u, -6.85 * u], [0.95 * u, -6.75 * u]], 0.68 * u);
    const beak = new Path2D();
    beak.moveTo(0.28 * u, -6.1 * u);
    beak.lineTo(0.78 * u, -6.1 * u);
    beak.lineTo(0.53 * u, -5.45 * u);
    beak.closePath();
    shape(cv, beak, c.accent, c.ink, inkW * 0.55);
    blush(c, -0.75 * u, -5.9 * u, 0.34 * u);
    blush(c, 1.45 * u, -5.85 * u, 0.3 * u);
    accFace(c, 0.95 * u, -6.75 * u);
    accHat(c, 0.1 * u, -8.65 * u);
  } else {
    if (!isPenguin) {
      circleD(cv, 0.55 * u, -6.9 * u, 1.5 * u, c.body, c.ink, inkW);
    }
    if (c.spec.ear === "tufts") {
      shape(cv, leafPath([0.35 * u, -8.2 * u], [0.15 * u, -8.9 * u], 0.2 * u), c.body, c.ink, inkW * 0.5);
    }
    eyeProfile(c, 0.85 * u, -7.15 * u, 0.5 * u);
    ellipseD(cv, 1.85 * u, -6.85 * u, 0.72 * u, 0.26 * u, c.accent, c.ink, inkW * 0.55, 0.06);
    ellipseD(cv, 1.8 * u, -6.6 * u, 0.5 * u, 0.16 * u,
      mixColors(c.accent, "#000000", 0.12), "transparent", 0);
    blush(c, 0.35 * u, -6.45 * u, 0.3 * u);
    accFace(c, 0.85 * u, -7.15 * u);
    accHat(c, 0.4 * u, -8.45 * u);
  }

  accNeck(c, 0.1 * u, -2.2 * u);
  cv.restore();
}

function birdSleep(c: C) {
  const { cv, u, inkW } = c;
  const isPenguin = c.pet.type === "penguin";
  const br = breathOf(c);
  ellipseD(cv, 0, -1.75 * u, 2.2 * u, 1.75 * u * br, c.body, c.ink, inkW);
  if (isPenguin) {
    ellipseD(cv, 0.3 * u, -1.5 * u, 1.55 * u, 1.3 * u, c.belly, "transparent", 0);
  }
  ellipseD(cv, -0.55 * u, -1.9 * u, 0.95 * u, 1.1 * u,
    isPenguin ? c.dark : mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.7, 0.3);
  if (c.pet.type === "owl") {
    circleD(cv, 0.5 * u, -3.1 * u, 1.5 * u, c.body, c.ink, inkW);
    eyesFront(c, [[0.2 * u, -3.25 * u], [1.0 * u, -3.15 * u]], 0.5 * u);
    const beak = new Path2D();
    beak.moveTo(0.42 * u, -2.75 * u);
    beak.lineTo(0.82 * u, -2.75 * u);
    beak.lineTo(0.62 * u, -2.25 * u);
    beak.closePath();
    shape(cv, beak, c.accent, c.ink, inkW * 0.5);
  } else {
    circleD(cv, 0.7 * u, -3.0 * u, 1.25 * u, c.body, c.ink, inkW);
    eyeProfile(c, 0.95 * u, -3.15 * u, 0.42 * u);
    ellipseD(cv, 1.75 * u, -2.95 * u, 0.6 * u, 0.22 * u, c.accent, c.ink, inkW * 0.5, 0.1);
  }
  blush(c, 0.35 * u, -2.6 * u, 0.28 * u);
}

// ── ПРЫГУНЫ ────────────────────────────────────────────────────────────

function paintHop(c: C) {
  const { u } = c;
  if (c.pet.type === "frog") {
    frog(c);
    return;
  }
  const { cv, inkW } = c;
  const br = breathOf(c);
  if (c.sleeping) {
    ellipseD(cv, 0.2 * u, -1.15 * u, 2.5 * u, 1.1 * u * br, c.body, c.ink, inkW);
    shape(cv, leafPath([2.4 * u, -1.8 * u], [-0.6 * u, -2.5 * u], 0.45 * u), c.body, c.ink, inkW * 0.7);
    shape(cv, leafPath([2.5 * u, -1.5 * u], [-0.2 * u, -2.75 * u], 0.42 * u), c.body, c.ink, inkW * 0.7);
    circleD(cv, 2.6 * u, -1.5 * u, 1.15 * u, c.body, c.ink, inkW);
    eyeProfile(c, 3.0 * u, -1.7 * u, 0.42 * u);
    ellipseD(cv, 3.4 * u, -1.3 * u, 0.24 * u, 0.18 * u, c.accent, "transparent", 0);
    circleD(cv, -2.1 * u, -1.5 * u, 0.6 * u, c.belly, c.ink, inkW * 0.6);
    return;
  }

  circleD(cv, -2.75 * u, -2.7 * u, 0.72 * u, c.belly, c.ink, inkW * 0.7);
  circleD(cv, -1.1 * u, -2.3 * u, 1.75 * u, c.body, c.ink, inkW);
  const kick = c.kind === "walk" ? Math.sin(c.stride) * 0.18 : 0;
  cv.save();
  cv.translate(-0.4 * u, -0.9 * u);
  cv.rotate(kick);
  shape(cv, capsulePath([0, 0], 0.48 * u, [1.5 * u, -0.1 * u], 0.42 * u), c.belly, c.ink, inkW * 0.8);
  cv.restore();
  ellipseD(cv, 0.35 * u, -4.1 * u * br, 2.15 * u * (2 - br), 2.35 * u * br, c.body, c.ink, inkW);
  ellipseD(cv, 0.55 * u, -2.6 * u, 1.4 * u, 1.15 * u, c.belly, "transparent", 0);
  shape(
    cv,
    capsulePath([2.1 * u, -1.3 * u], 0.32 * u, [2.4 * u, -0.4 * u], 0.3 * u),
    c.body, c.ink, inkW * 0.8,
  );
  circleD(cv, 1.9 * u, -6.5 * u, 1.6 * u, c.body, c.ink, inkW);
  const bounce = c.kind === "walk" ? Math.sin(c.stride * 2) * 0.12 : Math.sin(c.tSec * 1.3) * 0.04;
  cv.save();
  cv.translate(1.35 * u, -7.7 * u);
  cv.rotate(-0.22 + bounce);
  shape(
    cv,
    capsulePath([0, 0], 0.44 * u, [-0.15 * u, -2.5 * u], 0.36 * u),
    mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.8,
  );
  cv.restore();
  cv.save();
  cv.translate(2.0 * u, -7.85 * u);
  cv.rotate(0.1 + bounce);
  shape(cv, capsulePath([0, 0], 0.48 * u, [0.25 * u, -2.6 * u], 0.4 * u), c.body, c.ink, inkW);
  shape(
    cv,
    capsulePath([0.06 * u, -0.35 * u], 0.22 * u, [0.22 * u, -2.15 * u], 0.18 * u),
    c.accent, "transparent", 0,
  );
  cv.restore();
  eyeProfile(c, 2.45 * u, -6.6 * u, 0.5 * u);
  dot(cv, 3.25 * u, -6.35 * u, 0.17 * u, c.ink);
  mouth(c, 3.0 * u, -5.95 * u, 0.42 * u);
  for (const dy of [-0.1, 0.12]) {
    line(cv, 3.35 * u, -6.2 * u + dy * u, 3.95 * u, -6.35 * u + dy * u * 2.4, c.ink, inkW * 0.35);
  }
  blush(c, 1.75 * u, -5.95 * u, 0.3 * u);
  accFace(c, 2.45 * u, -6.6 * u);
  accHat(c, 1.75 * u, -8.2 * u);
  accNeck(c, 1.2 * u, -5.2 * u);
}

function frog(c: C) {
  const { cv, u, inkW } = c;
  const br = breathOf(c);
  if (c.sleeping) {
    ellipseD(cv, 0, -0.85 * u, 2.35 * u, 0.85 * u * br, c.body, c.ink, inkW);
    circleD(cv, 0.7 * u, -1.5 * u, 0.62 * u, c.body, c.ink, inkW * 0.7);
    circleD(cv, -0.6 * u, -1.55 * u, 0.62 * u, c.body, c.ink, inkW * 0.7);
    line(cv, 0.45 * u, -1.5 * u, 0.95 * u, -1.5 * u, c.ink, inkW * 0.5);
    line(cv, -0.85 * u, -1.55 * u, -0.35 * u, -1.55 * u, c.ink, inkW * 0.5);
    return;
  }
  for (const dx of [-1.0, 0.2]) {
    shape(
      cv,
      capsulePath([dx * u, -1.7 * u], 0.55 * u, [dx * u - 0.9 * u, -0.7 * u], 0.42 * u),
      mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.8,
    );
  }
  ellipseD(cv, 0, -1.75 * u * br, 2.55 * u * (2 - br), 1.7 * u * br, c.body, c.ink, inkW);
  ellipseD(cv, 0.3 * u, -1.05 * u, 1.7 * u, 0.85 * u, c.belly, "transparent", 0);
  ellipseD(cv, 1.2 * u, -1.15 * u, 0.75 * u, 0.5 * u * (1 + Math.sin(c.tSec * 3.1) * 0.12),
    c.belly, "transparent", 0);
  circleD(cv, 0.85 * u, -3.1 * u, 0.72 * u, c.body, c.ink, inkW);
  circleD(cv, -0.65 * u, -3.15 * u, 0.72 * u, mixColors(c.body, INK_WARM, 0.28), c.ink, inkW);
  eyesFront(c, [[0.95 * u, -3.2 * u]], 0.45 * u);
  eyesFront(c, [[-0.55 * u, -3.25 * u]], 0.45 * u);
  const smile = new Path2D();
  smile.moveTo(0.1 * u, -2.1 * u);
  smile.quadraticCurveTo(1.4 * u, -1.7 * u, 2.15 * u, -2.2 * u);
  cv.strokeStyle = c.ink;
  cv.lineWidth = inkW * 0.55;
  cv.lineCap = "round";
  cv.stroke(smile);
  blush(c, 1.7 * u, -2.6 * u, 0.3 * u);
  accFace(c, 0.95 * u, -3.2 * u);
  accHat(c, -0.3 * u, -3.85 * u);
}

// ── ВОДНЫЕ ЖИТЕЛИ ──────────────────────────────────────────────────────

function paintPond(c: C) {
  switch (c.pet.type) {
    case "whale":
      whale(c);
      break;
    case "seal":
      seal(c);
      break;
    case "turtle":
      turtle(c);
      break;
    case "octopus":
      octopus(c);
      break;
    default:
      crab(c);
  }
}

function pondEyeSmile(c: C, ex: number, ey: number, sx: number, sy: number) {
  eyeProfile(c, ex, ey, 0.3 * c.u);
  mouth(c, sx, sy, 0.5 * c.u);
  blush(c, sx - 0.15 * c.u, sy + 0.35 * c.u, 0.26 * c.u);
}

function whale(c: C) {
  const { cv, u, inkW } = c;
  const br = breathOf(c);
  const wag = c.sleeping ? 0 : Math.sin(c.tSec * 2.2) * 0.16;

  cv.save();
  cv.translate(-3.6 * u, -1.9 * u);
  cv.rotate(wag);
  shape(cv, leafPath([0.3 * u, 0], [-1.6 * u, -1.0 * u], 0.55 * u), c.body, c.ink, inkW * 0.8);
  shape(cv, leafPath([0.3 * u, 0], [-1.6 * u, 0.9 * u], 0.55 * u), c.body, c.ink, inkW * 0.8);
  cv.restore();

  const body = new Path2D();
  body.moveTo(4.3 * u, -1.9 * u);
  body.quadraticCurveTo(3.4 * u, -3.35 * u * br, 0.2 * u, -3.25 * u * br);
  body.quadraticCurveTo(-3.2 * u, -3.1 * u * br, -3.9 * u, -1.7 * u);
  body.quadraticCurveTo(-1.5 * u, -0.55 * u, 0.8 * u, -0.6 * u);
  body.quadraticCurveTo(3.1 * u, -0.65 * u, 4.3 * u, -1.9 * u);
  body.closePath();
  shape(cv, body, c.body, c.ink, inkW);

  const belly = new Path2D();
  belly.moveTo(3.9 * u, -1.55 * u);
  belly.quadraticCurveTo(1.5 * u, -0.55 * u, -1.5 * u, -0.7 * u);
  belly.quadraticCurveTo(0.5 * u, -1.5 * u, 3.9 * u, -1.55 * u);
  belly.closePath();
  cv.fillStyle = c.belly;
  cv.fill(belly);
  for (const dx of [-0.6, 0.6, 1.8]) {
    const groove = new Path2D();
    groove.moveTo(dx * u, -0.75 * u);
    groove.quadraticCurveTo(dx * u + 0.3 * u, -1.1 * u, dx * u + 0.15 * u, -1.45 * u);
    cv.strokeStyle = mixColors(c.belly, INK_WARM, 0.28);
    cv.lineWidth = inkW * 0.35;
    cv.lineCap = "round";
    cv.stroke(groove);
  }
  cv.save();
  cv.translate(0.9 * u, -1.05 * u);
  cv.rotate(Math.sin(c.tSec * 2.6) * 0.12);
  shape(cv, leafPath([0, 0], [0.7 * u, 0.75 * u], 0.4 * u),
    mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.7);
  cv.restore();
  pondEyeSmile(c, 3.1 * u, -2.35 * u, 3.55 * u, -1.7 * u);
}

function seal(c: C) {
  const { cv, u, inkW } = c;
  const br = breathOf(c);
  cv.save();
  cv.translate(-3.1 * u, -1.5 * u);
  cv.rotate(c.sleeping ? 0 : Math.sin(c.tSec * 2) * 0.14);
  shape(cv, leafPath([0, 0], [-1.1 * u, -0.7 * u], 0.45 * u), c.body, c.ink, inkW * 0.7);
  shape(cv, leafPath([0, 0], [-1.1 * u, 0.6 * u], 0.45 * u), c.body, c.ink, inkW * 0.7);
  cv.restore();
  ellipseD(cv, 0.2 * u, -1.55 * u * br, 3.4 * u * (2 - br), 1.35 * u * br, c.body, c.ink, inkW);
  circleD(cv, 2.9 * u, -1.8 * u, 1.15 * u, c.body, c.ink, inkW);
  ellipseD(cv, 2.2 * u, -1.0 * u, 1.4 * u, 0.7 * u, c.belly, "transparent", 0);
  dot(cv, 3.85 * u, -1.95 * u, 0.15 * u, c.ink);
  for (const dy of [-0.1, 0.08]) {
    line(cv, 3.7 * u, -1.75 * u + dy * u, 4.35 * u, -1.85 * u + dy * u * 2, c.ink, inkW * 0.3);
  }
  shape(cv, leafPath([1.4 * u, -0.9 * u], [2.1 * u, -0.15 * u], 0.4 * u),
    mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.7);
  pondEyeSmile(c, 3.15 * u, -2.1 * u, 3.6 * u, -1.5 * u);
}

function turtle(c: C) {
  const { cv, u, inkW } = c;
  const legs: [number, number, boolean][] = [
    [2.1, 0, true], [-2.1, Math.PI, true], [1.6, Math.PI / 2, false], [-1.6, -Math.PI / 2, false],
  ];
  for (const [x, ph, near] of legs) {
    const sw = c.sleeping ? 0 : Math.sin(c.tSec * 2.8 + ph) * 0.3;
    cv.save();
    cv.translate(x * u, -0.55 * u);
    cv.rotate(sw);
    shape(
      cv,
      capsulePath([0, 0], 0.34 * u, [0.15 * u, 0.5 * u], 0.28 * u),
      near ? c.body : mixColors(c.body, INK_WARM, 0.28), c.ink, inkW * 0.7,
    );
    cv.restore();
  }
  shape(cv, leafPath([-3.0 * u, -1.0 * u], [-3.7 * u, -0.7 * u], 0.25 * u), c.body, c.ink, inkW * 0.6);
  const br = breathOf(c);
  const shell = new Path2D();
  shell.moveTo(2.75 * u, -0.75 * u);
  shell.quadraticCurveTo(2.3 * u, -2.95 * u * br, 0, -2.95 * u * br);
  shell.quadraticCurveTo(-2.3 * u, -2.95 * u * br, -2.75 * u, -0.75 * u);
  shell.closePath();
  shape(cv, shell, c.dark, c.ink, inkW);
  for (const dx of [-1.3, 0, 1.3]) {
    const plate = new Path2D();
    plate.moveTo(dx * u - 0.55 * u, -0.8 * u);
    plate.quadraticCurveTo(dx * u, -2.3 * u, dx * u + 0.55 * u, -0.8 * u);
    cv.strokeStyle = mixColors(c.dark, "#FFFFFF", 0.18);
    cv.lineWidth = inkW * 0.4;
    cv.lineCap = "round";
    cv.stroke(plate);
  }
  ellipseD(cv, 0, -0.72 * u, 2.95 * u, 0.42 * u, c.body, c.ink, inkW * 0.7);
  circleD(cv, 3.3 * u, -1.25 * u, 0.85 * u, c.body, c.ink, inkW);
  pondEyeSmile(c, 3.5 * u, -1.4 * u, 3.8 * u, -0.95 * u);
}

function octopus(c: C) {
  const { cv, u, inkW } = c;
  const br = breathOf(c);
  for (let i = 0; i < 5; i++) {
    const bx = (-1.4 + i * 0.7) * u;
    const wave = c.sleeping ? 0 : Math.sin(c.tSec * 2 + i * 1.25) * 0.55 * u;
    const curl = c.sleeping ? 0.5 : 0.9;
    const arm = new Path2D();
    arm.moveTo(bx, -1.3 * u);
    arm.quadraticCurveTo(bx - 0.2 * u, -0.5 * u, bx - 0.1 * u + wave * 0.4, 0.05 * u);
    arm.quadraticCurveTo(bx + wave, 0.45 * u * curl, bx + wave * 0.4, 0.1 * u);
    cv.lineCap = "round";
    cv.strokeStyle = c.ink;
    cv.lineWidth = 0.85 * u;
    cv.stroke(arm);
    cv.strokeStyle = c.body;
    cv.lineWidth = 0.55 * u;
    cv.stroke(arm);
    if (i === 2 && c.spec.extras.includes("suckers")) {
      for (const t of [0.3, 0.55, 0.8]) {
        dot(cv, bx + wave * 0.4 * t, -1.3 * u + 1.35 * u * t, 0.1 * u, c.belly);
      }
    }
  }
  ellipseD(cv, 0, -2.7 * u * br, 2.05 * u * (2 - br) * 0.9, 2.1 * u * br, c.body, c.ink, inkW);
  eyesFront(c, [[-0.5 * u, -2.9 * u], [0.75 * u, -2.85 * u]], 0.48 * u);
  mouth(c, 0.15 * u, -1.95 * u, 0.55 * u);
  blush(c, -0.95 * u, -2.2 * u, 0.3 * u);
  blush(c, 1.25 * u, -2.15 * u, 0.3 * u);
  accHat(c, 0, -4.85 * u);
}

function crab(c: C) {
  const { cv, u, inkW } = c;
  const legs: [number, number, boolean][] = [
    [-1.6, 0, true], [-2.3, 1.2, true], [-1.2, 2.1, true],
    [1.2, 0, false], [2.3, 1.2, false], [1.6, 2.1, false],
  ];
  for (const [x, ph, far] of legs) {
    const sw = c.sleeping ? 0 : Math.sin(c.tSec * 6 + ph) * 0.1;
    cv.save();
    cv.translate(x * u, -1.3 * u);
    cv.rotate((far ? -1 : 1) * (0.55 + sw));
    shape(
      cv,
      capsulePath([0, 0], 0.16 * u, [0, 1.15 * u], 0.13 * u),
      far ? mixColors(c.accent, INK_WARM, 0.28) : c.accent, c.ink, inkW * 0.6,
    );
    cv.restore();
  }
  // Дальняя клешня.
  cv.save();
  cv.translate(-1.9 * u, -2.0 * u);
  cv.rotate(-0.5);
  shape(cv, capsulePath([0, 0], 0.28 * u, [-0.7 * u, -0.45 * u], 0.24 * u),
    mixColors(c.accent, INK_WARM, 0.28), c.ink, inkW * 0.7);
  circleD(cv, -0.95 * u, -0.6 * u, 0.52 * u, mixColors(c.accent, INK_WARM, 0.28), c.ink, inkW * 0.7);
  cv.restore();
  // Тело.
  const br = breathOf(c);
  ellipseD(cv, 0, -1.75 * u * br, 2.5 * u * (2 - br), 1.35 * u * br, c.body, c.ink, inkW);
  // Ближняя клешня машет.
  cv.save();
  cv.translate(1.8 * u, -2.1 * u);
  cv.rotate(c.sleeping ? 0.2 : Math.sin(c.tSec * 2.6) * 0.28 - 0.1);
  shape(cv, capsulePath([0, 0], 0.3 * u, [1.05 * u, -0.5 * u], 0.26 * u), c.accent, c.ink, inkW * 0.7);
  circleD(cv, 1.4 * u, -0.68 * u, 0.62 * u, c.accent, c.ink, inkW);
  const notch = new Path2D();
  notch.moveTo(1.75 * u, -0.5 * u);
  notch.lineTo(2.2 * u, -0.25 * u);
  notch.lineTo(1.6 * u, -0.05 * u);
  notch.closePath();
  shape(cv, notch, c.body, "transparent", 0);
  cv.restore();
  // Глазки на стебельках.
  for (const dx of [-0.7, 0.7]) {
    const droop = c.sleeping ? 0.55 : 0;
    cv.save();
    cv.translate(dx * u, -2.75 * u);
    cv.rotate(droop);
    shape(
      cv,
      capsulePath([0, 0], 0.2 * u, [dx * 0.2 * u, -0.95 * u], 0.17 * u),
      c.body, c.ink, inkW * 0.6,
    );
    eyesFront(c, [[dx * 0.2 * u, -1.0 * u]], 0.4 * u);
    cv.restore();
  }
  mouth(c, 0.15 * u, -1.45 * u, 0.55 * u);
  blush(c, -1.3 * u, -1.35 * u, 0.28 * u);
  blush(c, 1.3 * u, -1.3 * u, 0.28 * u);
}

// ── РАСТЕНИЯ ───────────────────────────────────────────────────────────

function paintPlant(c: C) {
  switch (c.pet.type) {
    case "cactus":
      cactus(c);
      break;
    case "bonsai":
      bonsai(c);
      break;
    case "succulent":
      succulent(c);
      break;
    case "sunflower":
      sunflower(c);
      break;
    case "clover":
      clover(c);
      break;
    default:
      sprout(c);
  }
}

function cactus(c: C) {
  const { cv, u, inkW } = c;
  const ink = mixColors(c.body, INK_WARM, 0.45);
  const br = breathOf(c);
  // Ствол — скруглённая колонна.
  const body = new Path2D();
  body.roundRect(-1.25 * u, -6.3 * u * br, 2.5 * u, 6.3 * u * br, [1.25 * u, 1.25 * u, 0, 0]);
  shape(cv, body, c.body, ink, inkW);
  for (const dx of [-0.45, 0.45]) {
    line(cv, dx * u, -5.6 * u, dx * u, -0.9 * u, mixColors(c.body, INK_WARM, 0.28), inkW * 0.4);
  }
  const sway = Math.sin(c.tSec * 1.5 + c.index) * 0.05;
  cv.save();
  cv.translate(-1.1 * u, -3.6 * u);
  cv.rotate(-sway);
  shape(cv, capsulePath([-0.5 * u, 0], 0.55 * u, [-1.5 * u, -0.7 * u], 0.5 * u), c.body, ink, inkW);
  shape(cv, capsulePath([-1.5 * u, -0.7 * u], 0.5 * u, [-1.5 * u, -2.1 * u], 0.5 * u), c.body, ink, inkW);
  cv.restore();
  cv.save();
  cv.translate(1.1 * u, -2.6 * u);
  cv.rotate(sway);
  shape(cv, capsulePath([0.5 * u, 0], 0.5 * u, [1.4 * u, -0.6 * u], 0.45 * u), c.body, ink, inkW);
  shape(cv, capsulePath([1.4 * u, -0.6 * u], 0.45 * u, [1.4 * u, -1.9 * u], 0.45 * u), c.body, ink, inkW);
  cv.restore();
  for (let i = 0; i < 6; i++) {
    const y = (-1.0 - i * 0.95) * u;
    line(cv, -1.45 * u, y, -1.75 * u, y - 0.15 * u, ink, inkW * 0.3);
    line(cv, 1.45 * u, y + 0.4 * u, 1.75 * u, y + 0.25 * u, ink, inkW * 0.3);
  }
  const fx = 0, fy = -6.55 * u;
  for (let i = 0; i < 5; i++) {
    const ang = (i * 2 * Math.PI) / 5 - Math.PI / 2 + sway;
    dot(cv, fx + Math.cos(ang) * 0.55 * u, fy + Math.sin(ang) * 0.55 * u, 0.42 * u, c.accent);
  }
  dot(cv, fx, fy, 0.36 * u, "#FFD166");
}

function bonsai(c: C) {
  const { cv, u, inkW } = c;
  const ink = mixColors(c.accent, INK_WARM, 0.45);
  const foliage = c.body;
  const trunk = new Path2D();
  trunk.moveTo(-0.25 * u, 0);
  trunk.quadraticCurveTo(-0.75 * u, -1.8 * u, 0.1 * u, -3.2 * u);
  tube(cv, trunk, c.accent, ink, 0.85 * u, inkW);
  const branch = new Path2D();
  branch.moveTo(0.05 * u, -3.1 * u);
  branch.quadraticCurveTo(0.6 * u, -3.6 * u, 1.3 * u, -3.75 * u);
  tube(cv, branch, c.accent, ink, 0.5 * u, inkW);
  const branch2 = new Path2D();
  branch2.moveTo(0, -2.6 * u);
  branch2.quadraticCurveTo(-0.7 * u, -3.0 * u, -1.3 * u, -3.6 * u);
  tube(cv, branch2, c.accent, ink, 0.45 * u, inkW);
  const br = breathOf(c);
  ellipseD(cv, 0.45 * u, -4.85 * u * br, 2.3 * u, 1.45 * u * br, foliage, ink, inkW);
  ellipseD(cv, -1.55 * u, -4.15 * u, 1.45 * u, 0.95 * u,
    mixColors(foliage, "#000000", 0.06), ink, inkW * 0.8);
  ellipseD(cv, 2.1 * u, -4.0 * u, 1.3 * u, 0.9 * u,
    mixColors(foliage, "#000000", 0.06), ink, inkW * 0.8);
  dot(cv, -0.2 * u, -5.2 * u, 0.22 * u, c.belly);
  dot(cv, 1.2 * u, -4.6 * u, 0.22 * u, c.belly);
  dot(cv, -0.7 * u, -0.25 * u, 0.3 * u, mixColors(foliage, INK_WARM, 0.28));
  dot(cv, 0.6 * u, -0.2 * u, 0.24 * u, mixColors(foliage, INK_WARM, 0.28));
}

function succulent(c: C) {
  const { cv, u, inkW } = c;
  const ink = mixColors(c.body, INK_WARM, 0.45);
  const cx = 0, cy = -1.9 * u;
  const rot = Math.sin(c.tSec * 1.4 + c.index) * 0.04;
  for (let i = 0; i < 7; i++) {
    const ang = (i * 2 * Math.PI) / 7 + 0.35 + rot;
    const tipx = cx + Math.cos(ang) * 2.15 * u;
    const tipy = cy + Math.sin(ang) * 2.15 * u;
    shape(
      cv,
      leafPath([cx + Math.cos(ang) * 0.3 * u, cy + Math.sin(ang) * 0.3 * u], [tipx, tipy], 0.6 * u),
      c.body, ink, inkW * 0.7,
    );
    dot(cv, tipx, tipy, 0.22 * u, c.accent);
  }
  for (let i = 0; i < 5; i++) {
    const ang = (i * 2 * Math.PI) / 5 + 1.1 - rot;
    shape(
      cv,
      leafPath([cx, cy], [cx + Math.cos(ang) * 1.05 * u, cy + Math.sin(ang) * 1.05 * u], 0.42 * u),
      c.belly, ink, inkW * 0.55,
    );
  }
  dot(cv, cx, cy, 0.42 * u, c.accent);
}

function sunflower(c: C) {
  const { cv, u, inkW } = c;
  const ink = mixColors(c.accent, INK_WARM, 0.45);
  shape(cv, capsulePath([0, 0], 0.26 * u, [0.12 * u, -5.0 * u], 0.22 * u), c.accent, ink, inkW * 0.7);
  const sway = Math.sin(c.tSec * 1.6 + c.index) * 0.06;
  for (const [y, dir] of [[-2.1, -1], [-3.3, 1]] as [number, number][]) {
    cv.save();
    cv.translate(0.06 * u, y * u);
    cv.rotate(dir * (0.5 + sway));
    shape(cv, leafPath([0, 0], [1.75 * u, -0.35 * u], 0.5 * u), c.accent, ink, inkW * 0.7);
    line(cv, 0.2 * u, -0.05 * u, 1.4 * u, -0.3 * u, mixColors(c.accent, INK_WARM, 0.28), inkW * 0.3);
    cv.restore();
  }
  cv.save();
  cv.translate(0.12 * u, -6.15 * u);
  cv.rotate(sway * 1.6);
  for (let i = 0; i < 10; i++) {
    const ang = (i * 2 * Math.PI) / 10;
    shape(
      cv,
      leafPath(
        [Math.cos(ang) * 0.6 * u, Math.sin(ang) * 0.6 * u],
        [Math.cos(ang) * 2.0 * u, Math.sin(ang) * 2.0 * u],
        0.55 * u,
      ),
      c.body,
      mixColors(c.body, "#000000", 0.35),
      inkW * 0.55,
    );
  }
  circleD(cv, 0, 0, 1.05 * u, c.belly, mixColors(c.belly, INK_WARM, 0.45), inkW * 0.7);
  for (const [ox, oy] of [
    [-0.35 * u, -0.3 * u], [0.3 * u, -0.35 * u], [0, 0.15 * u],
    [-0.4 * u, 0.35 * u], [0.42 * u, 0.3 * u],
  ]) {
    dot(cv, ox, oy, 0.11 * u, mixColors(c.belly, INK_WARM, 0.45));
  }
  cv.restore();
}

function clover(c: C) {
  const { cv, u, inkW } = c;
  const ink = mixColors(c.body, INK_WARM, 0.45);
  const rot = Math.sin(c.tSec * 1.6 + c.index) * 0.05;
  for (const [x, y] of [[-1.15, -2.5], [1.15, -2.5], [0, -3.3]] as [number, number][]) {
    shape(
      cv,
      capsulePath([0, 0], 0.12 * u, [x * u, y * u], 0.1 * u),
      mixColors(c.body, INK_WARM, 0.28), ink, inkW * 0.45,
    );
  }
  const tips: [number, number][] = [
    [-1.75 * u, -2.85 * u], [1.75 * u, -2.85 * u], [0, -3.95 * u],
  ];
  for (let i = 0; i < tips.length; i++) {
    cv.save();
    cv.translate(tips[i][0], tips[i][1]);
    cv.rotate(i === 2 ? rot : -rot);
    shape(cv, leafPath([0, 0], [0.9 * u, 0], 0.55 * u), c.body, ink, inkW * 0.6);
    shape(cv, leafPath([0, 0], [-0.9 * u, 0], 0.55 * u), c.body, ink, inkW * 0.6);
    line(cv, -0.7 * u, 0, 0.7 * u, 0, mixColors(c.body, INK_WARM, 0.28), inkW * 0.3);
    cv.restore();
  }
  const flx = 0.9 * u, fly = -3.6 * u;
  for (let i = 0; i < 5; i++) {
    const ang = (i * 2 * Math.PI) / 5 - Math.PI / 2 + rot;
    dot(cv, flx + Math.cos(ang) * 0.3 * u, fly + Math.sin(ang) * 0.3 * u, 0.22 * u, c.accent);
  }
  dot(cv, flx, fly, 0.18 * u, "#FFD166");
}

function sprout(c: C) {
  const { cv, u, inkW } = c;
  const ink = mixColors(c.body, INK_WARM, 0.45);
  const sway = Math.sin(c.tSec * 1.7 + c.index) * 0.06;
  shape(
    cv,
    capsulePath([0, 0], 0.2 * u, [0, -2.1 * u], 0.16 * u),
    mixColors(c.body, INK_WARM, 0.28), ink, inkW * 0.6,
  );
  cv.save();
  cv.translate(0, -2.0 * u);
  cv.rotate(-0.5 - sway);
  shape(cv, leafPath([0, 0], [-1.9 * u, -1.35 * u], 0.72 * u), c.body, ink, inkW * 0.7);
  line(cv, -0.25 * u, -0.2 * u, -1.45 * u, -1.05 * u, mixColors(c.body, INK_WARM, 0.28), inkW * 0.3);
  cv.restore();
  cv.save();
  cv.translate(0, -2.0 * u);
  cv.rotate(0.5 + sway);
  shape(cv, leafPath([0, 0], [1.8 * u, -1.5 * u], 0.72 * u), c.belly, ink, inkW * 0.7);
  line(cv, 0.25 * u, -0.2 * u, 1.4 * u, -1.15 * u, mixColors(c.belly, INK_WARM, 0.28), inkW * 0.3);
  cv.restore();
  shape(cv, leafPath([0, -2.1 * u], [0.1 * u, -3.3 * u], 0.3 * u), c.body, ink, inkW * 0.55);
}

// ── Аксессуары гардероба (в локальных единицах u) ──────────────────────

function accHat(c: C, x: number, y: number) {
  const { cv, inkW } = c;
  const au = c.u * 0.115; // единица аксессуаров (1% ширины спрайта)
  const hat = c.pet.hat ?? "none";
  if (hat === "cap") {
    const dome = new Path2D();
    dome.moveTo(x - 14 * au * 0.62, y);
    dome.quadraticCurveTo(x, y - 22 * au * 0.62, x + 14 * au * 0.62, y);
    dome.closePath();
    shape(cv, dome, "#EF476F", c.ink, inkW * 0.6);
    const visor = new Path2D();
    visor.roundRect(x + 5 * au, y - 2 * au, 13 * au, 4 * au, 3);
    shape(cv, visor, "#D63860", c.ink, inkW * 0.5);
    dot(cv, x, y - 11 * au * 0.62, 2.1 * au, "#FFFFFF");
  } else if (hat === "beanie") {
    const dome = new Path2D();
    dome.moveTo(x - 14 * au * 0.62, y);
    dome.quadraticCurveTo(x, y - 20 * au * 0.62, x + 14 * au * 0.62, y);
    dome.closePath();
    shape(cv, dome, "#B892E0", c.ink, inkW * 0.6);
    const band = new Path2D();
    band.roundRect(x - 14 * au * 0.62, y - 2 * au, 28 * au * 0.62, 4.4 * au * 0.62, 3);
    shape(cv, band, "#9A77C9", c.ink, inkW * 0.5);
    dot(cv, x, y - 19 * au * 0.62, 3.2 * au, "#F7F1EA");
  } else if (hat === "crown") {
    const crown = new Path2D();
    crown.moveTo(x - 11 * au * 0.62, y);
    crown.lineTo(x - 11 * au * 0.62, y - 10 * au * 0.62);
    crown.lineTo(x - 5.5 * au * 0.62, y - 5 * au * 0.62);
    crown.lineTo(x, y - 12 * au * 0.62);
    crown.lineTo(x + 5.5 * au * 0.62, y - 5 * au * 0.62);
    crown.lineTo(x + 11 * au * 0.62, y - 10 * au * 0.62);
    crown.lineTo(x + 11 * au * 0.62, y);
    crown.closePath();
    shape(cv, crown, "#FFC800", c.ink, inkW * 0.6);
    dot(cv, x, y - 3.4 * au, 1.7 * au, "#EF476F");
  } else if (hat === "flowerPin") {
    for (let i = 0; i < 5; i++) {
      const ang = (i * 2 * Math.PI) / 5 - Math.PI / 2;
      dot(cv, x + Math.cos(ang) * 3.2 * au, y + Math.sin(ang) * 3.2 * au, 2.3 * au, "#FF8FB1");
    }
    dot(cv, x, y, 2.1 * au, "#FFD166");
  }
}

function accFace(c: C, x: number, y: number) {
  const { cv, inkW } = c;
  const au = c.u * 0.115; // единица аксессуаров (1% ширины спрайта)
  const face = c.pet.face ?? "none";
  if (face === "glasses") {
    cv.beginPath();
    cv.arc(x, y, 6 * au * 0.62, 0, Math.PI * 2);
    cv.strokeStyle = "#3A3A3A";
    cv.lineWidth = 1.6 * au;
    cv.stroke();
    line(cv, x + 6 * au * 0.62, y, x + 12 * au, y - 1.5 * au, "#3A3A3A", 1.6 * au);
  } else if (face === "shades") {
    const sh = new Path2D();
    sh.roundRect(x - 6 * au, y - 4.25 * au, 12 * au, 8.5 * au, 3 * au);
    shape(cv, sh, "#23262B", c.ink, inkW * 0.5);
    line(cv, x + 6 * au, y - 1 * au, x + 12 * au, y - 2.5 * au, "#23262B", 1.6 * au);
  }
}

function accNeck(c: C, x: number, y: number) {
  const { cv, inkW } = c;
  const au = c.u * 0.115; // единица аксессуаров (1% ширины спрайта)
  const neck = c.pet.neck ?? "none";
  if (neck === "scarf") {
    const s1 = new Path2D();
    s1.roundRect(x - 11 * au, y - 3.25 * au, 22 * au, 6.5 * au, 3.2 * au);
    shape(cv, s1, "#EF6461", c.ink, inkW * 0.55);
    const s2 = new Path2D();
    s2.roundRect(x - 11 * au, y, 6.5 * au, 13 * au, 3 * au);
    shape(cv, s2, "#D63860", c.ink, inkW * 0.55);
  } else if (neck === "bow") {
    dot(cv, x, y, 2.4 * au, "#E85D8A");
    const l = new Path2D();
    l.moveTo(x, y);
    l.lineTo(x - 11 * au, y - 6.5 * au);
    l.quadraticCurveTo(x - 14 * au, y, x - 11 * au, y + 6.5 * au);
    l.closePath();
    shape(cv, l, "#FF6FA5", c.ink, inkW * 0.55);
    const r = new Path2D();
    r.moveTo(x, y);
    r.lineTo(x + 11 * au, y - 6.5 * au);
    r.quadraticCurveTo(x + 14 * au, y, x + 11 * au, y + 6.5 * au);
    r.closePath();
    shape(cv, r, "#FF6FA5", c.ink, inkW * 0.55);
  } else if (neck === "bandana") {
    const kerchief = new Path2D();
    kerchief.moveTo(x - 12 * au, y - 2.5 * au);
    kerchief.lineTo(x + 12 * au, y - 2.5 * au);
    kerchief.lineTo(x, y + 10 * au);
    kerchief.closePath();
    shape(cv, kerchief, "#3E7BFA", c.ink, inkW * 0.55);
    const band = new Path2D();
    band.roundRect(x - 12 * au, y - 2.5 * au - 2.3 * au, 24 * au, 4.6 * au, 2.4 * au);
    shape(cv, band, "#2F63D6", c.ink, inkW * 0.5);
  } else if (neck === "bell") {
    const strap = new Path2D();
    strap.roundRect(x - 11 * au, y - 1.7 * au, 22 * au, 3.4 * au, 2 * au);
    shape(cv, strap, "#D63860", c.ink, inkW * 0.5);
    circleD(cv, x, y + 5 * au, 4.4 * au, "#FFC800", c.ink, inkW * 0.55);
    circleD(cv, x, y + 5 * au, 2 * au, "#E09E00", c.ink, inkW * 0.45);
    dot(cv, x, y + 3.6 * au, 1 * au, "#FFFFFF");
  }
}

