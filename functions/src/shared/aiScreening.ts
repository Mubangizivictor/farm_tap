// GENERATED from shared/ by `node shared/sync.mjs`. Edit the file in shared/, not this copy.
// FarmTap AI engine — photo screening (decision 0025, experimental).
//
// No open, commercially licensed and validated model for these checks was
// found, so none is installed and FarmTap does not claim to detect any of
// them. What runs today is a plain photo-quality check (brightness,
// contrast, sharpness), so the photo saved for the vet is usable. A model
// can be added only after it passes tools/ai_eval/ on labelled photos.

export type ScreeningStatus = 'noModel' | 'evaluating' | 'available';

export interface ScreeningTarget {
  key: string;
  label: string;
  /** What the farmer should photograph. */
  photo: string;
  status: ScreeningStatus;
  /** Minimum evaluation results before it may be switched on (tools/ai_eval). */
  minSensitivity: number;
  minSpecificity: number;
  note: string;
}

export const screeningTargets: ScreeningTarget[] = [
  { key: 'skin', label: 'Skin lumps and lesions (e.g. lumpy skin)', photo: 'The whole side of the animal in daylight, then a close photo of the lumps.', status: 'noModel', minSensitivity: 0.9, minSpecificity: 0.85, note: 'Published lumpy-skin studies use small single-region datasets with no commercial licence; no model released for reuse.' },
  { key: 'eye', label: 'Eye problems (e.g. pinkeye)', photo: 'Close to the eye, in shade, eye open.', status: 'noModel', minSensitivity: 0.85, minSpecificity: 0.85, note: 'No licensed cattle eye dataset found.' },
  { key: 'wound', label: 'Wounds and injuries', photo: 'The wound and the skin around it, with something for size (a pen).', status: 'noModel', minSensitivity: 0.85, minSpecificity: 0.8, note: 'No licensed cattle wound dataset found.' },
  { key: 'bcs', label: 'Body condition score', photo: 'From behind and from the side, standing on flat ground.', status: 'noModel', minSensitivity: 0.8, minSpecificity: 0.8, note: 'Research models need fixed 3D/depth cameras; not usable from a phone photo yet.' },
  { key: 'lameness', label: 'Lameness (from video)', photo: 'A short video of her walking on flat ground, from the side.', status: 'noModel', minSensitivity: 0.85, minSpecificity: 0.8, note: 'Needs video gait models; none licensed for reuse.' },
  { key: 'udder', label: 'Udder and mastitis signs', photo: 'The udder from behind and the side.', status: 'noModel', minSensitivity: 0.9, minSpecificity: 0.85, note: 'Mastitis cannot be judged from a photo alone; a CMT or lab test is needed.' },
  { key: 'parasites', label: 'Ticks and other external parasites', photo: 'Ears, under the tail and between the legs, close up.', status: 'noModel', minSensitivity: 0.85, minSpecificity: 0.8, note: 'No validated tick-detection dataset for East African cattle found.' },
];

export interface PhotoQuality {
  brightness: number;
  contrast: number;
  sharpness: number;
  ok: boolean;
  problems: string[];
}

/**
 * Quality of a photo from its grey pixels (0–255, row by row): mean
 * brightness, contrast (standard deviation) and sharpness (variance of the
 * Laplacian, the usual blur measure). Thresholds suit a ~320 px image.
 */
export function photoQuality(gray: ArrayLike<number>, w: number, h: number): PhotoQuality {
  const n = w * h;
  let s = 0;
  for (let i = 0; i < n; i++) s += gray[i];
  const mean = s / n;
  let v = 0;
  for (let i = 0; i < n; i++) v += (gray[i] - mean) ** 2;
  const contrast = Math.sqrt(v / n);
  let ls = 0;
  let ls2 = 0;
  let m = 0;
  for (let y = 1; y < h - 1; y++)
    for (let x = 1; x < w - 1; x++) {
      const i = y * w + x;
      const lap = gray[i - w] + gray[i + w] + gray[i - 1] + gray[i + 1] - 4 * gray[i];
      ls += lap;
      ls2 += lap * lap;
      m++;
    }
  const sharpness = m ? ls2 / m - (ls / m) ** 2 : 0;
  const problems: string[] = [];
  if (mean < 50) problems.push('Too dark: take it in daylight or shade, not at night.');
  if (mean > 215) problems.push('Too bright: move out of direct sun.');
  if (contrast < 20) problems.push('Very flat: get closer so the problem fills the photo.');
  if (sharpness < 60) problems.push('Blurred: hold the phone still and tap to focus.');
  return { brightness: Math.round(mean), contrast: Math.round(contrast), sharpness: Math.round(sharpness), ok: problems.length === 0, problems };
}

export const SCREENING_ENGINE = 'screening-none-1';
