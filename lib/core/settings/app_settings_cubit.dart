import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:farm_tap/core/sound/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends Equatable {
  const new({this.soundsEnabled = true, this.themeMode = ThemeMode.system});

  /// Settings > Sounds. Muted automatically when the phone is silent.
  final bool soundsEnabled;

  /// Settings > Appearance: follow the phone, or always light / dark.
  final ThemeMode themeMode;

  AppSettings copyWith({bool? soundsEnabled, ThemeMode? themeMode}) =>
      AppSettings(soundsEnabled: soundsEnabled ?? this.soundsEnabled, themeMode: themeMode ?? this.themeMode);

  @override
  List<Object?> get props => [soundsEnabled, themeMode];
}

/// The phone's own settings, kept on the phone across restarts.
class AppSettingsCubit extends Cubit<AppSettings> {
  new() : super(const AppSettings());

  static const _soundsKey = 'settings.sounds';
  static const _themeKey = 'settings.theme';

  /// Reads the saved settings (silently skipped where there is no storage,
  /// e.g. widget tests).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sounds = prefs.getBool(_soundsKey) ?? true;
      final theme = ThemeMode.values.asNameMap()[prefs.getString(_themeKey)] ?? ThemeMode.system;
      SoundService.instance.enabled = sounds;
      if (!isClosed) emit(AppSettings(soundsEnabled: sounds, themeMode: theme));
    } on Object {
      // No storage: keep the defaults.
    }
  }

  void setSounds({required bool enabled}) {
    SoundService.instance.enabled = enabled;
    emit(state.copyWith(soundsEnabled: enabled));
    unawaited(_save((p) => p.setBool(_soundsKey, enabled)));
  }

  void setTheme(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
    unawaited(_save((p) => p.setString(_themeKey, mode.name)));
  }

  Future<void> _save(Future<bool> Function(SharedPreferences) write) async {
    try {
      await write(await SharedPreferences.getInstance());
    } on Object {
      // No storage: the choice lasts until the app closes.
    }
  }
}
