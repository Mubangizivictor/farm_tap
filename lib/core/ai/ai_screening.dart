// FarmTap AI engine: photo screening (decision 0025, experimental). Hand
// port of shared/aiScreening.ts.
//
// No open, commercially licensed and validated model for these checks was
// found, so none is installed and FarmTap does not claim to detect any of
// them. What runs today is a plain photo-quality check (brightness,
// contrast, sharpness) so the photo saved for the vet is usable.
import 'dart:math' as math;

import 'ai_core.dart';

class ScreeningTarget {
  const ScreeningTarget(
    this.key,
    this.label,
    this.photo,
    this.status,
    this.minSensitivity,
    this.minSpecificity,
    this.note,
  );
  final String key;
  final String label;

  /// What the farmer should photograph.
  final String photo;

  /// noModel, evaluating or available
  final String status;
  final double minSensitivity;
  final double minSpecificity;
  final String note;
}

const screeningTargets = <ScreeningTarget>[
  ScreeningTarget(
    'skin',
    'Skin lumps and lesions (e.g. lumpy skin)',
    'The whole side of the animal in daylight, then a close photo of the lumps.',
    'noModel',
    0.9,
    0.85,
    'Published lumpy-skin studies use small single-region datasets with no commercial licence; no model released for reuse.',
  ),
  ScreeningTarget(
    'eye',
    'Eye problems (e.g. pinkeye)',
    'Close to the eye, in shade, eye open.',
    'noModel',
    0.85,
    0.85,
    'No licensed cattle eye dataset found.',
  ),
  ScreeningTarget(
    'wound',
    'Wounds and injuries',
    'The wound and the skin around it, with something for size (a pen).',
    'noModel',
    0.85,
    0.8,
    'No licensed cattle wound dataset found.',
  ),
  ScreeningTarget(
    'bcs',
    'Body condition score',
    'From behind and from the side, standing on flat ground.',
    'noModel',
    0.8,
    0.8,
    'Research models need fixed 3D/depth cameras; not usable from a phone photo yet.',
  ),
  ScreeningTarget(
    'lameness',
    'Lameness (from video)',
    'A short video of her walking on flat ground, from the side.',
    'noModel',
    0.85,
    0.8,
    'Needs video gait models; none licensed for reuse.',
  ),
  ScreeningTarget(
    'udder',
    'Udder and mastitis signs',
    'The udder from behind and the side.',
    'noModel',
    0.9,
    0.85,
    'Mastitis cannot be judged from a photo alone; a CMT or lab test is needed.',
  ),
  ScreeningTarget(
    'parasites',
    'Ticks and other external parasites',
    'Ears, under the tail and between the legs, close up.',
    'noModel',
    0.85,
    0.8,
    'No validated tick-detection dataset for East African cattle found.',
  ),
];

class PhotoQuality {
  const PhotoQuality({
    required this.brightness,
    required this.contrast,
    required this.sharpness,
    required this.ok,
    required this.problems,
  });
  final int brightness;
  final int contrast;
  final int sharpness;
  final bool ok;
  final List<String> problems;
}

/// Quality of a photo from its grey pixels (0-255, row by row): mean
/// brightness, contrast (standard deviation) and sharpness (variance of the
/// Laplacian, the usual blur measure). Thresholds suit a ~320 px image.
PhotoQuality photoQuality(List<num> gray, int w, int h) {
  final n = w * h;
  var s = 0.0;
  for (var i = 0; i < n; i++) {
    s += gray[i];
  }
  final mean = s / n;
  var v = 0.0;
  for (var i = 0; i < n; i++) {
    v += (gray[i] - mean) * (gray[i] - mean);
  }
  final contrast = v / n <= 0 ? 0.0 : math.sqrt(v / n);
  var ls = 0.0;
  var ls2 = 0.0;
  var m = 0;
  for (var y = 1; y < h - 1; y++) {
    for (var x = 1; x < w - 1; x++) {
      final i = y * w + x;
      final lap = gray[i - w] + gray[i + w] + gray[i - 1] + gray[i + 1] - 4 * gray[i];
      ls += lap;
      ls2 += lap * lap;
      m++;
    }
  }
  final sharpness = m > 0 ? ls2 / m - (ls / m) * (ls / m) : 0.0;
  final problems = <String>[
    if (mean < 50) 'Too dark: take it in daylight or shade, not at night.',
    if (mean > 215) 'Too bright: move out of direct sun.',
    if (contrast < 20) 'Very flat: get closer so the problem fills the photo.',
    if (sharpness < 60) 'Blurred: hold the phone still and tap to focus.',
  ];
  return PhotoQuality(
    brightness: jsRound(mean).toInt(),
    contrast: jsRound(contrast).toInt(),
    sharpness: jsRound(sharpness).toInt(),
    ok: problems.isEmpty,
    problems: problems,
  );
}

const screeningEngine = 'screening-none-1';
