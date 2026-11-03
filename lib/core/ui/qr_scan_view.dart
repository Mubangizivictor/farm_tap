// A live QR camera inside the dark viewfinder card: ear tags (E05), staff
// and farmer cards. The torch button works; the same code is not reported
// twice in a row within a moment, so one card is not read twice.
import 'dart:async';
import 'dart:io';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScanView extends StatefulWidget {
  const new({required this.onCode, required this.prompt, super.key, this.extraAction, this.paused = false});

  /// A QR code was read (its raw text).
  final ValueChanged<String> onCode;
  final String prompt;

  /// A second button beside the torch (e.g. "Type tag instead").
  final Widget? extraAction;

  /// True while the result of a scan is showing: no new reads.
  final bool paused;

  @override
  State<QrScanView> createState() => _QrScanViewState();
}

class _QrScanViewState extends State<QrScanView> {
  // Widget tests and the web have no camera: show the frame only.
  static final bool _camera = !kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST');

  MobileScannerController? _controller;
  bool _torch = false;
  String? _last;
  DateTime _lastAt = DateTime(0);

  @override
  void initState() {
    super.initState();
    if (_camera) _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  void _detect(BarcodeCapture capture) {
    if (widget.paused) return;
    final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (code == null) return;
    final now = DateTime.now();
    if (code == _last && now.difference(_lastAt) < context.motion.autoAdvance) return;
    _last = code;
    _lastAt = now;
    widget.onCode(code);
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null) return;
    try {
      await c.toggleTorch();
      if (mounted) setState(() => _torch = !_torch);
    } on Object {
      // No torch on this phone: nothing to do.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final on = context.status.onViewfinder;
    final c = _controller;
    return AspectRatio(
      aspectRatio: context.isCompact ? context.sizes.viewfinderAspect : context.sizes.viewfinderAspectWide,
      child: Container(
        decoration: BoxDecoration(color: context.status.viewfinder, borderRadius: context.radii.dialog),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (c != null)
              MobileScanner(
                controller: c,
                onDetect: _detect,
                errorBuilder: (context, error) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(context.space.xl),
                    child: Text(
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                          ? l10n.cameraPermissionNeeded
                          : l10n.cameraNotAvailable,
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(color: on),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(context.space.xl),
              child: Column(
                children: [
                  Text(
                    widget.prompt,
                    textAlign: TextAlign.center,
                    style: context.text.titleSmall?.copyWith(color: on),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: context.space.xl),
                      child: const ScanFrame(),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: l10n.torch,
                        onPressed: c == null ? null : _toggleTorch,
                        icon: Icon(
                          _torch ? Symbols.flash_off_rounded : Symbols.flash_on_rounded,
                          color: on,
                          size: context.sizes.iconLg,
                        ),
                      ),
                      if (widget.extraAction != null) ...[context.space.gapXl, widget.extraAction!],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four corner brackets and a gold scan line.
class ScanFrame extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(
        corner: context.status.viewfinderAccent,
        line: context.status.brandGold,
        stroke: context.sizes.scanFrameStroke,
        arm: context.sizes.scanFrameArm,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _FramePainter extends CustomPainter {
  new({required this.corner, required this.line, required this.stroke, required this.arm});

  final Color corner;
  final Color line;
  final double stroke;
  final double arm;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final rect = Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side);
    final p = Paint()
      ..color = corner
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke;
    for (final (o, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(o, o + Offset(arm * dx, 0), p)
        ..drawLine(o, o + Offset(0, arm * dy), p);
    }
    canvas.drawLine(
      Offset(rect.left + arm / 2, rect.center.dy),
      Offset(rect.right - arm / 2, rect.center.dy),
      Paint()
        ..color = line
        ..strokeWidth = stroke / 1.5,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.corner != corner || old.line != line;
}
