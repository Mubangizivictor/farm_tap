import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class ReadBackConfirmSheet extends StatelessWidget {
  const new({
    required this.summary,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final String summary;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            summary,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.correct,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: Text(l10n.no),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  child: Text(l10n.yes),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
