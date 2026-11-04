import 'dart:async';

import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/theme/theme.dart';
import 'package:farm_tap/core/ui/ui.dart';
import 'package:farm_tap/sectors/cattle/operations/data/operations_repository.dart';
import 'package:farm_tap/sectors/cattle/operations/domain/operations_models.dart';
import 'package:farm_tap/sectors/cattle/operations/presentation/pages/operations_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Farm contacts (decision 0024): vet, AI technician, feed suppliers, buyers,
/// emergency numbers. Call or WhatsApp with one tap. The same list as the web.
class ContactsPage extends StatefulWidget {
  const new({required this.repo, required this.canEdit, super.key});

  final OperationsRepository repo;
  final bool canEdit;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  String _q = '';

  @override
  void initState() {
    super.initState();
    if (!widget.repo.loaded) unawaited(widget.repo.restore());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.repo,
      builder: (context, _) {
        final q = _q.trim().toLowerCase();
        final all = widget.repo.contacts.where((c) => widget.canEdit || c.showWorkers).toList();
        final shown = all
            .where((c) => q.isEmpty || '${c.name} ${c.org ?? ''} ${c.phone}'.toLowerCase().contains(q))
            .toList();
        return AdaptiveScaffold(
          title: l10n.opsContacts,
          showBack: true,
          floatingActionButton: widget.canEdit
              ? FarmTapFab(label: l10n.opsAddContact, icon: Symbols.person_add_rounded, onPressed: () => _edit(null))
              : null,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (all.length > 6) ...[
                SearchField(hint: l10n.opsSearchContacts, onChanged: (v) => setState(() => _q = v)),
                context.space.gapMd,
              ],
              if (!widget.repo.loaded)
                const FarmTapPageLoader()
              else if (shown.isEmpty)
                EmptyState(
                  title: l10n.opsNoContacts,
                  message: l10n.opsNoContactsBody,
                  actionLabel: widget.canEdit ? l10n.opsAddContact : null,
                  onAction: widget.canEdit ? () => _edit(null) : null,
                )
              else
                for (final kind in ContactKind.values)
                  if (shown.any((c) => c.kind == kind)) ...[
                    ListCard(
                      title: contactKindLabel(l10n, kind),
                      children: [
                        for (final c in shown.where((c) => c.kind == kind))
                          RecordTile(
                            leading: PersonAvatar(name: c.name, size: context.sizes.avatarMd),
                            title: c.name,
                            subtitle: [c.org, c.phone].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                            trailing: c.phone.isEmpty ? null : CallButtons(phone: c.phone),
                            showChevron: false,
                            onTap: widget.canEdit ? () => _edit(c) : null,
                          ),
                      ],
                    ),
                    context.space.gapMd,
                  ],
              if (!widget.canEdit) const ViewOnlyNote(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _edit(FarmContact? c) => showAdaptiveSheet<void>(
    context,
    builder: (_) => _ContactForm(repo: widget.repo, contact: c),
  );
}

class _ContactForm extends StatefulWidget {
  const new({required this.repo, this.contact});

  final OperationsRepository repo;
  final FarmContact? contact;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  late final _name = TextEditingController(text: widget.contact?.name);
  late final _phone = TextEditingController(text: widget.contact?.phone);
  late final _org = TextEditingController(text: widget.contact?.org);
  late final _place = TextEditingController(text: widget.contact?.place);
  late ContactKind _kind = widget.contact?.kind ?? ContactKind.vet;
  late bool _show = widget.contact?.showWorkers ?? true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _org, _place]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_name.text.trim().isEmpty || _phone.text.replaceAll(RegExp(r'\D'), '').length < 9) {
      setState(() => _error = l10n.opsContactNeeds);
      return;
    }
    setState(() => _saving = true);
    await widget.repo.saveContact(
      FarmContact(
        id: widget.contact?.id ?? '',
        name: _name.text.trim(),
        kind: _kind,
        phone: _phone.text.trim(),
        phone2: widget.contact?.phone2,
        org: _org.text.trim().isEmpty ? null : _org.text.trim(),
        place: _place.text.trim().isEmpty ? null : _place.text.trim(),
        note: widget.contact?.note,
        showWorkers: _show,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    setState(() => _saving = true);
    await widget.repo.removeContact(widget.contact!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FormSheet(
      title: widget.contact == null ? l10n.opsAddContact : l10n.opsEditContact,
      saving: _saving,
      onSave: _save,
      onDelete: widget.contact == null ? null : _remove,
      children: [
        FarmTapSelectField<ContactKind>(
          label: l10n.opsContactKind,
          options: ContactKind.values,
          value: _kind,
          labelOf: (k) => contactKindLabel(l10n, k),
          onChanged: (k) => setState(() => _kind = k),
        ),
        FarmTapTextField(label: l10n.name, controller: _name, textInputAction: TextInputAction.next),
        FarmTapTextField(
          label: l10n.phone,
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9+ ]'))],
          error: _error,
        ),
        FarmTapTextField(label: l10n.opsContactOrg, controller: _org),
        FarmTapTextField(label: l10n.opsContactPlace, controller: _place),
        CheckRow(label: l10n.opsShowWorkers, value: _show, onChanged: (v) => setState(() => _show = v)),
      ],
    );
  }
}
