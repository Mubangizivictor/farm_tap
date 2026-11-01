import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:farm_tap/core/theme/farmtap_assets.dart';
import 'package:just_audio/just_audio.dart';

/// Plays the short UI sounds. Widgets call [SoundService.instance]; the app
/// swaps in [JustAudioSoundService] at start-up, tests keep the silent one.
abstract class SoundService {
  static SoundService instance = NoOpSoundService();

  /// Settings > Sounds. Default on.
  bool enabled = true;

  Future<void> play(FarmTapSound sound);
}

class NoOpSoundService extends SoundService {
  /// Sounds requested while enabled (handy in tests).
  final List<FarmTapSound> played = [];

  @override
  Future<void> play(FarmTapSound sound) async {
    if (enabled) played.add(sound);
  }
}

class JustAudioSoundService extends SoundService {
  final Map<FarmTapSound, AudioPlayer> _players = {};
  bool _configured = false;

  Future<void> _configure() async {
    if (_configured) return;
    _configured = true;
    final session = await AudioSession.instance;
    // Notification-type audio on Android and "ambient" on iOS follow the
    // phone's silent / ringer switch, so sounds stay quiet when it is silent.
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.notificationEvent,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      ),
    );
  }

  @override
  Future<void> play(FarmTapSound sound) async {
    if (!enabled) return;
    try {
      await _configure();
      final player = _players[sound] ??= AudioPlayer();
      if (player.audioSource == null) await player.setAsset(sound.asset);
      await player.seek(Duration.zero);
      unawaited(player.play());
    } on Object {
      // A missing or unplayable sound must never break recording.
    }
  }
}
