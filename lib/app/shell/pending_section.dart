// TEMPORARY (UI rebuild): root of a shell branch whose screens are not built
// yet. Each section replaces its entry in app_router.dart; this file is
// deleted when the last section (P) is done. Dev-only text, not in the ARB.
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:flutter/material.dart';

class PendingSection extends StatelessWidget {
  const new({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: title,
      scrollable: false,
      body: EmptyState(title: title, animation: FarmTapAnimations.cowGrazing),
    );
  }
}
