// ─── دالة مساعدة — ضيفها في video_player_widget.dart و video_full_screen.dart ───
//
// media_kit بيدعم audio track منفصل عن طريق MediaKit configuration
// لو الـ stream HLS video-only، بنعمل open للـ video URL وبعدين
// نضيف الـ audio file عن طريق mpv property

import 'package:media_kit/media_kit.dart';

/// افتح فيديو مع audio منفصل لو موجود (للـ HLS video-only streams)
Future<void> openMediaWithAudio(
  Player player,
  String videoUrl, {
  String? audioUrl,
  bool play = false,
}) async {
  await player.open(Media(videoUrl), play: false);

  // لو في audio منفصل → ضيفه عن طريق mpv
  if (audioUrl != null && audioUrl.isNotEmpty) {
    try {
      // media_kit (MPV backend) بيدعم audio-file property
      await player.setAudioTrack(
        AudioTrack.uri(audioUrl),
      );
    } catch (e) {
      }
  }

  if (play) await player.play();
}

// ─── الاستخدام في _loadVideo() ────────────────────────────────────────────────
//
// بدل:
//   await _player.open(Media(url), play: false);
//
// استخدم:
//   final option = _qualityOptions.first;
//   await openMediaWithAudio(
//     _player,
//     option.url,
//     audioUrl: option.audioUrl,
//     play: false,
//   );
//
// وفي _setQuality():
//   await openMediaWithAudio(
//     _player,
//     chosen.url,
//     audioUrl: chosen.audioUrl,
//     play: wasPlaying,
//   );
