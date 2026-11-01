import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Outlined input: 60 tall, radius 14, fill c0, 1.2 outline border (2
/// primary when focused, 2 danger on error). Leading icon 24 at x16, text
/// (bodyLarge) at x52, optional prefix ("UGX"). Floating label labelSmall.
/// [password] adds the show/hide eye. Errors appear under the field, never
/// as a popup.
class FarmTapTextField extends StatefulWidget {
  const new({
    required this.label,
    super.key,
    this.controller,
    this.focusNode,
    this.icon,
    this.prefixText,
    this.hint,
    this.helper,
    this.error,
    this.password = false,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final IconData? icon;
  final String? prefixText;
  final String? hint;
  final String? helper;
  final String? error;
  final bool password;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<FarmTapTextField> createState() => _FarmTapTextFieldState();
}

class _FarmTapTextFieldState extends State<FarmTapTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final iconColor = widget.error != null ? context.colors.error : context.colors.onSurfaceVariant;
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      obscureText: widget.password && _obscured,
      enableSuggestions: !widget.password,
      autocorrect: !widget.password,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: context.text.bodyLarge,
      cursorWidth: context.sizes.borderThick,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        helperText: widget.error == null ? widget.helper : null,
        errorText: widget.error,
        prefixText: widget.prefixText,
        prefixStyle: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
        prefixIcon: widget.icon == null
            ? null
            : Padding(
                padding: EdgeInsetsDirectional.only(start: context.space.lg, end: context.space.sm),
                child: Icon(widget.icon, size: context.sizes.iconMd, color: iconColor),
              ),
        prefixIconConstraints: const BoxConstraints(),
        suffixIcon: widget.password
            ? Padding(
                padding: EdgeInsetsDirectional.only(end: context.space.xs),
                child: IconButton(
                  tooltip: _obscured ? l10n.showPassword : l10n.hidePassword,
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured ? Symbols.visibility_rounded : Symbols.visibility_off_rounded,
                    size: context.sizes.iconMd,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              )
            : null,
        helperStyle: context.text.bodySmall,
        errorStyle: context.text.bodySmall?.copyWith(color: context.colors.error),
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: context.space.lg,
          vertical: context.space.lg + context.space.xxs,
        ),
      ),
    );
  }
}
