import 'dart:async';

import 'package:farm_tap/sectors/cattle/herd/domain/usecases/add_animal.dart';
import 'package:farm_tap/sectors/cattle/herd/domain/usecases/watch_animals.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_event.dart';
import 'package:farm_tap/sectors/cattle/herd/presentation/bloc/herd_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HerdBloc extends Bloc<HerdEvent, HerdState> {
  HerdBloc({
    required this.watchAnimals,
    required this.addAnimal,
  })  : super(const HerdState()) {
    on<WatchAnimalsRequested>(_onWatchAnimalsRequested);
    on<AnimalsUpdated>(_onAnimalsUpdated);
    on<AddAnimalRequested>(_onAddAnimalRequested);
  }

  final WatchAnimals watchAnimals;
  final AddAnimal addAnimal;
  StreamSubscription<dynamic>? _animalsSubscription;

  Future<void> _onWatchAnimalsRequested(
    WatchAnimalsRequested event,
    Emitter<HerdState> emit,
  ) async {
    emit(state.copyWith(status: HerdBlocStatus.loading));
    await _animalsSubscription?.cancel();
    _animalsSubscription = watchAnimals().listen((result) {
      add(AnimalsUpdated(result.data ?? []));
    });
  }

  void _onAnimalsUpdated(
    AnimalsUpdated event,
    Emitter<HerdState> emit,
  ) {
    emit(state.copyWith(
      status: HerdBlocStatus.success,
      animals: event.animals,
    ));
  }

  Future<void> _onAddAnimalRequested(
    AddAnimalRequested event,
    Emitter<HerdState> emit,
  ) async {
    final result = await addAnimal(event.animal);
    if (result.isFailure) {
      emit(
        state.copyWith(
          status: HerdBlocStatus.failure,
          errorMessage: result.failure?.message,
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _animalsSubscription?.cancel();
    return super.close();
  }
}
