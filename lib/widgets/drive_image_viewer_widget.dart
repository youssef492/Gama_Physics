import 'package:flutter/material.dart';
import 'package:gama/config/theme.dart';
import 'package:gama/l10n/app_localizations.dart';

class DriveImageViewerWidget extends StatelessWidget {
  final String imageUrl;
  final String title;

  const DriveImageViewerWidget({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Center(
            child: DriveImage(
              sourceUrl: imageUrl,
              fit: BoxFit.contain,
              backgroundColor: Colors.black,
              invalidLabel: l10n.invalidImageUrl,
            ),
          ),
        ),
      ),
    );
  }
}

class DriveImage extends StatefulWidget {
  final String sourceUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final String? invalidLabel;

  const DriveImage({
    super.key,
    required this.sourceUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.invalidLabel,
  });

  @override
  State<DriveImage> createState() => _DriveImageState();
}

class _DriveImageState extends State<DriveImage> {
  late final List<String> _candidates;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _candidates = _buildImageUrls(widget.sourceUrl);
  }

  void _tryNextCandidate() {
    if (!mounted || _currentIndex >= _candidates.length - 1) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _currentIndex += 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_candidates.isEmpty) {
      return _buildFallback(
        child: Text(
          widget.invalidLabel ?? 'Invalid image URL',
          style: const TextStyle(
            color: AppTheme.errorRed,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final image = Image.network(
      _candidates[_currentIndex],
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stackTrace) {
        if (_currentIndex < _candidates.length - 1) {
          _tryNextCandidate();
          return _buildLoading();
        }
        return _buildFallback(
          child: Icon(
            Icons.broken_image_outlined,
            size: 34,
            color: Colors.grey.shade500,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoading();
      },
    );

    if (widget.borderRadius == null) return image;

    return ClipRRect(
      borderRadius: widget.borderRadius!,
      child: image,
    );
  }

  Widget _buildLoading() {
    return _buildFallback(
      child: const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildFallback({required Widget child}) {
    return Container(
      width: widget.width,
      height: widget.height,
      alignment: Alignment.center,
      color: widget.backgroundColor ?? Colors.grey.shade100,
      child: child,
    );
  }

  String? _extractFileId(String url) {
    final normalizedUrl = url.trim();
    if (normalizedUrl.isEmpty) return null;
    if (!normalizedUrl.contains('/')) return normalizedUrl;

    if (normalizedUrl.contains('/file/d/')) {
      final parts = normalizedUrl.split('/file/d/');
      if (parts.length > 1) {
        final fileId = parts[1].split('/').first.split('?').first;
        if (fileId.isNotEmpty) return fileId;
      }
    }

    if (normalizedUrl.contains('/d/')) {
      final parts = normalizedUrl.split('/d/');
      if (parts.length > 1) {
        final fileId = parts[1].split('/').first.split('?').first;
        if (fileId.isNotEmpty) return fileId;
      }
    }

    final uri = Uri.tryParse(normalizedUrl);
    return uri?.queryParameters['id'];
  }

  List<String> _buildImageUrls(String sourceUrlOrFileId) {
    final fileId = _extractFileId(sourceUrlOrFileId);
    if (fileId == null) return const [];

    return [
      'https://drive.google.com/thumbnail?id=$fileId&sz=w2000',
      'https://drive.google.com/uc?export=view&id=$fileId',
      'https://lh3.googleusercontent.com/d/$fileId=w2000',
    ];
  }
}
