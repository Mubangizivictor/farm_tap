import 'package:farm_tap/core/theme/colors/farmtap_semantic_colors.dart';
import 'package:flutter/material.dart';

enum StatusType { success, warning, danger, info }

class StatusBanner extends StatelessWidget {
  const new({
    required this.message,
    required this.type,
    super.key,
  });

  final String message;
  final StatusType type;

  @override
  Widget build(BuildContext context) {
    final statusColors = Theme.of(context).extension<FarmTapSemanticColors>()!;
    
    final (bgColor, textColor) = switch (type) {
      StatusType.success => (statusColors.success, statusColors.onSuccess),
      StatusType.warning => (statusColors.warning, statusColors.onWarning),
      StatusType.danger => (statusColors.danger, statusColors.onDanger),
      StatusType.info => (statusColors.info, statusColors.onInfo),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bgColor),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
