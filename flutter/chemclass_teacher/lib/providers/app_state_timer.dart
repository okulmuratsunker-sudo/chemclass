part of 'app_state.dart';

/// Countdown timer - mirrors `setTimer()` / `startTimer()` / `pauseTimer()` /
/// `resetTimer()` / `drawTimer()`.
extension AppStateTimer on AppState {
  bool get timerDanger => timerLeft > 0 && timerLeft <= 10;

  String get timerDisplay => fmtTime(timerLeft);

  void setTimer(int minutes, int seconds) {
    pauseTimer();
    timerTotal = (minutes * 60 + seconds);
    timerLeft = timerTotal;
    notify();
  }

  /// Returns an error message, or `null` on success.
  String? startTimer(int minutes, int seconds) {
    if (timerRunning) return null;
    if (timerLeft <= 0 || timerLeft == timerTotal) {
      timerTotal = minutes * 60 + seconds;
      timerLeft = timerTotal;
    }
    if (timerLeft <= 0) return 'Süre girin';

    _timerHandle = Timer.periodic(const Duration(seconds: 1), (_) {
      timerLeft--;
      if (timerLeft <= 0) {
        pauseTimer();
        soundService.play(sndType);
        toast('⏰ Süre bitti!');
      }
      notify();
    });
    setBoardView('timer');
    notify();
    return null;
  }

  void pauseTimer() {
    if (_timerHandle != null) {
      _timerHandle!.cancel();
      _timerHandle = null;
      scheduleBoardUpdate();
      notify();
    }
  }

  void resetTimer(int minutes, int seconds) {
    pauseTimer();
    timerTotal = minutes * 60 + seconds;
    if (timerTotal <= 0) timerTotal = 300;
    timerLeft = timerTotal;
    scheduleBoardUpdate();
    notify();
  }

  void setSound(TimerSound sound) {
    sndType = sound;
    _storage.setSound(sound.key);
    notify();
  }

  void testSound() {
    soundService.play(sndType);
  }
}
