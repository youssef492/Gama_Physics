import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:gama/services/video_view_service.dart';
import 'package:gama/services/youtube_service.dart';
import 'package:gama/services/google_drive_service.dart';
export 'package:gama/services/youtube_service.dart' show YoutubeQualityOption;

enum SeekDirection { forward, backward }

enum _VideoLoadState {
  fetchingUrl,
  buffering,
  ready,
  errorSlow,
  errorOffline,
  errorOther
}

const _kPrimary = Color(0xFF0D6EBE);

// ─── Register fvp once at app startup (ضعها في main.dart قبل runApp) ─────────
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   fvp.registerWith();          // ← السطر ده بس
//   runApp(const MyApp());
// }
// ─────────────────────────────────────────────────────────────────────────────

class VideoPlayerWidget extends StatefulWidget {
  final String embedUrl;
  final String title;
  final String videoType;
  final String rawVideoUrl;

  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  // بيانات المشاهدة — اختيارية (مش موجودة في شاشة المدرس)
  final String lessonId;
  final String studentId;
  final String studentName;
  final String studentPhone;
  final String studentGrade;

  const VideoPlayerWidget({
    super.key,
    required this.embedUrl,
    required this.title,
    required this.videoType,
    required this.rawVideoUrl,
    this.lessonId = '',
    this.studentId = '',
    this.studentName = '',
    this.studentPhone = '',
    this.studentGrade = '',
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;

  _VideoLoadState _loadState = _VideoLoadState.fetchingUrl;
  bool _showControls = false;
  Timer? _hideTimer;
  double _playbackSpeed = 1.0;
  SeekDirection? _seekHint;
  Timer? _seekHintTimer;
  List<YoutubeQualityOption> _qualityOptions = [];
  String _selectedQualityLabel = 'auto';

  bool _viewRecorded = false;

  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekHintTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ─── Load ─────────────────────────────────────────────────────────────────
  Future<void> _loadVideo({
    String? overrideUrl,
    String? overrideQuality,
    bool autoPlay = true,
  }) async {
    if (!mounted) return;

    final old = _controller;
    _controller = null;
    await old?.dispose();

    setState(() => _loadState = _VideoLoadState.fetchingUrl);

    try {
      String url;

      if (overrideUrl != null) {
        url = overrideUrl;
        if (overrideQuality != null) _selectedQualityLabel = overrideQuality;
      } else if (widget.videoType == 'youtube') {
        final result = await YoutubeService.getStreamUrl(
          widget.rawVideoUrl,
          retryCount: 2,
        );
        _qualityOptions = result.allStreams;
        if (_qualityOptions.isNotEmpty) {
          _selectedQualityLabel = _qualityOptions.first.label;
        }
        url = result.streamUrl;
      } else if (widget.videoType == 'google_drive' ||
          widget.videoType == 'drive') {
        url = await GoogleDriveService.getDirectStreamUrl(widget.embedUrl);
      } else {
        url = widget.embedUrl;
      }

      if (!mounted) return;
      setState(() => _loadState = _VideoLoadState.buffering);

      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = ctrl;

      // ←←← التعديل هنا
      await ctrl.initialize();
      if (!mounted) return;

      await ctrl.setPlaybackSpeed(_playbackSpeed);

      ctrl.addListener(_onPlayingChanged);

      if (autoPlay) {
        await ctrl.play();
      }

      setState(() => _loadState = _VideoLoadState.ready);
    } on TimeoutException {
      if (mounted) setState(() => _loadState = _VideoLoadState.errorSlow);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('slow_connection')) {
        setState(() => _loadState = _VideoLoadState.errorSlow);
      } else if (msg.contains('socket') ||
          msg.contains('network') ||
          msg.contains('connection')) {
        setState(() => _loadState = _VideoLoadState.errorOffline);
      } else {
        debugPrint('[VideoPlayer] Load error: $e');
        setState(() => _loadState = _VideoLoadState.errorOther);
      }
    }
  }

  void _onPlayingChanged() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (ctrl.value.isPlaying) _recordViewOnce();
  }

  void _recordViewOnce() {
    if (_viewRecorded) return;
    if (widget.lessonId.isEmpty || widget.studentId.isEmpty) return;
    _viewRecorded = true;
    VideoViewService.recordView(
      lessonId: widget.lessonId,
      studentId: widget.studentId,
      studentName: widget.studentName,
      studentPhone: widget.studentPhone,
      studentGrade: widget.studentGrade,
    );
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
    final ctrl = _controller;
    if (ctrl == null) return;
    ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
    _resetTimer();
  }

  void _seekBackward() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final pos = ctrl.value.position - const Duration(seconds: 10);
    ctrl.seekTo(pos.isNegative ? Duration.zero : pos);
    _showSeekHintAnim(SeekDirection.backward);
    _resetTimer();
  }

  void _seekForward() {
    final ctrl = _controller;
    if (ctrl == null) return;
    ctrl.seekTo(ctrl.value.position + const Duration(seconds: 10));
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
    _controller?.setPlaybackSpeed(s);
    _resetTimer();
  }

  Future<void> _setQuality(YoutubeQualityOption option) async {
    final ctrl = _controller;
    if (ctrl == null) return;

    final pos = ctrl.value.position;
    final wasPlaying = ctrl.value.isPlaying;

    setState(() {
      _selectedQualityLabel = option.label;
      _loadState = _VideoLoadState.buffering;
    });

    try {
      // جلب URL جديد بالجودة المطلوبة
      final result = await YoutubeService.getStreamUrl(
        widget.rawVideoUrl,
        retryCount: 1,
        forceRefresh: true,
      );
      final chosen =
          result.allStreams.where((q) => q.label == option.label).firstOrNull;
      final url = chosen?.url ?? option.url;

      setState(() => _qualityOptions = result.allStreams);

      // reload بالـ URL الجديد
      await _loadVideo(
        overrideUrl: url,
        overrideQuality: option.label,
        autoPlay: false,
      );

      // رجع للموضع القديم
      await _controller?.seekTo(pos);
      if (wasPlaying) await _controller?.play();
    } catch (_) {
      await _loadVideo(
        overrideUrl: option.url,
        overrideQuality: option.label,
        autoPlay: false,
      );
      await _controller?.seekTo(pos);
      if (wasPlaying) await _controller?.play();
    }
  }

  Future<void> _openFullScreen() async {
    final ctrl = _controller;
    if (ctrl == null) return;

    final pos = ctrl.value.position;
    await ctrl.pause();
    setState(() => _showControls = false);
    _hideTimer?.cancel();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoFullScreenFvp(
          controller: ctrl,
          title: widget.title,
          startAt: pos,
          initialSpeed: _playbackSpeed,
          selectedQualityLabel: _selectedQualityLabel,
          qualityOptions: _qualityOptions,
          isYoutube: widget.videoType == 'youtube',
          rawVideoUrl: widget.rawVideoUrl,
          onQualityChanged: (option) => _setQuality(option),
        ),
      ),
    );
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

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // ─── Video ───────────────────────────────────────────────────
            if (_loadState == _VideoLoadState.ready && _controller != null)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),

            // ─── Loading / Error overlay ──────────────────────────────────
            _buildOverlay(),

            // ─── Seek zones (double-tap) ──────────────────────────────────
            if (_loadState == _VideoLoadState.ready)
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

            // ─── Seek hint ────────────────────────────────────────────────
            if (_seekHint != null)
              Directionality(
                textDirection: TextDirection.ltr,
                child: SeekHintOverlay(direction: _seekHint!),
              ),

            // ─── Controls overlay ─────────────────────────────────────────
            if (_loadState == _VideoLoadState.ready && _controller != null)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _controller!,
                    builder: (_, value, __) {
                      final isPlaying = value.isPlaying;
                      final pos = value.position;
                      final dur = value.duration;
                      final progress = dur.inMilliseconds > 0
                          ? (pos.inMilliseconds / dur.inMilliseconds)
                              .clamp(0.0, 1.0)
                          : 0.0;

                      return Stack(fit: StackFit.expand, children: [
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
                              onQualityTap: widget.videoType == 'youtube' &&
                                      _qualityOptions.isNotEmpty
                                  ? _showQualityPicker
                                  : null,
                              onSliderChanged: (v) {
                                _controller?.seekTo(Duration(
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
      ),
    );
  }

  Widget _buildOverlay() {
    final l10n = AppLocalizations.of(context)!;
    switch (_loadState) {
      case _VideoLoadState.fetchingUrl:
        return _LoadingOverlay(
            key: const ValueKey('fetch'), message: l10n.preparingVideo);
      case _VideoLoadState.buffering:
        return _LoadingOverlay(
          key: const ValueKey('buffer'),
          message: l10n.loading,
          controller: _controller,
        );
      case _VideoLoadState.errorSlow:
        return _ErrorOverlay(
            key: const ValueKey('slow'),
            icon: Icons.signal_cellular_alt_rounded,
            title: l10n.slowNetwork,
            subtitle: l10n.slowNetworkDesc,
            onRetry: _loadVideo);
      case _VideoLoadState.errorOffline:
        return _ErrorOverlay(
            key: const ValueKey('offline'),
            icon: Icons.wifi_off_rounded,
            title: l10n.noInternet,
            subtitle: l10n.noInternetDesc,
            onRetry: _loadVideo);
      case _VideoLoadState.errorOther:
        return _ErrorOverlay(
            key: const ValueKey('error'),
            icon: Icons.play_circle_outline_rounded,
            title: l10n.cannotPlayVideo,
            subtitle: l10n.cannotPlayVideoDesc,
            onRetry: _loadVideo);
      case _VideoLoadState.ready:
        return const SizedBox.shrink(key: ValueKey('ready'));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen Screen (fvp version — بيشارك نفس الـ controller)
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
        setState(() => _selectedQualityLabel = option.label);
        await widget.onQualityChanged(option);
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
          // ─── Video ───────────────────────────────────────────────────────
          FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _ctrl.value.size.width,
              height: _ctrl.value.size.height,
              child: VideoPlayer(_ctrl),
            ),
          ),

          // ─── Seek zones ───────────────────────────────────────────────────
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

          // ─── Seek hint ────────────────────────────────────────────────────
          if (_seekHint != null)
            Directionality(
              textDirection: TextDirection.ltr,
              child: SeekHintOverlay(direction: _seekHint!),
            ),

          // ─── Controls ─────────────────────────────────────────────────────
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
                    // Top bar
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

                    // Play/Pause center
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

                    // Bottom bar
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
                          onQualityTap: widget.isYoutube &&
                                  widget.qualityOptions.isNotEmpty
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

// ─── Controls Bar ─────────────────────────────────────────────────────────────
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
              onChangeEnd: onSliderChangeEnd,
            ),
          ),
        ),
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
              child:
                  Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
            ),
          ),
        ]),
        const SizedBox(height: 2),
      ]),
    );
  }
}

// ─── VLC Bar Fullscreen ───────────────────────────────────────────────────────
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
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '00')}';
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
              onChangeEnd: onSliderChangeEnd,
            ),
          ),
        ),
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
                  color: Colors.white, size: 22),
            ),
          ),
        ]),
        const SizedBox(height: 2),
      ]),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final String message;
  final VideoPlayerController? controller;

  const _LoadingOverlay({
    super.key,
    required this.message,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error Overlay ────────────────────────────────────────────────────────────
class _ErrorOverlay extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onRetry;
  const _ErrorOverlay(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white60, size: 56),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: Text(l10n.retry),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        ),
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
          Icon(
            isForward ? Icons.forward_10_rounded : Icons.replay_10_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            isForward ? l10n.skipForward10 : l10n.skipBackward10,
            style: const TextStyle(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
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
                fontFamily: 'monospace')),
      ),
    );
  }
}
