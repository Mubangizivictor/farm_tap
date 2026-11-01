import 'package:farm_tap/core/onboarding/domain/farm_setup.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The onboarding draft, shared by every step (B01-B10). Each step pushes
/// the next, so back always returns to the previous step with its answers.
class OnboardingCubit extends Cubit<FarmSetup> {
  new() : super(const FarmSetup());

  void update(FarmSetup Function(FarmSetup) change) => emit(change(state));

  void reset() => emit(const FarmSetup());
}
