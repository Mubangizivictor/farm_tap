import 'dart:async';
import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/core/tenancy/tenant_provider.dart';
import 'package:farm_tap/core/ui/read_back_confirm_sheet.dart';
import 'package:farm_tap/core/utils/clock.dart';
import 'package:farm_tap/core/utils/id_generator.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/entities/animal.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_bloc.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_event.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddAnimalPage extends StatefulWidget {
  const AddAnimalPage({super.key});

  @override
  State<AddAnimalPage> createState() => _AddAnimalPageState();
}

class _AddAnimalPageState extends State<AddAnimalPage> {
  final _tagController = TextEditingController();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  AnimalSex _sex = AnimalSex.female;

  @override
  void dispose() {
    _tagController.dispose();
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.addAnimal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _tagController,
              decoration: InputDecoration(labelText: l10n.tagNumber),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.name),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _breedController,
              decoration: InputDecoration(labelText: l10n.breed),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AnimalSex>(
              initialValue: _sex,
              decoration: InputDecoration(labelText: l10n.sex),
              items: [
                DropdownMenuItem(value: AnimalSex.male, child: Text(l10n.male)),
                DropdownMenuItem(
                  value: AnimalSex.female,
                  child: Text(l10n.female),
                ),
              ],
              onChanged: (val) => setState(() => _sex = val!),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final summary = '${_nameController.text} - ${_tagController.text}';
                  unawaited(
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (context) => ReadBackConfirmSheet(
                        summary: summary,
                        onConfirm: () {
                          final animal = Animal(
                            id: getIt<IdGenerator>().generate(),
                            tenantId: getIt<TenantProvider>().currentTenantId,
                            tagNumber: _tagController.text,
                            name: _nameController.text,
                            sex: _sex,
                            breed: _breedController.text,
                            dateOfBirth: DateTime.now().subtract(const Duration(days: 365)),
                            status: AnimalStatus.active,
                            createdAt: getIt<Clock>().now(),
                            updatedAt: getIt<Clock>().now(),
                            createdBy: 'user-1',
                            updatedBy: 'user-1',
                            deviceId: 'device-1',
                            syncStatus: SyncStatus.pending,
                          );

                          getIt<HerdBloc>().add(AddAnimalRequested(animal));

                          Navigator.pop(context); // close sheet
                          context.pop(); // go back to herd list
                        },
                        onCancel: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
