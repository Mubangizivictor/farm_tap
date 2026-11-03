import 'package:equatable/equatable.dart';
import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppSettings extends Equatable {
  const new({this.soundsEnabled = true});

  /// Settings > Sounds. Muted automatically when the phone is silent.
  final bool soundsEnabled;

  AppSettings copyWith({bool? soundsEnabled}) => AppSettings(soundsEnabled: soundsEnabled ?? this.soundsEnabled);

  @override
  List<Object?> get props => [soundsEnabled];
}

class AppSettingsCubit extends Cubit<AppSettings> {
  new() : super(const AppSettings());

  void setSounds({required bool enabled}) {
    SoundService.instance.enabled = enabled;
    emit(state.copyWith(soundsEnabled: enabled));
  }
}
