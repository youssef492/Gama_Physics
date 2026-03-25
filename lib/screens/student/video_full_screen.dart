import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:gama/services/youtube_service.dart';
import 'package:gama/widgets/video_player_widget.dart'
    show SeekDirection, SeekHintOverlay, showVideoOptionsSheet;

const _kPrimary = Color(0xFF0D6EBE);

// ─────────────────────────────────────────────────────────────────────────────
// VideoFullScreenFvp
// بيشارك نفس الـ VideoPlayerController مع الـ VideoPlayerWidget
// ─────────────────────────────────────────────────────────────────────────────
class VideoFullScreenFvp extends StatefulWidget {
  final VideoPlayerController controller;
  final String title;
  final Duration startAt;
  final double initialSpeed;
  final String selectedQualityLabel;
  final List<YoutubeQualityOption> qualityOptions;
  final bool isYoutube;
  final String rawVideoUrl;
  final Future<void> Function(YoutubeQualityOption) onQualityChanged;

  const VideoFullScreenFvp({
    super.key,
    required this.controller,
    required this.title,
    required this.startAt,
    required this.initialSpeed,
    required this.selectedQualityLabel,
    required this.qualityOptions,
    required this.isYoutube,
    required this.rawVideoUrl,
    required this.onQualityChanged,
  });

  @override
  State<VideoFullScreenFvp> createState() => _VideoFullScreenFvpState();
}

class _VideoFullScreenFvpState extends State<VideoFullScreenFvp> {
  late double _speed;
  late String _selectedQualityLabel;
  late List<YoutubeQualityOption> _qualityOptions;

  bool _showControls = false;
  Timer? _hideTimer;
  SeekDirection? _seekHint;
  Timer? _seekHintTimer;

  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  VideoPlayerController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _speed = widget.initialSpeed;
    _selectedQualityLabel = widget.selectedQualityLabel;
    _qualityOptions = List.from(widget.qualityOptions);
    _forceLandscape();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.startAt != Duration.zero) {
        _ctrl.seekTo(widget.startAt);
      }
      if (_ctrl.value.isInitialized) {
        _ctrl.play();
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekHintTimer?.cancel();
    _restoreOrientation();
    super.dispose();
  }

  // ─── Orientation ──────────────────────────────────────────────────────────
  void _forceLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restoreOrientation() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ─── Controls visibility ───────────────────────────────────────────────────
  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _resetTimer();
  }

  void _resetTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _keepVisible() => _hideTimer?.cancel();

  // ─── Playback ─────────────────────────────────────────────────────────────
  void _togglePlayPause() {
    _ctrl.value.isPlaying ? _ctrl.pause() : _ctrl.play();
    _resetTimer();
  }

  void _seekBackward() {
    final pos = _ctrl.value.position - const Duration(seconds: 10);
    _ctrl.seekTo(pos.isNegative ? Duration.zero : pos);
    _showSeekHint(SeekDirection.backward);
    _resetTimer();
  }

  void _seekForward() {
    _ctrl.seekTo(_ctrl.value.position + const Duration(seconds: 10));
    _showSeekHint(SeekDirection.forward);
    _resetTimer();
  }

  void _showSeekHint(SeekDirection dir) {
    setState(() => _seekHint = dir);
    _seekHintTimer?.cancel();
    _seekHintTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _seekHint = null);
    });
  }

  void _setSpeed(double s) {
    setState(() => _speed = s);
    _ctrl.setPlaybackSpeed(s);
    _resetTimer();
  }

  // ─── Quality ──────────────────────────────────────────────────────────────
  Future<void> _changeQuality(YoutubeQualityOption option) async {
    setState(() => _selectedQualityLabel = option.label);
    // بنفوّض للـ VideoPlayerWidget لأنه هو اللي بيملك الـ controller فعلياً
    await widget.onQualityChanged(option);
    _resetTimer();
  }

  // ─── Pickers ──────────────────────────────────────────────────────────────
  void _showSpeedPicker() {
    _keepVisible();
    final l10n = AppLocalizations.of(context)!;
    showVideoOptionsSheet(
      context: context,
      title: l10n.playbackSpeed,
      items: _speeds.map((s) => '${s}x').toList(),
      selected: '${_speed}x',
      onSelect: (i) => _setSpeed(_speeds[i]),
    );
  }

  void _showQualityPicker() {
    if (_qualityOptions.isEmpty) return;
    _keepVisible();
    final l10n = AppLocalizations.of(context)!;
    showVideoOptionsSheet(
      context: context,
      title: l10n.videoQuality,
      items: _qualityOptions.map((q) => q.label).toList(),
      selected: _selectedQualityLabel,
      onSelect: (i) => _changeQuality(_qualityOptions[i]),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── Video ───────────────────────────────────────────────────────
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _ctrl,
            builder: (_, value, __) {
              if (!value.isInitialized) {
                return const Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                );
              }
              return FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: value.size.width,
                  height: value.size.height,
                  child: VideoPlayer(_ctrl),
                ),
              );
            },
          ),

          // ─── Seek zones (double-tap) ──────────────────────────────────────
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  onDoubleTap: _seekBackward,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  onDoubleTap: _seekForward,
                ),
              ),
            ]),
          ),

          // ─── Seek hint animation ──────────────────────────────────────────
          if (_seekHint != null)
            Directionality(
              textDirection: TextDirection.ltr,
              child: SeekHintOverlay(direction: _seekHint!),
            ),

          // ─── Controls overlay ─────────────────────────────────────────────
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: _ctrl,
                builder: (_, value, __) {
                  final isPlaying = value.isPlaying;
                  final pos = value.position;
                  final dur = value.duration;
                  final progress = dur.inMilliseconds > 0
                      ? (pos.inMilliseconds / dur.inMilliseconds)
                          .clamp(0.0, 1.0)
                      : 0.0;

                  return Stack(fit: StackFit.expand, children: [
                    // ── Top gradient + title + back ──────────────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
                        child: Row(children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 22),
                            padding: EdgeInsets.zero,
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(color: Colors.black54, blurRadius: 6)
                                ],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),

                    // ── Play / Pause center button ────────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                              color: Colors.black45, shape: BoxShape.circle),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),

                    // ── Bottom bar ────────────────────────────────────────
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: _BottomBar(
                          progress: progress.toDouble(),
                          currentSec: pos.inSeconds,
                          totalSec: dur.inSeconds,
                          speed: _speed,
                          qualityLabel: _selectedQualityLabel,
                          showQuality:
                              widget.isYoutube && _qualityOptions.isNotEmpty,
                          onExit: () => Navigator.pop(context),
                          onSpeedTap: _showSpeedPicker,
                          onQualityTap:
                              widget.isYoutube && _qualityOptions.isNotEmpty
                                  ? _showQualityPicker
                                  : null,
                          onSliderChanged: (v) {
                            _ctrl.seekTo(Duration(
                                milliseconds:
                                    (v * dur.inMilliseconds).round()));
                            _resetTimer();
                          },
                          onSliderChangeStart: (_) => _keepVisible(),
                          onSliderChangeEnd: (_) => _resetTimer(),
                        ),
                      ),
                    ),
                  ]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Bar
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final double progress;
  final int currentSec, totalSec;
  final double speed;
  final String qualityLabel;
  final bool showQuality;
  final VoidCallback onExit, onSpeedTap;
  final VoidCallback? onQualityTap;
  final ValueChanged<double> onSliderChanged,
      onSliderChangeStart,
      onSliderChangeEnd;

  const _BottomBar({
    required this.progress,
    required this.currentSec,
    required this.totalSec,
    required this.speed,
    required this.qualityLabel,
    required this.showQuality,
    required this.onExit,
    required this.onSpeedTap,
    required this.onQualityTap,
    required this.onSliderChanged,
    required this.onSliderChangeStart,
    required this.onSliderChangeEnd,
  });

  String _fmt(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Progress slider ──────────────────────────────────────────────
          SizedBox(
            height: 24,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 11),
                activeTrackColor: _kPrimary,
                inactiveTrackColor: Colors.white30,
                thumbColor: _kPrimary,
                overlayColor: const Color(0x330D6EBE),
              ),
              child: Slider(
                value: progress,
                onChangeStart: onSliderChangeStart,
                onChanged: onSliderChanged,
                onChangeEnd: onSliderChangeEnd,
              ),
            ),
          ),

          // ── Time + chips + exit ──────────────────────────────────────────
          Row(children: [
            Text(
              '${_fmt(currentSec)} / ${_fmt(totalSec)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            // Speed chip
            _ChipBtn(
              label: speed == 1.0 ? '1x' : '${speed}x',
              onTap: onSpeedTap,
            ),
            const SizedBox(width: 6),
            // Quality chip
            if (onQualityTap != null) ...[
              _ChipBtn(label: qualityLabel, onTap: onQualityTap!),
              const SizedBox(width: 10),
            ],
            // Exit fullscreen
            GestureDetector(
              onTap: onExit,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                child: Icon(
                  Icons.fullscreen_exit_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

// ─── Chip Button ──────────────────────────────────────────────────────────────
class _ChipBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ChipBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white24, width: .8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
