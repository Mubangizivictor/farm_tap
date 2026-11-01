import 'package:farm_tap/app/router/routes.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_bloc.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HerdTab extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.herd)),
      body: BlocBuilder<HerdBloc, HerdState>(
        builder: (context, state) {
          if (state.status == HerdBlocStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.animals.isEmpty) {
            return const Center(child: Text('No animals in the herd yet.'));
          }

          return ListView.builder(
            itemCount: state.animals.length,
            itemBuilder: (context, index) {
              final animal = state.animals[index];
              return ListTile(
                leading: const Icon(Icons.pets),
                title: Text(animal.name),
                subtitle: Text('${animal.breed} • ${animal.tagNumber}'),
                trailing: Text(animal.sex.name),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addAnimal),
        child: const Icon(Icons.add),
      ),
    );
  }
}
