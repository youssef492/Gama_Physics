import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class GoogleDriveService {
  static final Map<String, _CachedUrl> _cache = {};

  static String? extractFileId(String url) {
    debugPrint('[DriveService] ← Input URL: $url');
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        debugPrint('[DriveService] ✗ Uri.tryParse failed');
        return null;
      }

      debugPrint('[DriveService] Uri segments: ${uri.pathSegments}');
      debugPrint('[DriveService] Uri queryParams: ${uri.queryParameters}');

      final segments = uri.pathSegments;
      final dIndex = segments.indexOf('d');
      if (dIndex != -1 && dIndex + 1 < segments.length) {
        final id = segments[dIndex + 1];
        debugPrint('[DriveService] ✓ FILE_ID from path: $id');
        return id;
      }

      final idFromQuery = uri.queryParameters['id'];
      if (idFromQuery != null) {
        debugPrint('[DriveService] ✓ FILE_ID from query: $idFromQuery');
        return idFromQuery;
      }

      debugPrint('[DriveService] ✗ Could not extract FILE_ID');
      return null;
    } catch (e) {
      debugPrint('[DriveService] ✗ extractFileId error: $e');
      return null;
    }
  }

  static Future<String> getDirectStreamUrl(String embedOrFileUrl) async {
    debugPrint('[DriveService] ══════════════════════════════');
    debugPrint('[DriveService] getDirectStreamUrl called');
    debugPrint('[DriveService] Input: $embedOrFileUrl');

    final fileId = extractFileId(embedOrFileUrl);
    if (fileId == null) {
      debugPrint('[DriveService] ✗ fileId is null → throwing exception');
      throw Exception('Invalid Google Drive URL');
    }

    debugPrint('[DriveService] FILE_ID = $fileId');

    // تحقق من الـ cache
    final cached = _cache[fileId];
    if (cached != null && !cached.isExpired) {
      debugPrint('[DriveService] ✓ Cache hit → ${cached.url}');
      return cached.url;
    }
    debugPrint('[DriveService] Cache miss → building URL');

    final url =
        'https://drive.google.com/uc?export=download&id=$fileId&confirm=t&authuser=0';

    debugPrint('[DriveService] ✓ Final URL: $url');

    // تحقق إن الـ URL بيرد
    await _pingUrl(url);

    _cache[fileId] = _CachedUrl(url: url, cachedAt: DateTime.now());
    return url;
  }

  /// بيعمل HEAD request بس عشان نشوف الـ status code
  static Future<void> _pingUrl(String url) async {
    debugPrint('[DriveService] Pinging URL...');
    final client = HttpClient();
    try {
      final req = await client
          .headUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      req.headers.set('User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
      final res = await req.close().timeout(const Duration(seconds: 10));
      debugPrint('[DriveService] Ping status: ${res.statusCode}');
      debugPrint(
          '[DriveService] Content-Type: ${res.headers.value('content-type')}');
      debugPrint(
          '[DriveService] Content-Length: ${res.headers.value('content-length')}');
      final location = res.headers.value(HttpHeaders.locationHeader);
      if (location != null) {
        debugPrint('[DriveService] Redirect → $location');
      }
      res.drain();
    } catch (e) {
      debugPrint('[DriveService] ✗ Ping error: $e');
    } finally {
      client.close();
    }
  }

  static void clearCache() => _cache.clear();
}

class _CachedUrl {
  final String url;
  final DateTime cachedAt;
  static const Duration _ttl = Duration(hours: 1);
  _CachedUrl({required this.url, required this.cachedAt});
  bool get isExpired => DateTime.now().difference(cachedAt) > _ttl;
}
