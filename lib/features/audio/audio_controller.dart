import 'package:just_audio/just_audio.dart';

class AudioController {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playFromUrl(String url) async {
    await _player.setUrl(url);
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}

