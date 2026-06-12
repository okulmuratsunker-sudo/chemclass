part of 'app_state.dart';

/// "Sesli Oku" — reads assignment/announcement/message text aloud.
extension AppStateTts on AppState {
  Future<void> speak(String text) => ttsService.speak(text);
  Future<void> stopSpeaking() => ttsService.stop();
}
