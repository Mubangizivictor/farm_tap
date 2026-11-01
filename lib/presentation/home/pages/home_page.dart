import 'package:farm_tap/app/di/injection.dart';
import 'package:farm_tap/core/l10n/generated/app_localizations.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_bloc.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_event.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/pages/herd_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const new({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const HerdTab(),
    const Center(child: Text('Milk Tab')),
    const Center(child: Text('Health Tab')),
    const Center(child: Text('More Tab')),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider(
      create: (context) => HerdBloc(watchAnimals: getIt(), addAnimal: getIt())..add(const WatchAnimalsRequested()),
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.pets), label: l10n.herd),
            NavigationDestination(icon: const Icon(Icons.water_drop), label: l10n.milk),
            NavigationDestination(icon: const Icon(Icons.health_and_safety), label: l10n.health),
            NavigationDestination(icon: const Icon(Icons.more_horiz), label: l10n.more),
          ],
        ),
      ),
    );
  }
}
