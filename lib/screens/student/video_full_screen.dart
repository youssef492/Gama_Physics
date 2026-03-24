import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:gama/services/youtube_service.dart';
import 'package:gama/widgets/video_player_widget.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

const _kPrimary = Color(0xFF0D6EBE);

class VideoFullScreenScreen extends StatefulWidget {
  final String? videoId;
  final String? embedUrl;
  final String title;
  final Duration startAt;
  final bool isYoutube;
  final double initialSpeed;
  final String initialQuality;
  final List<YoutubeQualityOption> qualityOptions;
  final Player? player; // ✅ إضافة دعم تمرير الـ player

  // ─── YouTube constructor ────────────────────────────────────────────────
  const VideoFullScreenScreen.youtube({
    super.key,
    required String videoId,
    required this.title,
    this.startAt = Duration.zero,
    this.initialSpeed = 1.0,
    this.initialQuality = 'auto',
    this.qualityOptions = const [],
    this.player, // ✅
  })  : videoId = videoId,
        embedUrl = null,
        isYoutube = true;

  // ─── Web/Drive constructor ──────────────────────────────────────────────
  const VideoFullScreenScreen.web({
    super.key,
    required String embedUrl,
    required this.title,
    this.startAt = Duration.zero, // ✅ أضفنا استلام وقت البدء للـ web
    this.player, // ✅
  })  : embedUrl = embedUrl,
        videoId = null,
        isYoutube = false,
        initialSpeed = 1.0,
        initialQuality = 'auto',
        qualityOptions = const [];

  @override
  State<VideoFullScreenScreen> createState() => _VideoFullScreenScreenState();
}

class _VideoFullScreenScreenState extends State<VideoFullScreenScreen> {
  // media_kit
  late final Player _player;
  late final VideoController _controller;

  bool _isLoading = true;
  bool _hasError = false;
  bool _showControls = false;
  Timer? _hideTimer;

  late double _speed;
  late String _selectedQualityLabel;
  List<YoutubeQualityOption> _qualityOptions = [];

  SeekDirection? _seekHint;
  Timer? _seekHintTimer;

  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _speed = widget.initialSpeed;
    _selectedQualityLabel = widget.initialQuality;
    _qualityOptions = widget.qualityOptions;
    _forceLandscape();

    // ✅ لو في player ممرر، استخدمه. غير كده انشئ واحد جديد.
    _player = widget.player ?? Player();
    _controller = VideoController(_player);

    if (widget.player == null) {
      _loadVideo();
    } else {
      // لو ممرر، هو شغال فعلاً فبلاش loading
      _isLoading = false;
      // تأكد أن الـ rate مظبوط
      _player.setRate(_speed);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekHintTimer?.cancel();
    // ✅ احذف الـ player لو كنت أنت اللي منشئه بس
    if (widget.player == null) {
      _player.dispose();
    }
    _restoreOrientation();
    super.dispose();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      String url;
      if (widget.isYoutube) {
        // لو عنده quality options جاهزة استخدمها
        if (_qualityOptions.isNotEmpty) {
          final chosen = _qualityOptions
              .where((q) => q.label == _selectedQualityLabel)
              .firstOrNull;
          url = chosen?.url ?? _qualityOptions.first.url;
          _selectedQualityLabel = chosen?.label ?? _qualityOptions.first.label;
        } else {
          // جيب من youtube_explode
          final result = await YoutubeService.getStreamUrl(widget.videoId!);
          _qualityOptions = result.allStreams;
          _selectedQualityLabel =
              _qualityOptions.isNotEmpty ? _qualityOptions.first.label : 'auto';
          url = result.streamUrl;
        }
      } else {
        url = widget.embedUrl!;
      }

      await _player.open(Media(url), play: true);
      if (widget.startAt != Duration.zero) {
        await _player.seek(widget.startAt);
      }
      await _player.setRate(_speed);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
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

  // ─── Controls ─────────────────────────────────────────────────────────────

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

  void _togglePlayPause() {
    _player.state.playing ? _player.pause() : _player.play();
    _resetTimer();
  }

  void _seekBackward() {
    final t = _player.state.position - const Duration(seconds: 10);
    _player.seek(t.isNegative ? Duration.zero : t);
    _showSeekHint(SeekDirection.backward);
    _resetTimer();
  }

  void _seekForward() {
    _player.seek(_player.state.position + const Duration(seconds: 10));
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
    _player.setRate(s);
    _resetTimer();
  }

  Future<void> _setQuality(YoutubeQualityOption option) async {
    setState(() {
      _selectedQualityLabel = option.label;
      _isLoading = true;
    });

    final pos = _player.state.position;
    final wasPlaying = _player.state.playing;

    try {
      final result = await YoutubeService.getStreamUrl(
        widget.videoId!,
        retryCount: 1,
      );

      final chosen =
          result.allStreams.where((q) => q.label == option.label).firstOrNull;
      final url = chosen?.url ?? option.url;

      setState(() => _qualityOptions = result.allStreams);

      await _player.open(Media(url), play: false);
      await _player.seek(pos);
      if (wasPlaying) await _player.play();
      await _player.setRate(_speed);
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      await _player.open(Media(option.url), play: false);
      await _player.seek(pos);
      if (wasPlaying) await _player.play();
      await _player.setRate(_speed);
      if (mounted) setState(() => _isLoading = false);
    }

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
      onSelect: (i) => _setQuality(_qualityOptions[i]),
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
          // ── Video ────────────────────────────────────────────────────────
          Video(
            controller: _controller,
            controls: NoVideoControls,
            fit: BoxFit.contain,
          ),

          // ── Loading ──────────────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.black87,
              child: const Center(
                child: CircularProgressIndicator(color: _kPrimary),
              ),
            ),

          // ── Error ────────────────────────────────────────────────────────
          if (_hasError)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.video_error,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadVideo,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.video_retry),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: _kPrimary),
                    ),
                  ],
                ),
              ),
            ),

          // ── Tap zones ────────────────────────────────────────────────────
          if (!_isLoading && !_hasError)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
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
                ],
              ),
            ),

          // ── Seek hint ────────────────────────────────────────────────────
          if (_seekHint != null)
            Directionality(
              textDirection: TextDirection.ltr,
              child: SeekHintOverlay(direction: _seekHint!),
            ),

          // ── Controls overlay ─────────────────────────────────────────────
          if (!_isLoading && !_hasError)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: StreamBuilder<bool>(
                  stream: _player.stream.playing,
                  initialData: false,
                  builder: (context, playSnap) {
                    final isPlaying = playSnap.data ?? false;
                    return StreamBuilder<Duration>(
                      stream: _player.stream.position,
                      initialData: Duration.zero,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = _player.state.duration;
                        final progress = dur.inMilliseconds > 0
                            ? (pos.inMilliseconds / dur.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            // Top bar: back + title
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black87,
                                      Colors.transparent
                                    ],
                                  ),
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(4, 8, 16, 20),
                                child: Row(
                                  children: [
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
                                            Shadow(
                                                color: Colors.black54,
                                                blurRadius: 6)
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Center play/pause
                            Center(
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
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

                            // Bottom bar — always LTR
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: _VlcBarFS(
                                  progress: progress.toDouble(),
                                  currentSec: pos.inSeconds,
                                  totalSec: dur.inSeconds,
                                  speed: _speed,
                                  qualityLabel: _selectedQualityLabel,
                                  onExit: () => Navigator.pop(context),
                                  onSpeedTap: _showSpeedPicker,
                                  onQualityTap: _qualityOptions.isNotEmpty
                                      ? _showQualityPicker
                                      : null,
                                  onSliderChanged: (v) {
                                    _player.seek(Duration(
                                        milliseconds:
                                            (v * dur.inMilliseconds).round()));
                                    _resetTimer();
                                  },
                                  onSliderChangeStart: (_) => _keepVisible(),
                                  onSliderChangeEnd: (_) => _resetTimer(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
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
// VLC Bar Fullscreen
// ─────────────────────────────────────────────────────────────────────────────
class _VlcBarFS extends StatelessWidget {
  final double progress;
  final int currentSec, totalSec;
  final double speed;
  final String qualityLabel;
  final VoidCallback onExit, onSpeedTap;
  final VoidCallback? onQualityTap;
  final ValueChanged<double> onSliderChanged,
      onSliderChangeStart,
      onSliderChangeEnd;

  const _VlcBarFS({
    required this.progress,
    required this.currentSec,
    required this.totalSec,
    required this.speed,
    required this.qualityLabel,
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
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent])),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
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
                  onChangeEnd: onSliderChangeEnd),
            )),
        Row(children: [
          Text('${_fmt(currentSec)} / ${_fmt(totalSec)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
          const Spacer(),
          _ChipBtn(label: speed == 1.0 ? '1x' : '${speed}x', onTap: onSpeedTap),
          const SizedBox(width: 6),
          if (onQualityTap != null)
            _ChipBtn(label: qualityLabel, onTap: onQualityTap!),
          const SizedBox(width: 10),
          GestureDetector(
              onTap: onExit,
              child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  child: Icon(Icons.fullscreen_exit_rounded,
                      color: Colors.white, size: 22))),
        ]),
        const SizedBox(height: 2),
      ]),
    );
  }
}
// ─── Chip button ──────────────────────────────────────────────────────────────

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
