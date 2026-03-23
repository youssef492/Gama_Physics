import 'dart:async';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  static final YoutubeExplode _yt = YoutubeExplode();

  // ─── Cache: videoId → result (عمرها 3 ساعات) ──────────────────────────────
  static final Map<String, _CachedStream> _cache = {};

  static Future<YoutubeStreamResult> getStreamUrl(String rawUrl) async {
    final videoId = _extractId(rawUrl);

    // لو موجودة في الـ cache وغير منتهية → ارجعها على طول
    final cached = _cache[videoId];
    if (cached != null && !cached.isExpired) {
      return cached.result;
    }

    try {
      final id = VideoId(rawUrl);
      final manifest = await _yt.videos.streamsClient
          .getManifest(id)
          .timeout(const Duration(seconds: 15));
      final video =
          await _yt.videos.get(id).timeout(const Duration(seconds: 10));

      final muxedStreams = manifest.muxed.sortByVideoQuality();
      if (muxedStreams.isEmpty) throw Exception('No streams available');

      final result = YoutubeStreamResult(
        streamUrl: muxedStreams.first.url.toString(),
        title: video.title,
        duration: video.duration ?? Duration.zero,
        availableQualities: muxedStreams
            .map(
                (s) => s.videoQuality.toString().replaceAll('videoQuality', ''))
            .toList(),
        allStreams: muxedStreams
            .map((s) => YoutubeQualityOption(
                  label: '${s.videoResolution.height}p',
                  url: s.url.toString(),
                ))
            .toList(),
      );

      // نحفظها في الـ cache
      _cache[videoId] = _CachedStream(result: result, cachedAt: DateTime.now());
      return result;
    } on TimeoutException {
      throw Exception('timeout');
    } catch (e) {
      // لو في الـ cache حتى لو منتهية → أحسن من لا شيء
      if (cached != null) return cached.result;
      rethrow;
    }
  }

  // استخرج الـ videoId من الـ URL عشان نستخدمه كـ cache key
  static String _extractId(String rawUrl) {
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
  YoutubeQualityOption({required this.label, required this.url});
}
