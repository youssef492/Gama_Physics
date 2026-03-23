import 'dart:async';
import 'package:GAMA/l10n/app_localizations.dart';
import 'package:GAMA/services/youtube_service.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

enum SeekDirection { forward, backward }

// ─── Video load state ─────────────────────────────────────────────────────────
enum _VideoLoadState { fetchingUrl, buffering, ready, errorOffline, errorOther }

const _kPrimary = Color(0xFF0D6EBE);

// ─────────────────────────────────────────────────────────────────────────────
// VideoPlayerWidget
// ─────────────────────────────────────────────────────────────────────────────
class VideoPlayerWidget extends StatefulWidget {
  final String embedUrl;
  final String title;
  final String videoType;
  final String rawVideoUrl;

  const VideoPlayerWidget({
    super.key,
    required this.embedUrl,
    required this.title,
    required this.videoType,
    required this.rawVideoUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late final Player _player;
  late final VideoController _controller;

  _VideoLoadState _loadState = _VideoLoadState.fetchingUrl;
  bool _showControls = false;
  Timer? _hideTimer;
  double _playbackSpeed = 1.0;
  SeekDirection? _seekHint;
  Timer? _seekHintTimer;
  List<YoutubeQualityOption> _qualityOptions = [];
  String _selectedQualityLabel = 'auto';

  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _loadVideo();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekHintTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  // ─── Load video ─────────────────────────────────────────────────────────────
  Future<void> _loadVideo() async {
    if (!mounted) return;
    setState(() => _loadState = _VideoLoadState.fetchingUrl);

    try {
      String url;
      if (widget.videoType == 'youtube') {
        // Step 1: جيب الـ URL (من cache أو network)
        final result = await YoutubeService.getStreamUrl(widget.rawVideoUrl);
        _qualityOptions = result.allStreams;
        if (_qualityOptions.isNotEmpty) {
          _selectedQualityLabel = _qualityOptions.first.label;
        }
        url = result.streamUrl;
      } else {
        url = widget.embedUrl;
      }

      if (!mounted) return;
      // Step 2: الـ media_kit يبدأ يحمل
      setState(() => _loadState = _VideoLoadState.buffering);

      await _player.open(Media(url), play: false);

      // نستنى الـ buffering يخلص
      _player.stream.buffering.listen((buffering) {
        if (!buffering && mounted && _loadState == _VideoLoadState.buffering) {
          setState(() => _loadState = _VideoLoadState.ready);
        }
      });

      // fallback: لو ما اشتغلش الـ stream بعد 3 ثواني نعتبره ready
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _loadState == _VideoLoadState.buffering) {
          setState(() => _loadState = _VideoLoadState.ready);
        }
      });
    } on TimeoutException {
      if (mounted) setState(() => _loadState = _VideoLoadState.errorOffline);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') ||
          msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('connection')) {
        setState(() => _loadState = _VideoLoadState.errorOffline);
      } else {
        setState(() => _loadState = _VideoLoadState.errorOther);
      }
    }
  }

  // ─── Controls logic ─────────────────────────────────────────────────────────
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
    final pos = _player.state.position - const Duration(seconds: 10);
    _player.seek(pos.isNegative ? Duration.zero : pos);
    _showSeekHintAnim(SeekDirection.backward);
    _resetTimer();
  }

  void _seekForward() {
    _player.seek(_player.state.position + const Duration(seconds: 10));
    _showSeekHintAnim(SeekDirection.forward);
    _resetTimer();
  }

  void _showSeekHintAnim(SeekDirection dir) {
    setState(() => _seekHint = dir);
    _seekHintTimer?.cancel();
    _seekHintTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _seekHint = null);
    });
  }

  void _setSpeed(double s) {
    setState(() => _playbackSpeed = s);
    _player.setRate(s);
    _resetTimer();
  }

  Future<void> _setQuality(YoutubeQualityOption option) async {
    setState(() {
      _selectedQualityLabel = option.label;
      _loadState = _VideoLoadState.buffering;
    });
    final pos = _player.state.position;
    final wasPlaying = _player.state.playing;
    await _player.open(Media(option.url), play: false);
    await _player.seek(pos);
    if (wasPlaying) await _player.play();
    if (mounted) setState(() => _loadState = _VideoLoadState.ready);
    _resetTimer();
  }

  Future<void> _openFullScreen() async {
    final pos = _player.state.position;
    final wasPlaying = _player.state.playing;
    await _player.pause();
    setState(() => _showControls = false);
    _hideTimer?.cancel();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoFullScreenMediaKit(
          rawUrl: widget.rawVideoUrl,
          videoType: widget.videoType,
          title: widget.title,
          startAt: pos,
          initialSpeed: _playbackSpeed,
          qualityOptions: _qualityOptions,
          selectedQuality: _selectedQualityLabel,
        ),
      ),
    );

    if (wasPlaying && mounted) _player.play();
  }

  void _showSpeedPicker() {
    _keepVisible();
    final l10n = AppLocalizations.of(context)!;
    showVideoOptionsSheet(
      context: context,
      title: l10n.playbackSpeed,
      items: _speeds.map((s) => '${s}x').toList(),
      selected: '${_playbackSpeed}x',
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

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video (دايماً موجود في الخلفية)
          Video(
            controller: _controller,
            controls: NoVideoControls,
            fit: BoxFit.contain,
          ),

          // ─── Overlay حسب الـ state ────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStateOverlay(),
          ),

          // ─── Tap zones ────────────────────────────────────────────────────
          if (_loadState == _VideoLoadState.ready)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                    onDoubleTap: _seekBackward,
                  )),
                  Expanded(
                      child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                    onDoubleTap: _seekForward,
                  )),
                ],
              ),
            ),

          // ─── Seek hint ────────────────────────────────────────────────────
          if (_seekHint != null)
            Directionality(
              textDirection: TextDirection.ltr,
              child: SeekHintOverlay(direction: _seekHint!),
            ),

          // ─── Controls overlay ─────────────────────────────────────────────
          if (_loadState == _VideoLoadState.ready)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: StreamBuilder<bool>(
                  stream: _player.stream.playing,
                  initialData: false,
                  builder: (_, playSnap) {
                    final isPlaying = playSnap.data ?? false;
                    return StreamBuilder<Duration>(
                      stream: _player.stream.position,
                      initialData: Duration.zero,
                      builder: (_, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = _player.state.duration;
                        final progress = dur.inMilliseconds > 0
                            ? (pos.inMilliseconds / dur.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Center(
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: _ControlsBar(
                                  progress: progress.toDouble(),
                                  currentSec: pos.inSeconds,
                                  totalSec: dur.inSeconds,
                                  speed: _playbackSpeed,
                                  qualityLabel: _selectedQualityLabel,
                                  onFullScreen: _openFullScreen,
                                  onSpeedTap: _showSpeedPicker,
                                  onQualityTap: _qualityOptions.isNotEmpty
                                      ? _showQualityPicker
                                      : null,
                                  onSliderChanged: (v) {
                                    _player.seek(Duration(
                                        milliseconds: (v *
                                                _player.state.duration
                                                    .inMilliseconds)
                                            .round()));
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

  // ─── State overlays ──────────────────────────────────────────────────────────
  Widget _buildStateOverlay() {
    switch (_loadState) {
      case _VideoLoadState.fetchingUrl:
        return _LoadingOverlay(
          key: const ValueKey('fetchingUrl'),
          message: 'جارٍ تجهيز الفيديو...',
        );
      case _VideoLoadState.buffering:
        return _LoadingOverlay(
          key: const ValueKey('buffering'),
          message: 'جارٍ التحميل...',
        );
      case _VideoLoadState.errorOffline:
        return _ErrorOverlay(
          key: const ValueKey('offline'),
          icon: Icons.wifi_off_rounded,
          title: 'لا يوجد اتصال بالإنترنت',
          subtitle: 'تحقق من الاتصال وحاول مرة أخرى',
          onRetry: _loadVideo,
        );
      case _VideoLoadState.errorOther:
        return _ErrorOverlay(
          key: const ValueKey('error'),
          icon: Icons.play_circle_outline_rounded,
          title: 'تعذر تشغيل الفيديو',
          subtitle: 'حاول مرة أخرى',
          onRetry: _loadVideo,
        );
      case _VideoLoadState.ready:
        return const SizedBox.shrink(key: ValueKey('ready'));
    }
  }
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────
class _LoadingOverlay extends StatelessWidget {
  final String message;
  const _LoadingOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                color: _kPrimary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error Overlay ────────────────────────────────────────────────────────────
class _ErrorOverlay extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  const _ErrorOverlay({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: _kPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'إعادة المحاولة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen screen
// ─────────────────────────────────────────────────────────────────────────────
class VideoFullScreenMediaKit extends StatefulWidget {
  final String rawUrl;
  final String videoType;
  final String title;
  final Duration startAt;
  final double initialSpeed;
  final List<YoutubeQualityOption> qualityOptions;
  final String selectedQuality;

  const VideoFullScreenMediaKit({
    super.key,
    required this.rawUrl,
    required this.videoType,
    required this.title,
    required this.startAt,
    required this.initialSpeed,
    required this.qualityOptions,
    required this.selectedQuality,
  });

  @override
  State<VideoFullScreenMediaKit> createState() =>
      _VideoFullScreenMediaKitState();
}

class _VideoFullScreenMediaKitState extends State<VideoFullScreenMediaKit> {
  late final Player _player;
  late final VideoController _controller;

  _VideoLoadState _loadState = _VideoLoadState.fetchingUrl;
  bool _showControls = false;
  Timer? _hideTimer;
  double _playbackSpeed = 1.0;
  String _selectedQualityLabel = 'auto';
  SeekDirection? _seekHint;
  Timer? _seekHintTimer;

  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _playbackSpeed = widget.initialSpeed;
    _selectedQualityLabel = widget.selectedQuality;
    _player = Player();
    _controller = VideoController(_player);
    _loadAndSeek();
  }

  Future<void> _loadAndSeek() async {
    if (!mounted) return;
    setState(() => _loadState = _VideoLoadState.fetchingUrl);
    try {
      String url;
      if (widget.videoType == 'youtube') {
        final chosen = widget.qualityOptions
            .where((q) => q.label == widget.selectedQuality)
            .firstOrNull;
        if (chosen != null) {
          url = chosen.url;
          setState(() => _loadState = _VideoLoadState.buffering);
        } else {
          final result = await YoutubeService.getStreamUrl(widget.rawUrl);
          url = result.streamUrl;
          setState(() => _loadState = _VideoLoadState.buffering);
        }
      } else {
        url = widget.rawUrl;
        setState(() => _loadState = _VideoLoadState.buffering);
      }

      await _player.open(Media(url), play: true);
      await _player.seek(widget.startAt);
      await _player.setRate(_playbackSpeed);

      _player.stream.buffering.listen((buffering) {
        if (!buffering && mounted && _loadState == _VideoLoadState.buffering) {
          setState(() => _loadState = _VideoLoadState.ready);
        }
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _loadState == _VideoLoadState.buffering) {
          setState(() => _loadState = _VideoLoadState.ready);
        }
      });
    } on TimeoutException {
      if (mounted) setState(() => _loadState = _VideoLoadState.errorOffline);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') ||
          msg.contains('socket') ||
          msg.contains('network')) {
        setState(() => _loadState = _VideoLoadState.errorOffline);
      } else {
        setState(() => _loadState = _VideoLoadState.errorOther);
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekHintTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

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
    final pos = _player.state.position - const Duration(seconds: 10);
    _player.seek(pos.isNegative ? Duration.zero : pos);
    _showSeekHintAnim(SeekDirection.backward);
    _resetTimer();
  }

  void _seekForward() {
    _player.seek(_player.state.position + const Duration(seconds: 10));
    _showSeekHintAnim(SeekDirection.forward);
    _resetTimer();
  }

  void _showSeekHintAnim(SeekDirection dir) {
    setState(() => _seekHint = dir);
    _seekHintTimer?.cancel();
    _seekHintTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _seekHint = null);
    });
  }

  void _setSpeed(double s) {
    setState(() => _playbackSpeed = s);
    _player.setRate(s);
    _resetTimer();
  }

  void _showSpeedPicker() {
    _keepVisible();
    final l10n = AppLocalizations.of(context)!;
    showVideoOptionsSheet(
      context: context,
      title: l10n.playbackSpeed,
      items: _speeds.map((s) => '${s}x').toList(),
      selected: '${_playbackSpeed}x',
      onSelect: (i) => _setSpeed(_speeds[i]),
    );
  }

  void _showQualityPicker() {
    if (widget.qualityOptions.isEmpty) return;
    _keepVisible();
    final l10n = AppLocalizations.of(context)!;
    showVideoOptionsSheet(
      context: context,
      title: l10n.videoQuality,
      items: widget.qualityOptions.map((q) => q.label).toList(),
      selected: _selectedQualityLabel,
      onSelect: (i) async {
        final option = widget.qualityOptions[i];
        setState(() {
          _selectedQualityLabel = option.label;
          _loadState = _VideoLoadState.buffering;
        });
        final pos = _player.state.position;
        final wasPlaying = _player.state.playing;
        await _player.open(Media(option.url), play: false);
        await _player.seek(pos);
        if (wasPlaying) await _player.play();
        if (mounted) setState(() => _loadState = _VideoLoadState.ready);
        _resetTimer();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Video(
              controller: _controller,
              controls: NoVideoControls,
              fit: BoxFit.contain),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildOverlay(),
          ),
          if (_loadState == _VideoLoadState.ready)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(children: [
                Expanded(
                    child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _toggleControls,
                        onDoubleTap: _seekBackward)),
                Expanded(
                    child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _toggleControls,
                        onDoubleTap: _seekForward)),
              ]),
            ),
          if (_seekHint != null)
            Directionality(
              textDirection: TextDirection.ltr,
              child: SeekHintOverlay(direction: _seekHint!),
            ),
          if (_loadState == _VideoLoadState.ready)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: StreamBuilder<bool>(
                  stream: _player.stream.playing,
                  initialData: false,
                  builder: (_, playSnap) {
                    final isPlaying = playSnap.data ?? false;
                    return StreamBuilder<Duration>(
                      stream: _player.stream.position,
                      initialData: Duration.zero,
                      builder: (_, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        final dur = _player.state.duration;
                        final progress = dur.inMilliseconds > 0
                            ? (pos.inMilliseconds / dur.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;
                        return Stack(fit: StackFit.expand, children: [
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
                                  ])),
                              padding: const EdgeInsets.fromLTRB(4, 8, 16, 20),
                              child: Row(children: [
                                IconButton(
                                    icon: const Icon(Icons.arrow_back_rounded,
                                        color: Colors.white, size: 22),
                                    onPressed: () => Navigator.pop(context)),
                                Expanded(
                                    child: Text(widget.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600))),
                              ]),
                            ),
                          ),
                          Center(
                            child: GestureDetector(
                              onTap: _togglePlayPause,
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle),
                                child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 40),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: _ControlsBarFS(
                                progress: progress.toDouble(),
                                currentSec: pos.inSeconds,
                                totalSec: dur.inSeconds,
                                speed: _playbackSpeed,
                                qualityLabel: _selectedQualityLabel,
                                onExit: () => Navigator.pop(context),
                                onSpeedTap: _showSpeedPicker,
                                onQualityTap: widget.qualityOptions.isNotEmpty
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
                        ]);
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

  Widget _buildOverlay() {
    switch (_loadState) {
      case _VideoLoadState.fetchingUrl:
        return _LoadingOverlay(
            key: const ValueKey('fetchingUrl'),
            message: 'جارٍ تجهيز الفيديو...');
      case _VideoLoadState.buffering:
        return _LoadingOverlay(
            key: const ValueKey('buffering'), message: 'جارٍ التحميل...');
      case _VideoLoadState.errorOffline:
        return _ErrorOverlay(
          key: const ValueKey('offline'),
          icon: Icons.wifi_off_rounded,
          title: 'لا يوجد اتصال بالإنترنت',
          subtitle: 'تحقق من الاتصال وحاول مرة أخرى',
          onRetry: _loadAndSeek,
        );
      case _VideoLoadState.errorOther:
        return _ErrorOverlay(
          key: const ValueKey('error'),
          icon: Icons.play_circle_outline_rounded,
          title: 'تعذر تشغيل الفيديو',
          subtitle: 'حاول مرة أخرى',
          onRetry: _loadAndSeek,
        );
      case _VideoLoadState.ready:
        return const SizedBox.shrink(key: ValueKey('ready'));
    }
  }
}

// ─── Controls Bar (mini) ──────────────────────────────────────────────────────
class _ControlsBar extends StatelessWidget {
  final double progress;
  final int currentSec, totalSec;
  final double speed;
  final String qualityLabel;
  final VoidCallback onFullScreen, onSpeedTap;
  final VoidCallback? onQualityTap;
  final ValueChanged<double> onSliderChanged,
      onSliderChangeStart,
      onSliderChangeEnd;

  const _ControlsBar({
    required this.progress,
    required this.currentSec,
    required this.totalSec,
    required this.speed,
    required this.qualityLabel,
    required this.onFullScreen,
    required this.onSpeedTap,
    required this.onQualityTap,
    required this.onSliderChanged,
    required this.onSliderChangeStart,
    required this.onSliderChangeEnd,
  });

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

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
                overlayColor: Color(0x330D6EBE),
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
              onTap: onFullScreen,
              child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  child: Icon(Icons.fullscreen_rounded,
                      color: Colors.white, size: 22))),
        ]),
        const SizedBox(height: 2),
      ]),
    );
  }
}

// ─── Controls Bar (fullscreen) ────────────────────────────────────────────────
class _ControlsBarFS extends StatelessWidget {
  final double progress;
  final int currentSec, totalSec;
  final double speed;
  final String qualityLabel;
  final VoidCallback onExit, onSpeedTap;
  final VoidCallback? onQualityTap;
  final ValueChanged<double> onSliderChanged,
      onSliderChangeStart,
      onSliderChangeEnd;

  const _ControlsBarFS({
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

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent])),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
            height: 24,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 13),
                activeTrackColor: _kPrimary,
                inactiveTrackColor: Colors.white30,
                thumbColor: _kPrimary,
                overlayColor: Color(0x330D6EBE),
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
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          _ChipBtn(label: speed == 1.0 ? '1x' : '${speed}x', onTap: onSpeedTap),
          const SizedBox(width: 8),
          if (onQualityTap != null) ...[
            _ChipBtn(label: qualityLabel, onTap: onQualityTap!),
            const SizedBox(width: 14),
          ],
          GestureDetector(
              onTap: onExit,
              child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                  child: Icon(Icons.fullscreen_exit_rounded,
                      color: Colors.white, size: 26))),
        ]),
      ]),
    );
  }
}

// ─── Seek Hint ────────────────────────────────────────────────────────────────
class SeekHintOverlay extends StatelessWidget {
  final SeekDirection direction;
  const SeekHintOverlay({super.key, required this.direction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isForward = direction == SeekDirection.forward;
    return Align(
      alignment: isForward ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.horizontal(
            left: isForward ? const Radius.circular(80) : Radius.zero,
            right: !isForward ? const Radius.circular(80) : Radius.zero,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isForward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
              color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(isForward ? l10n.skipForward10 : l10n.skipBackward10,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

// ─── Options Sheet ────────────────────────────────────────────────────────────
void showVideoOptionsSheet({
  required BuildContext context,
  required String title,
  required List<String> items,
  required String selected,
  required ValueChanged<int> onSelect,
}) {
  final textDir = Directionality.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1C1C1E),
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => Directionality(
      textDirection: textDir,
      child: _OptionsSheet(
          title: title,
          items: items,
          selected: selected,
          onSelect: (i) {
            Navigator.pop(context);
            onSelect(i);
          }),
    ),
  );
}

class _OptionsSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final String selected;
  final ValueChanged<int> onSelect;

  const _OptionsSheet(
      {required this.title,
      required this.items,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 12),
      Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.white24, borderRadius: BorderRadius.circular(2))),
      const SizedBox(height: 12),
      Text(title,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Divider(color: Colors.white12, height: 1),
      ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45),
        child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.asMap().entries.map((e) {
                  final isSel = e.value == selected;
                  return ListTile(
                      dense: true,
                      title: Text(e.value,
                          style: TextStyle(
                              color: isSel ? _kPrimary : Colors.white,
                              fontWeight:
                                  isSel ? FontWeight.w700 : FontWeight.normal,
                              fontSize: 14)),
                      trailing: isSel
                          ? const Icon(Icons.check_rounded,
                              color: _kPrimary, size: 18)
                          : null,
                      onTap: () => onSelect(e.key));
                }).toList())),
      ),
      const SizedBox(height: 8),
    ]));
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
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24, width: .8)),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace'))));
  }
}
