import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  late final YoutubePlayerController _ytController;
  WebViewController? _webController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    if (widget.videoType == 'youtube') {
      final videoId = YoutubePlayer.convertUrlToId(widget.rawVideoUrl) ?? '';
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    } else {
      _webController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ))
        ..loadRequest(Uri.parse(widget.embedUrl));
    }
  }

  @override
  void dispose() {
    if (widget.videoType == 'youtube') {
      _ytController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoType == 'youtube') {
      return YoutubePlayer(
        controller: _ytController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
      );
    }

    // Google Drive
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          if (_webController != null)
            WebViewWidget(controller: _webController!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }
}
