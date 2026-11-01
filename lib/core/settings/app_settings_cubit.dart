import 'package:equatable/equatable.dart';
import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppSettings extends Equatable {
  const new({this.soundsEnabled = true, this.languageCode = 'en'});

  /// Settings > Sounds. Muted automatically when the phone is silent.
  final bool soundsEnabled;

  /// 'en' (English) or 'nyn' (Runyankore). A02 and N04 change it.
  final String languageCode;

  AppSettings copyWith({bool? soundsEnabled, String? languageCode}) =>
      AppSettings(soundsEnabled: soundsEnabled ?? this.soundsEnabled, languageCode: languageCode ?? this.languageCode);

  @override
  List<Object?> get props => [soundsEnabled, languageCode];
}

class AppSettingsCubit extends Cubit<AppSettings> {
  new() : super(const AppSettings());

  void setSounds({required bool enabled}) {
    SoundService.instance.enabled = enabled;
    emit(state.copyWith(soundsEnabled: enabled));
  }

  void setLanguage(String code) => emit(state.copyWith(languageCode: code));
}
