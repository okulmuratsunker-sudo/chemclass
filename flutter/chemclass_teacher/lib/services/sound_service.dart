import 'package:audioplayers/audioplayers.dart';

import '../utils/constants.dart';

/// Plays the countdown timer's end-of-time sound, mirroring the web app's
/// Web Audio API `beep()` function (beep / chime / alarm / silent).
class SoundService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(TimerSound sound) async {
    if (sound == TimerSound.silent) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/${sound.key}.wav'));
    } catch (_) {
      // Ignore playback errors (e.g. no audio device available).
    }
  }

  void dispose() {
    _player.dispose();
  }
}
