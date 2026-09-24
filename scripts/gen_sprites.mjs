// Генерация реалистичных спрайтов питомцев «Росток» v2.1.0.
// 30 видов (24 зверя + 6 растений): idle + сон (у растений сна нет).
// Единый стиль: реалистичная детская иллюстрация, профиль вправо,
// чистый белый фон (для последующего удаления).
import ZAI from 'z-ai-web-dev-sdk';
import fs from 'fs';
import path from 'path';

const OUT = '/home/z/my-project/scripts/sprites_raw';

const STYLE =
  'Realistic children\'s encyclopedia illustration, natural realistic anatomy and proportions, ' +
  'soft detailed fur and texture, natural colors, gentle soft daylight, ' +
  'whole subject fully visible inside frame with margin, ' +
  'isolated on a pure solid white background, no shadow, no ground, no grass, no text, no border, no watermark';

const IDLE = (subject, pose) =>
  `Realistic children's encyclopedia illustration of ${subject}, ${pose}, full body side profile view facing right, ${STYLE}`;

const SLEEP = (subject, pose) =>
  `Realistic children's encyclopedia illustration of ${subject} sleeping peacefully with eyes closed, ${pose}, full body side profile view facing right, ${STYLE}`;

// pose по умолчанию: стоит на земле (виден весь силуэт).
const Q = 'standing naturally on all four legs';
const BIRD = 'standing upright on two legs';
const HOP = 'sitting naturally on hind legs';

const SPRITES = [
  // ── Звери (24) ──────────────────────────────────────────────
  ['fox', 'a young red fox cub with fluffy orange fur, white chest and a big bushy tail with white tip', Q],
  ['cat', 'a small grey tabby kitten with stripes and a long tail', Q],
  ['owl', 'a small fluffy owl chick with big round eyes, brown and cream feathers', BIRD],
  ['dragon', 'a cute friendly young green dragon with small wings, small horns and a long tail, fantasy creature drawn realistically', Q],
  ['duck', 'a little yellow duckling with an orange flat beak and tiny wings', BIRD],
  ['bunny', 'a small fluffy grey-white rabbit with long ears and a round white tail', HOP],
  ['penguin', 'a fluffy grey emperor penguin chick with black and white head', BIRD],
  ['hedgehog', 'a little hedgehog with brown spines, light face and tiny paws', Q],
  ['panda', 'a chubby giant panda cub with black and white fur', Q],
  ['bear', 'a small brown bear cub with thick brown fur and round ears', Q],
  ['dog', 'a golden retriever puppy with golden fur and floppy ears', Q],
  ['deer', 'a young fawn with light brown spotted coat and tiny antlers', Q],
  ['seal', 'a baby grey seal pup with spotted fur and whiskers, resting on its belly', 'resting on its belly, head raised'],
  ['whale', 'a baby blue whale with grey-blue skin, small dorsal fin and a gentle smile', 'swimming, body horizontal'],
  ['turtle', 'a small green pond turtle with a detailed patterned shell', Q],
  ['frog', 'a small green frog with big round eyes on top of its head', HOP],
  ['squirrel', 'a red squirrel with a big fluffy tail and tufted ears', HOP],
  ['raccoon', 'a young raccoon with grey fur, black mask around the eyes and a striped bushy tail', Q],
  ['koala', 'a fluffy grey koala with big round fluffy ears and a black nose', HOP],
  ['pig', 'a chubby pink piglet with a snout nose and a curly tail', Q],
  ['chick', 'a tiny round yellow chick with a small orange beak', BIRD],
  ['unicorn', 'a young white unicorn with a golden horn and a pastel pink mane and tail', Q],
  ['octopus', 'a cute coral-pink octopus with eight rounded tentacles', 'resting, tentacles spread forward'],
  ['crab', 'a small red crab with two big claws and four walking legs per side', 'standing sideways, facing right'],
  // ── Растения (6, сна нет) ───────────────────────────────────
  ['cactus', 'a small green cactus with spines and one pink flower on top', 'growing from a small mound of soil'],
  ['bonsai', 'a miniature bonsai tree with a curved brown trunk and a lush green crown', 'growing from a small mound of soil'],
  ['succulent', 'a plump green echeveria succulent with rosette-shaped leaves', 'growing from a small mound of soil'],
  ['sunflower', 'a bright yellow sunflower on a thick green stem with large green leaves', 'growing from a small mound of soil'],
  ['clover', 'a lush clover plant with several green three-leaf stems and tiny white flowers', 'growing from a small mound of soil'],
  ['sprout', 'a young green sprout with two small leaves growing from a small mound of soil', 'growing straight up'],
];

const SLEEP_POSE = {
  fox: 'curled up like a ball with the tail wrapped around the body, lying on the ground',
  cat: 'curled up like a ball with the tail wrapped around, lying on the ground',
  owl: 'perched, with the head tucked down into the fluffed feathers',
  dragon: 'curled up with the tail around the body and wings folded, lying on the ground',
  duck: 'sitting with the beak tucked back into the wing feathers',
  bunny: 'lying with ears relaxed back, paws tucked under',
  penguin: 'standing upright with the beak tucked into the chest feathers',
  hedgehog: 'curled into a loose ball with spines relaxed, lying on the ground',
  panda: 'lying on its side with paws tucked',
  bear: 'lying on its side, curled slightly',
  dog: 'lying curled up with the nose near the tail',
  deer: 'lying with legs folded under the body, head raised slightly',
  seal: 'lying on its belly, head resting on the ground',
  whale: 'floating calmly underwater, body horizontal, eyes closed',
  turtle: 'resting with the head partly out of the shell',
  frog: 'sitting low with eyes closed',
  squirrel: 'curled up with the fluffy tail wrapped over the body like a blanket',
  raccoon: 'curled up lying on the ground',
  koala: 'sitting slouched, hugging itself, head down',
  pig: 'lying on its side with the snout resting forward',
  chick: 'sitting with the head tucked into the wing feathers',
  unicorn: 'lying with legs folded under, head lowered',
  octopus: 'resting with tentacles gently curled inward',
  crab: 'resting low, claws tucked close',
};

function buildJobs() {
  const jobs = [];
  for (const [name, subject, pose] of SPRITES) {
    jobs.push({ file: `${name}.png`, prompt: IDLE(subject, pose) });
    if (SLEEP_POSE[name]) {
      jobs.push({ file: `${name}_sleep.png`, prompt: SLEEP(subject, SLEEP_POSE[name]) });
    }
  }
  return jobs;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function genOne(zai, job, attempt = 1) {
  if (fs.existsSync(path.join(OUT, job.file))) {
    const st = fs.statSync(path.join(OUT, job.file));
    if (st.size > 20000) {
      console.log(`SKIP ${job.file}`);
      return true;
    }
  }
  try {
    const res = await zai.images.generations.create({ prompt: job.prompt, size: '1024x1024' });
    const b64 = res?.data?.[0]?.base64;
    if (!b64) throw new Error('empty base64');
    const buf = Buffer.from(b64, 'base64');
    if (buf.length < 20000) throw new Error(`too small: ${buf.length}`);
    fs.writeFileSync(path.join(OUT, job.file), buf);
    console.log(`OK ${job.file} (${Math.round(buf.length / 1024)} KB)`);
    return true;
  } catch (e) {
    console.log(`ERR ${job.file} try${attempt}: ${e.message}`);
    if (attempt < 3) {
      await sleep(2500 * attempt);
      return genOne(zai, job, attempt + 1);
    }
    return false;
  }
}

async function main() {
  const zai = await ZAI.create();
  const jobs = buildJobs();
  fs.writeFileSync(path.join(OUT, 'manifest.json'), JSON.stringify(jobs.map(({ file, prompt }) => ({ file, prompt })), null, 1));
  console.log(`Total jobs: ${jobs.length}`);
  let done = 0, fail = [];
  const queue = [...jobs];
  const CONCURRENCY = Number(process.env.GEN_CONC || 1);
  async function worker() {
    while (queue.length) {
      const job = queue.shift();
      const ok = await genOne(zai, job);
      done++;
      if (!ok) fail.push(job.file);
      await sleep(1500);
    }
  }
  await Promise.all(Array.from({ length: CONCURRENCY }, worker));
  console.log(`\nDONE: ${done - fail.length}/${jobs.length} ok`);
  if (fail.length) console.log('FAILED:', fail.join(', '));
}

main().catch((e) => { console.error('FATAL', e); process.exit(1); });
