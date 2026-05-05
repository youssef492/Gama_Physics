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

        final id = VideoId(videoId);
        final manifest = await _yt.videos.streamsClient
            .getManifest(id)
            .timeout(const Duration(seconds: 45));

        final video =
            await _yt.videos.get(id).timeout(const Duration(seconds: 30));

        debugPrint('[YoutubeService] Muxed: ${manifest.muxed.length}, '
            'Audio: ${manifest.audioOnly.length}, '
            'Video: ${manifest.videoOnly.length}, '
            'HLS: ${manifest.hls.length}');

        final allQualities = <String, YoutubeQualityOption>{};
        String bestUrl = '';
        String? bestAudioUrl;

        // استراتيجية 1: جرّب Muxed Streams أولاً
        if (manifest.muxed.isNotEmpty) {
          final muxedSorted =
              manifest.muxed.sortByVideoQuality().reversed.toList();

          for (var stream in muxedSorted) {
            final height = stream.videoResolution.height;
            final label = '${height}p';

            if (!allQualities.containsKey(label)) {
              allQualities[label] = YoutubeQualityOption(
                label: label,
                url: stream.url.toString(),
              );
            }
          }

          if (bestUrl.isEmpty && muxedSorted.isNotEmpty) {
            bestUrl = muxedSorted.first.url.toString();
          }
        }

        // استراتيجية 2: جرّب Video Only + Audio Only
        if (manifest.videoOnly.isNotEmpty && manifest.audioOnly.isNotEmpty) {
          final audioStreams = manifest.audioOnly.sortByBitrate().toList();
          final bestAudio = audioStreams.isNotEmpty ? audioStreams.last : null;
          bestAudioUrl = bestAudio?.url.toString();

          final videoSorted =
              manifest.videoOnly.sortByVideoQuality().reversed.toList();

          for (var stream in videoSorted) {
            final height = stream.videoResolution.height;
            final label = '${height}p';

            if (!allQualities.containsKey(label)) {
              allQualities[label] = YoutubeQualityOption(
                label: label,
                url: stream.url.toString(),
                audioUrl: bestAudioUrl,
              );
            }
          }

          if (bestUrl.isEmpty && videoSorted.isNotEmpty) {
            bestUrl = videoSorted.first.url.toString();
          }
        }

        // استراتيجية 3: جرّب HLS
        if (manifest.hls.isNotEmpty) {
          final hlsList = manifest.hls.toList();

          for (int i = 0; i < hlsList.length; i++) {
            final stream = hlsList[i];
            final streamStr = stream.toString();
            final height = _extractHeightFromHls(streamStr);

            if (height > 0) {
              final label = '${height}p';

              if (!allQualities.containsKey(label)) {
                allQualities[label] = YoutubeQualityOption(
                  label: label,
                  url: stream.url.toString(),
                );
              }
            }
          }

          if (bestUrl.isEmpty && hlsList.isNotEmpty) {
            bestUrl = hlsList.first.url.toString();
          }
        }

        // إذا لم نجد شيء
        if (bestUrl.isEmpty) {
          bestUrl = manifest.muxed.isNotEmpty
              ? manifest.muxed.first.url.toString()
              : '';

          if (bestUrl.isEmpty) {
            throw Exception('No available streams');
          }
        }

        // ترتيب الجودات من الأعلى للأقل
        final sortedQualities = allQualities.values.toList();
        sortedQualities.sort((a, b) {
          final aHeight = int.tryParse(a.label.replaceAll('p', '')) ?? 0;
          final bHeight = int.tryParse(b.label.replaceAll('p', '')) ?? 0;
          return bHeight.compareTo(aHeight);
        });

        debugPrint(
            '[YoutubeService] Found ${sortedQualities.length} qualities');

        final result = YoutubeStreamResult(
          streamUrl: bestUrl,
          title: video.title,
          duration: video.duration ?? Duration.zero,
          availableQualities: sortedQualities.map((q) => q.label).toList(),
          allStreams: sortedQualities.isNotEmpty
              ? sortedQualities
              : [YoutubeQualityOption(label: '360p', url: bestUrl)],
        );

        _cache[videoId] =
            _CachedStream(result: result, cachedAt: DateTime.now());

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

  static int _extractHeightFromHls(String hlsString) {
    // محاولة 1: البحث عن صيغة "1080p"
    RegExp regex1 = RegExp(r'(\d+)p');
    Match? match1 = regex1.firstMatch(hlsString);
    if (match1 != null) {
      final height = int.tryParse(match1.group(1) ?? '');
      if (height != null && height > 0) {
        return height;
      }
    }

    // محاولة 2: البحث عن صيغة "1080x720"
    RegExp regex2 = RegExp(r'(\d+)x(\d+)');
    Match? match2 = regex2.firstMatch(hlsString);
    if (match2 != null) {
      final height = int.tryParse(match2.group(2) ?? '');
      if (height != null && height > 0) {
        return height;
      }
    }

    // محاولة 3: البحث عن "height=1080"
    RegExp regex3 = RegExp(r'height=(\d+)');
    Match? match3 = regex3.firstMatch(hlsString);
    if (match3 != null) {
      final height = int.tryParse(match3.group(1) ?? '');
      if (height != null && height > 0) {
        return height;
      }
    }

    return 0;
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
    for (var key in expired) {
      _cache.remove(key);
    }

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

class _CachedStream {
  final YoutubeStreamResult result;
  final DateTime cachedAt;
  static const Duration _ttl = Duration(hours: 3);

  _CachedStream({required this.result, required this.cachedAt});

  bool get isExpired => DateTime.now().difference(cachedAt) > _ttl;
}

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
