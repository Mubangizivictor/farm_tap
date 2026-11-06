import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/adaptive_sheet.dart';
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

/// A choice shown like an input (District, Role): icon, value, expand arrow.
/// Tapping opens the options in an adaptive sheet.
class FarmTapSelectField<T> extends StatelessWidget {
  const new({
    required this.label,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    super.key,
    this.value,
    this.icon,
    this.error,
    this.picker,
  });

  final String label;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final T? value;
  final IconData? icon;
  final String? error;

  /// Replaces the plain list sheet, e.g. [showSearchPicker].
  final Future<T?> Function(BuildContext context)? picker;

  Future<void> _pick(BuildContext context) async {
    final custom = picker;
    if (custom != null) {
      final picked = await custom(context);
      if (picked != null) onChanged(picked);
      return;
    }
    final picked = await showAdaptiveSheet<T>(
      context,
      builder: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(label),
          sheet.space.gapMd,
          for (final o in options)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(labelOf(o)),
              trailing: o == value ? Icon(Symbols.check_circle_rounded, fill: 1, color: sheet.colors.primary) : null,
              onTap: () => Navigator.of(sheet).pop(o),
            ),
        ],
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Semantics(
      button: true,
      label: label,
      value: v == null ? null : labelOf(v),
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: context.radii.input,
        child: InputDecorator(
          isEmpty: v == null,
          decoration: InputDecoration(
            labelText: label,
            errorText: error,
            prefixIcon: icon == null
                ? null
                : Padding(
                    padding: EdgeInsetsDirectional.only(start: context.space.lg, end: context.space.sm),
                    child: Icon(icon, size: context.sizes.iconMd, color: context.colors.onSurfaceVariant),
                  ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: Padding(
              padding: EdgeInsetsDirectional.only(end: context.space.md),
              child: Icon(Symbols.expand_more_rounded, size: context.sizes.iconMd),
            ),
            suffixIconConstraints: const BoxConstraints(),
            contentPadding: EdgeInsetsDirectional.symmetric(
              horizontal: context.space.lg,
              vertical: context.space.lg + context.space.xxs,
            ),
          ),
          child: Text(v == null ? '' : labelOf(v), style: context.text.bodyLarge),
        ),
      ),
    );
  }
}

/// Formats Ugandan mobile numbers after the +256 prefix: "772 451 908".
class UgPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 9 ? digits.substring(0, 9) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      if (i == 3 || i == 6) buf.write(' ');
      buf.write(trimmed[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// True when 9 digits were typed.
  static bool isComplete(String text) => text.replaceAll(RegExp(r'\D'), '').length == 9;
}

/// A long list with a search box (all of Uganda's districts, roles...).
/// With [allowCustom] the typed text can be used when it is not listed.
Future<String?> showSearchPicker(
  BuildContext context, {
  required String title,
  required List<String> options,
  String? selected,
  bool allowCustom = true,
}) => showAdaptiveSheet<String>(
  context,
  builder: (sheet) => _SearchPicker(title: title, options: options, selected: selected, allowCustom: allowCustom),
);

class _SearchPicker extends StatefulWidget {
  const new({required this.title, required this.options, required this.allowCustom, this.selected});

  final String title;
  final List<String> options;
  final String? selected;
  final bool allowCustom;

  @override
  State<_SearchPicker> createState() => _SearchPickerState();
}

class _SearchPickerState extends State<_SearchPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = _query.text.trim();
    final shown = [
      for (final o in widget.options)
        if (q.isEmpty || o.toLowerCase().contains(q.toLowerCase())) o,
    ];
    final exact = widget.options.any((o) => o.toLowerCase() == q.toLowerCase());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTitle(widget.title),
        context.space.gapMd,
        FarmTapTextField(
          label: l10n.searchList,
          icon: Symbols.search_rounded,
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (shown.length == 1) Navigator.of(context).pop(shown.single);
          },
        ),
        context.space.gapSm,
        if (widget.allowCustom && q.isNotEmpty && !exact)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Symbols.edit_rounded, color: context.colors.primary),
            title: Text(l10n.useTyped(q)),
            onTap: () => Navigator.of(context).pop(q),
          ),
        if (shown.isEmpty && !widget.allowCustom)
          Padding(padding: EdgeInsets.all(context.space.lg), child: Text(l10n.nothingFound)),
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final o in shown)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(o),
                    trailing: o == widget.selected
                        ? Icon(Symbols.check_circle_rounded, fill: 1, color: context.colors.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(o),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
