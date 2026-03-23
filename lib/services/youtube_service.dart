import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  static final YoutubeExplode _yt = YoutubeExplode();

  // ─── Cache: videoId → result (عمرها 3 ساعات) ──────────────────────────────
  static final Map<String, _CachedStream> _cache = {};
  static const int _maxCacheSize = 50; // ✅ حد أقصى للعناصر

  /// ✅ تحسين: timeout أطول + retry mechanism
  static Future<YoutubeStreamResult> getStreamUrl(
    String rawUrl, {
    int retryCount = 2,
  }) async {
    final videoId = extractVideoId(rawUrl);

    // تنظيف الـ cache القديمة
    _cleanupCache();

    // لو موجودة في الـ cache وغير منتهية → ارجعها على طول
    final cached = _cache[videoId];
    if (cached != null && !cached.isExpired) {
      debugPrint('[YoutubeService] Cache hit for: $videoId');
      return cached.result;
    }

    // ✅ محاولة مع retry
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        debugPrint(
            '[YoutubeService] Fetching stream (attempt ${attempt + 1}/$retryCount): $videoId');

        final id = VideoId(rawUrl);

        // ✅ timeout أطول (45 ثانية للـ manifest)
        final manifest = await _yt.videos.streamsClient
            .getManifest(id)
            .timeout(const Duration(seconds: 45));

        // ✅ timeout أطول للـ video info (30 ثانية)
        final video =
            await _yt.videos.get(id).timeout(const Duration(seconds: 30));

        final muxedStreams = manifest.muxed.sortByVideoQuality();
        if (muxedStreams.isEmpty) {
          throw Exception('No streams available');
        }

        final result = YoutubeStreamResult(
          streamUrl: muxedStreams.first.url.toString(),
          title: video.title,
          duration: video.duration ?? Duration.zero,
          availableQualities: muxedStreams
              .map((s) =>
                  s.videoQuality.toString().replaceAll('videoQuality', ''))
              .toList(),
          allStreams: muxedStreams
              .map((s) => YoutubeQualityOption(
                    label: '${s.videoResolution.height}p',
                    url: s.url.toString(),
                  ))
              .toList(),
        );

        // نحفظها في الـ cache
        _cache[videoId] =
            _CachedStream(result: result, cachedAt: DateTime.now());
        debugPrint('[YoutubeService] Successfully cached: $videoId');
        return result;
      } on TimeoutException catch (e) {
        debugPrint('[YoutubeService] Timeout on attempt ${attempt + 1}: $e');

        // لو آخر محاولة → نشوف الـ cache القديمة
        if (attempt == retryCount) {
          if (cached != null) {
            debugPrint('[YoutubeService] Using expired cache for: $videoId');
            return cached.result;
          }
          throw Exception('slow_connection');
        }

        // ✅ انتظر شوية قبل إعادة المحاولة
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      } catch (e) {
        debugPrint('[YoutubeService] Error on attempt ${attempt + 1}: $e');

        // لو آخر محاولة
        if (attempt == retryCount) {
          // لو في الـ cache حتى لو منتهية → أحسن من لا شيء
          if (cached != null) {
            debugPrint(
                '[YoutubeService] Using expired cache as fallback: $videoId');
            return cached.result;
          }
          rethrow;
        }

        // انتظر قبل إعادة المحاولة
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }

    throw Exception('Max retries exceeded');
  }

  // ✅ استخرج الـ videoId من الـ URL عشان نستخدمه كـ cache key
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

  // ✅ تنظيف الـ cache من العناصر القديمة
  static void _cleanupCache() {
    if (_cache.length < _maxCacheSize) return;

    // احذف العناصر المنتهية
    final expired =
        _cache.entries.where((e) => e.value.isExpired).map((e) => e.key);

    for (var key in expired) {
      _cache.remove(key);
      debugPrint('[YoutubeService] Removed expired cache: $key');
    }

    // لو لسه الـ cache كبير، احذف الأقدم
    if (_cache.length >= _maxCacheSize) {
      final sorted = _cache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

      final toRemove = sorted.take(_cache.length - _maxCacheSize + 10);
      for (var entry in toRemove) {
        _cache.remove(entry.key);
        debugPrint('[YoutubeService] Removed old cache: ${entry.key}');
      }
    }
  }

  static void clearCache() {
    _cache.clear();
    debugPrint('[YoutubeService] Cache cleared');
  }

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
  YoutubeQualityOption({required this.label, required this.url});
}
