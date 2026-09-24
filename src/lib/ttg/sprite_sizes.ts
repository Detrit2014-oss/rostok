// Автогенерируется scripts/emit_sprite_sizes.py — размеры обработанных
// спрайтов (после удаления фона). Используется для расчёта пропорций.
export interface SpriteSize { w: number; h: number }

export const SPRITE_SIZES: Record<string, SpriteSize> = {
  bear: { w: 512, h: 504 },
  bear_sleep: { w: 512, h: 388 },
  bonsai: { w: 492, h: 512 },
  bunny: { w: 460, h: 512 },
  bunny_sleep: { w: 512, h: 430 },
  cactus: { w: 512, h: 458 },
  cat: { w: 460, h: 512 },
  cat_sleep: { w: 512, h: 464 },
  chick: { w: 312, h: 512 },
  chick_sleep: { w: 440, h: 512 },
  clover: { w: 512, h: 430 },
  crab: { w: 512, h: 416 },
  crab_sleep: { w: 512, h: 350 },
  deer: { w: 494, h: 512 },
  deer_sleep: { w: 512, h: 446 },
  dog: { w: 446, h: 512 },
  dog_sleep: { w: 504, h: 512 },
  dragon: { w: 492, h: 512 },
  dragon_sleep: { w: 512, h: 470 },
  duck: { w: 396, h: 512 },
  duck_sleep: { w: 490, h: 512 },
  fox: { w: 510, h: 512 },
  fox_sleep: { w: 512, h: 452 },
  frog: { w: 512, h: 448 },
  frog_sleep: { w: 512, h: 482 },
  hedgehog: { w: 512, h: 444 },
  hedgehog_sleep: { w: 512, h: 432 },
  koala: { w: 420, h: 512 },
  koala_sleep: { w: 512, h: 502 },
  octopus: { w: 512, h: 434 },
  octopus_sleep: { w: 512, h: 440 },
  owl: { w: 458, h: 512 },
  owl_sleep: { w: 404, h: 512 },
  panda: { w: 500, h: 512 },
  panda_sleep: { w: 512, h: 488 },
  penguin: { w: 338, h: 512 },
  penguin_sleep: { w: 370, h: 512 },
  pig: { w: 492, h: 512 },
  pig_sleep: { w: 512, h: 448 },
  raccoon: { w: 512, h: 436 },
  raccoon_sleep: { w: 512, h: 468 },
  seal: { w: 512, h: 440 },
  seal_sleep: { w: 512, h: 344 },
  sprout: { w: 512, h: 420 },
  squirrel: { w: 482, h: 512 },
  squirrel_sleep: { w: 452, h: 512 },
  succulent: { w: 466, h: 512 },
  sunflower: { w: 376, h: 512 },
  turtle: { w: 512, h: 322 },
  turtle_sleep: { w: 512, h: 396 },
  unicorn: { w: 438, h: 512 },
  unicorn_sleep: { w: 512, h: 386 },
  whale: { w: 512, h: 246 },
  whale_sleep: { w: 512, h: 296 }
};

export function spriteAspect(type: string): number {
  const s = SPRITE_SIZES[type];
  if (!s || !s.h) return 1.45;
  return s.w / s.h;
}
