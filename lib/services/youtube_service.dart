import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  static final YoutubeExplode _yt = YoutubeExplode();

  static final Map<String, _CachedStream> _cache = {};
  static const int _maxCacheSize = 50;

  static Future<YoutubeStreamResult> getStreamUrl(
    String rawUrl, {
    int retryCount = 2,
    bool forceRefresh = false,
  }) async {
    final videoId = extractVideoId(rawUrl);
    _cleanupCache();

    final cached = _cache[videoId];
    if (!forceRefresh && cached != null && !cached.isExpired) {
      debugPrint('[YoutubeService] Cache hit: $videoId');
      return cached.result;
    }

    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        debugPrint(
            '[YoutubeService] Fetching (attempt ${attempt + 1}): $videoId');

        final id = VideoId(rawUrl);

        final manifest = await _yt.videos.streamsClient
            .getManifest(id)
            .timeout(const Duration(seconds: 45));

        final video =
            await _yt.videos.get(id).timeout(const Duration(seconds: 30));

        // ─── Best audio stream ─────────────────────────────────────────────
        final audioStreams = manifest.audioOnly.sortByBitrate().toList();
        final bestAudio = audioStreams.isNotEmpty ? audioStreams.last : null;
        final audioUrl = bestAudio?.url.toString();

        // ─── HLS streams ───────────────────────────────────────────────────
        // HlsStreamInfo.toString() →  "[HLS] Video-only (230 | 640x360p25 | m3u8)"
        // نعمل filter للـ video-only وbparse الـ height من الـ string
        final hlsAll = manifest.hls.toList();
        debugPrint('[YoutubeService] All HLS: $hlsAll');

        final uniqueQualities = <String, YoutubeQualityOption>{};

        for (final s in hlsAll) {
          final str = s.toString();

          // تخطى الـ audio-only streams
          if (str.contains('Audio-only')) continue;

          // ✅ استخرج الـ height من pattern زي "640x360p25" أو "1280x720p30"
          final match = RegExp(r'\d+x(\d+)p').firstMatch(str);
          if (match == null) continue;

          final height = match.group(1)!;
          final label = '${height}p';

          if (!uniqueQualities.containsKey(label)) {
            uniqueQualities[label] = YoutubeQualityOption(
              label: label,
              url: s.url.toString(),
              audioUrl: audioUrl,
            );
            debugPrint('[YoutubeService] Found HLS quality: $label');
          }
        }

        List<YoutubeQualityOption> allStreamsList = [];
        String bestUrl;

        if (uniqueQualities.isNotEmpty) {
          // رتب تنازلياً (الأعلى جودة أول)
          allStreamsList = uniqueQualities.values.toList()
            ..sort((a, b) {
              final aH = int.tryParse(a.label.replaceAll('p', '')) ?? 0;
              final bH = int.tryParse(b.label.replaceAll('p', '')) ?? 0;
              return bH.compareTo(aH);
            });

          bestUrl = allStreamsList.first.url;
          debugPrint(
              '[YoutubeService] HLS qualities: ${allStreamsList.map((q) => q.label).toList()}');
        } else {
          // ─── Muxed fallback (360p) ─────────────────────────────────────
          debugPrint('[YoutubeService] No HLS video → muxed fallback');
          final muxedStreams =
              manifest.muxed.sortByVideoQuality().reversed.toList();

          if (muxedStreams.isEmpty) throw Exception('No streams available');

          for (var s in muxedStreams) {
            final label = '${s.videoResolution.height}p';
            if (!uniqueQualities.containsKey(label)) {
              uniqueQualities[label] =
                  YoutubeQualityOption(label: label, url: s.url.toString());
            }
          }
          allStreamsList = uniqueQualities.values.toList();
          bestUrl = muxedStreams.first.url.toString();
        }

        final result = YoutubeStreamResult(
          streamUrl: bestUrl,
          title: video.title,
          duration: video.duration ?? Duration.zero,
          availableQualities: allStreamsList.map((q) => q.label).toList(),
          allStreams: allStreamsList,
        );

        _cache[videoId] =
            _CachedStream(result: result, cachedAt: DateTime.now());
        debugPrint(
            '[YoutubeService] Done. Qualities: ${result.availableQualities}');
        return result;
      } on TimeoutException catch (e) {
        debugPrint('[YoutubeService] Timeout attempt ${attempt + 1}: $e');
        if (attempt == retryCount) {
          if (cached != null) return cached.result;
          throw Exception('slow_connection');
        }
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } catch (e) {
        debugPrint('[YoutubeService] Error attempt ${attempt + 1}: $e');
        if (attempt == retryCount) {
          if (cached != null) return cached.result;
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
    throw Exception('Max retries exceeded');
  }

  static String extractVideoId(String rawUrl) {
    try {
      final uri = Uri.tryParse(rawUrl);
      if (uri == null) return rawUrl;
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : rawUrl;
      }
      return uri.queryParameters['v'] ?? rawUrl;
    } catch (_) {
      return rawUrl;
    }
  }

  static void _cleanupCache() {
    if (_cache.length < _maxCacheSize) return;
    final expired = _cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();
    for (var key in expired) _cache.remove(key);
    if (_cache.length >= _maxCacheSize) {
      final sorted = _cache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
      for (var entry in sorted.take(_cache.length - _maxCacheSize + 10)) {
        _cache.remove(entry.key);
      }
    }
  }

  static void clearCache() => _cache.clear();
  static void dispose() => _yt.close();
}

// ─── Cache entry ──────────────────────────────────────────────────────────────
class _CachedStream {
  final YoutubeStreamResult result;
  final DateTime cachedAt;
  static const Duration _ttl = Duration(hours: 3);
  _CachedStream({required this.result, required this.cachedAt});
  bool get isExpired => DateTime.now().difference(cachedAt) > _ttl;
}

// ─── DTOs ─────────────────────────────────────────────────────────────────────
class YoutubeStreamResult {
  final String streamUrl;
  final String title;
  final Duration duration;
  final List<String> availableQualities;
  final List<YoutubeQualityOption> allStreams;

  YoutubeStreamResult({
    required this.streamUrl,
    required this.title,
    required this.duration,
    required this.availableQualities,
    required this.allStreams,
  });
}

class YoutubeQualityOption {
  final String label;
  final String url;
  final String? audioUrl;

  YoutubeQualityOption({
    required this.label,
    required this.url,
    this.audioUrl,
  });
}
