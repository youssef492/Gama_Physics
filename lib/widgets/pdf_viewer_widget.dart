import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gama/l10n/app_localizations.dart';
import 'package:gama/config/theme.dart';

class PdfViewerWidget extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerWidget({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;
  late final List<String> _candidateViewerUrls;
  int _currentViewerIndex = 0;
  bool _useExternalBrowser = false;
  String? _externalUri;

  /// `webview_flutter` supports Android, iOS, and macOS — not Windows/Linux desktop.
  static bool _needsExternalPdfViewer() =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  @override
  void initState() {
    super.initState();
    if (_needsExternalPdfViewer()) {
      _initExternalPdf();
    } else {
      _initializeWebView();
    }
  }

  void _initExternalPdf() {
    final fileId = _extractFileId(widget.pdfUrl);
    if (fileId == null) {
      _error = 'Invalid PDF URL - Could not extract file ID';
      return;
    }
    _externalUri =
        'https://drive.google.com/file/d/$fileId/preview?rm=minimal';
    _useExternalBrowser = true;
    _isLoading = false;
  }

  Future<void> _openExternalPdf() async {
    final uri = _externalUri;
    if (uri == null) return;
    final parsed = Uri.parse(uri);
    if (await canLaunchUrl(parsed)) {
      await launchUrl(parsed, mode: LaunchMode.externalApplication);
    }
  }

  void _initializeWebView() {
    debugPrint('═════════════════════════════════════════');
    debugPrint('[PDF VIEWER] Starting initialization');
    debugPrint('[PDF VIEWER] Input URL: ${widget.pdfUrl}');

    // Extract file ID from Google Drive URL
    final fileId = _extractFileId(widget.pdfUrl);

    debugPrint('[PDF VIEWER] Extracted File ID: $fileId');
    debugPrint('[PDF VIEWER] File ID Length: ${fileId?.length}');

    if (fileId == null) {
      debugPrint('[PDF VIEWER] ❌ FILE ID IS NULL - Setting error state');
      setState(() => _error = 'Invalid PDF URL - Could not extract file ID');
      return;
    }

    // Prefer Drive preview in minimal mode to reduce top actions like sign-in/print.
    final previewMinimalUrl = 'https://drive.google.com/file/d/$fileId/preview?rm=minimal';
    final previewUrl = 'https://drive.google.com/file/d/$fileId/preview';
    final directUrl = 'https://drive.google.com/uc?export=download&id=$fileId';
    _candidateViewerUrls = [previewMinimalUrl, previewUrl, directUrl];

    debugPrint('[PDF VIEWER] Candidate URLs: $_candidateViewerUrls');
    debugPrint(
        '[PDF VIEWER] ✅ Creating WebViewController with enhanced settings');

    _controller = WebViewController()
      // Allow JavaScript
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // Set user agent to bypass some restrictions
      ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[PDF VIEWER] 📄 Page started loading: $url');
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            debugPrint('[PDF VIEWER] ✅ Page finished loading: $url');
            setState(() => _isLoading = false);
            _hideDriveToolbar();
          },
          onWebResourceError: (error) {
            debugPrint('[PDF VIEWER] ❌ WebView error: ${error.description}');
            debugPrint('[PDF VIEWER] Error code: ${error.errorCode}');
            debugPrint('[PDF VIEWER] Error details: $error');
            _tryNextViewerUrl(
              reason: '${error.description}\n\nCode: ${error.errorCode}',
            );
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('[PDF VIEWER] 🔗 Navigation request: $url');

            // Allow Google domains required for Drive/GView rendering.
            final allowedHosts = [
              'drive.google.com',
              'docs.google.com',
              'accounts.google.com',
              'googleusercontent.com',
            ];
            final host = Uri.tryParse(url)?.host ?? '';
            final isAllowed =
                allowedHosts.any((allowed) => host == allowed || host.endsWith('.$allowed'));

            if (isAllowed) {
              debugPrint('[PDF VIEWER] ✅ Navigation allowed');
              return NavigationDecision.navigate;
            }

            debugPrint('[PDF VIEWER] ❌ Navigation blocked for: $url');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_candidateViewerUrls.first));

    debugPrint('[PDF VIEWER] ✅ loadRequest called with first candidate URL');
    debugPrint('═════════════════════════════════════════');
  }

  void _tryNextViewerUrl({required String reason}) {
    if (_currentViewerIndex < _candidateViewerUrls.length - 1) {
      _currentViewerIndex += 1;
      final nextUrl = _candidateViewerUrls[_currentViewerIndex];
      debugPrint('[PDF VIEWER] ↪ Trying fallback URL: $nextUrl');
      setState(() {
        _isLoading = true;
      });
      _controller?.loadRequest(Uri.parse(nextUrl));
      return;
    }

    setState(() => _error = reason);
  }

  Future<void> _hideDriveToolbar() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      // Best-effort CSS/JS cleanup for Google viewer chrome.
      await controller.runJavaScript('''
        (function() {
          const selectors = [
            '[aria-label*="Sign in"]',
            '[aria-label*="Print"]',
            'a[href*="ServiceLogin"]',
            'button[aria-label*="Sign in"]',
            'button[aria-label*="Print"]',
            '.ndfHFb-c4YZDc-Wrql6b',
            '.ndfHFb-c4YZDc-aTv5jf',
            '.ndfHFb-c4YZDc-r4nke',
            '[role="toolbar"]'
          ];
          selectors.forEach((selector) => {
            document.querySelectorAll(selector).forEach((el) => {
              el.style.setProperty('display', 'none', 'important');
              el.style.setProperty('visibility', 'hidden', 'important');
              el.style.setProperty('opacity', '0', 'important');
              el.style.setProperty('pointer-events', 'none', 'important');
            });
          });
        })();
      ''');
    } catch (e) {
      debugPrint('[PDF VIEWER] Toolbar hide skipped: $e');
    }
  }

  String? _extractFileId(String url) {
    try {
      debugPrint('╔═══════════════════════════════════════╗');
      debugPrint('║ EXTRACTING FILE ID FROM URL           ║');
      debugPrint('╚═══════════════════════════════════════╝');
      debugPrint('📥 Input URL: $url');
      debugPrint('📏 URL Length: ${url.length}');

      // Normalize the URL - handle both /view and /preview and /edit endpoints
      String normalizedUrl = url;

      // If it's already a preview/view URL, extract the file ID directly
      debugPrint('\n🔍 Check 1: Looking for /file/d/ pattern...');
      if (normalizedUrl.contains('/file/d/')) {
        // Format: https://drive.google.com/file/d/{FILE_ID}/preview
        // or     https://drive.google.com/file/d/{FILE_ID}/view
        final parts = normalizedUrl.split('/file/d/');
        debugPrint('   Found /file/d/ - Parts: ${parts.length}');
        if (parts.length > 1) {
          final fileIdPart = parts[1];
          debugPrint('   Part after /file/d/: $fileIdPart');
          final fileId = fileIdPart.split('/').first;
          debugPrint('   File ID after split: $fileId');
          debugPrint('   Length: ${fileId.length}');
          if (fileId.isNotEmpty && fileId.length > 10) {
            debugPrint('   ✅ VALID FILE ID FOUND: $fileId');
            return fileId;
          } else {
            debugPrint('   ❌ File ID too short (${fileId.length} chars)');
          }
        }
      }

      // Try extracting from /d/ pattern (used in share links)
      debugPrint('\n🔍 Check 2: Looking for /d/ pattern...');
      if (normalizedUrl.contains('/d/')) {
        final parts = normalizedUrl.split('/d/');
        debugPrint('   Found /d/ - Parts: ${parts.length}');
        if (parts.length > 1) {
          final fileIdPart = parts[1];
          debugPrint('   Part after /d/: $fileIdPart');
          // Remove trailing slashes and query parameters
          final fileId = fileIdPart.split('/').first.split('?').first;
          debugPrint('   File ID after split: $fileId');
          debugPrint('   Length: ${fileId.length}');
          if (fileId.isNotEmpty && fileId.length > 10) {
            debugPrint('   ✅ VALID FILE ID FOUND: $fileId');
            return fileId;
          } else {
            debugPrint('   ❌ File ID too short (${fileId.length} chars)');
          }
        }
      }

      // Try URI parsing as fallback
      debugPrint('\n🔍 Check 3: Parsing URI...');
      final uri = Uri.tryParse(normalizedUrl);
      if (uri != null) {
        debugPrint('   URI parsed successfully');
        debugPrint('   Host: ${uri.host}');
        debugPrint('   Path: ${uri.path}');
        debugPrint('   Query: ${uri.query}');

        // Try query parameter id
        debugPrint('\n   Checking query parameters...');
        final idFromQuery = uri.queryParameters['id'];
        debugPrint('   id parameter: $idFromQuery');
        if (idFromQuery != null && idFromQuery.isNotEmpty) {
          debugPrint('   ✅ VALID FILE ID FROM QUERY: $idFromQuery');
          return idFromQuery;
        }

        // Try path segments
        debugPrint('\n   Checking path segments...');
        final segments = uri.pathSegments;
        debugPrint('   Segments: $segments');
        if (segments.isNotEmpty) {
          // Look for 'file' or 'd' followed by file ID
          for (int i = 0; i < segments.length - 1; i++) {
            debugPrint('   Segment[$i]: ${segments[i]}');
            if ((segments[i] == 'file' || segments[i] == 'd') &&
                segments[i + 1].isNotEmpty &&
                segments[i + 1].length > 10) {
              debugPrint(
                  '   ✅ VALID FILE ID FROM SEGMENTS: ${segments[i + 1]}');
              return segments[i + 1];
            }
          }
        }
      } else {
        debugPrint('   ❌ URI parsing failed');
      }

      debugPrint('\n❌ COULD NOT EXTRACT FILE ID FROM: $normalizedUrl');
      debugPrint('═══════════════════════════════════════');
      return null;
    } catch (e) {
      debugPrint('❌ EXCEPTION in _extractFileId: $e');
      debugPrint('═══════════════════════════════════════');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_useExternalBrowser && _externalUri != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          elevation: 0,
          backgroundColor: AppTheme.primaryBlue,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.picture_as_pdf_outlined,
                    size: 64, color: AppTheme.primaryBlue),
                const SizedBox(height: 16),
                Text(
                  l10n.pdfDesktopHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _openExternalPdf,
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(l10n.openPdfInBrowser),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                l10n.invalidPdfUrl,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.back),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: Colors.white.withAlpha(200),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryBlue,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
