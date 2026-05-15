import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../services/supabase_service.dart';
import '../main.dart' as app;

// ============================================================
// CURRENT WORK SCREEN — Lo que estoy haciendo ahora
// ============================================================

String? _extractYouTubeId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  if (uri.host.contains('youtube.com')) {
    return uri.queryParameters['v'];
  }
  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  return null;
}

class CurrentWorkScreen extends StatefulWidget {
  const CurrentWorkScreen({super.key});

  @override
  State<CurrentWorkScreen> createState() => _CurrentWorkScreenState();
}

class _CurrentWorkScreenState extends State<CurrentWorkScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  AnimationController? _animController;

  @override
  void initState() {
    super.initState();
    _loadWorks();
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _loadWorks() async {
    setState(() => _isLoading = true);
    try {
      final items = await SupabaseService.getCurrentWorks();
      _animController?.dispose();
      _animController = null;
      if (items.isNotEmpty) {
        final totalMs = 600 + (items.length - 1) * 120;
        _animController = AnimationController(
          vsync: this,
          duration: Duration(milliseconds: totalMs),
        );
      }
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
        _animController?.forward();
      }
    } catch (e) {
      _animController?.dispose();
      _animController = null;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3845),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          app.tr(context, es: 'Lo que estoy haciendo ahora', en: 'What I\'m working on now'),
          style: GoogleFonts.roboto(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.w100,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? _buildEmptyState(context)
                  : _buildGrid(context, isDesktop),
          app.AppBackButton(isDesktop: isDesktop),
          app.AppLanguageToggle(isDesktop: isDesktop),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_outlined, size: 64, color: Colors.black26),
          const SizedBox(height: 16),
          Text(
            app.tr(context, es: 'No hay trabajos en proceso', en: 'No works in progress'),
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w200,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, bool isDesktop) {
    final totalMs = 600 + (_items.length - 1) * 120;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? MediaQuery.of(context).size.width * 0.12 : 20,
        vertical: 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Process / Work in progress',
            style: GoogleFonts.roboto(
              fontSize: 12,
              fontWeight: FontWeight.w100,
              color: Colors.black38,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: isDesktop ? 24 : 16,
            runSpacing: isDesktop ? 32 : 20,
            children: _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final startMs = index * 120;
              final endMs = startMs + 600;
              final start = startMs / totalMs;
              final end = endMs / totalMs;

              final animation = CurvedAnimation(
                parent: _animController!,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              );

              return SizedBox(
                width: isDesktop
                    ? (MediaQuery.of(context).size.width * 0.76 - 48) / 3
                    : double.infinity,
                child: _WorkCard(
                  item: item,
                  index: index,
                  isDesktop: isDesktop,
                  animation: animation,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WORK CARD
// ============================================================

class _WorkCard extends StatefulWidget {
  const _WorkCard({
    required this.item,
    required this.index,
    required this.isDesktop,
    required this.animation,
  });

  final Map<String, dynamic> item;
  final int index;
  final bool isDesktop;
  final Animation<double> animation;

  @override
  State<_WorkCard> createState() => _WorkCardState();
}

class _WorkCardState extends State<_WorkCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final mediaType = widget.item['media_type'] as String? ?? 'youtube';
    final mediaUrl = widget.item['media_url'] as String? ?? '';
    final title = widget.item['title'] as String? ?? '';
    final description = widget.item['description'] as String? ?? '';

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, child) {
        final value = widget.animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          scale: widget.isDesktop && _isHovered ? 1.02 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: widget.isDesktop && _isHovered ? 0.08 : 0.04,
                  ),
                  blurRadius: widget.isDesktop && _isHovered ? 28 : 20,
                  spreadRadius: 0,
                  offset: Offset(
                    0,
                    widget.isDesktop && _isHovered ? 12 : 8,
                  ),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Media area
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: mediaType == 'youtube'
                        ? _YouTubeThumbnail(url: mediaUrl)
                        : _VideoThumbnail(url: mediaUrl),
                  ),
                ),
                // Info
                if (title.isNotEmpty || description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title.isNotEmpty)
                          Text(
                            title,
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1a1a1a),
                              letterSpacing: 0.8,
                            ),
                          ),
                        if (title.isNotEmpty && description.isNotEmpty)
                          const SizedBox(height: 6),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: const Color(0xFF666666),
                              height: 1.5,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// YOUTUBE THUMBNAIL
// ============================================================

class _YouTubeThumbnail extends StatefulWidget {
  const _YouTubeThumbnail({required this.url});

  final String url;

  @override
  State<_YouTubeThumbnail> createState() => _YouTubeThumbnailState();
}

class _YouTubeThumbnailState extends State<_YouTubeThumbnail> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final videoId = _extractYouTubeId(widget.url);
    final thumbnailUrl = videoId != null
        ? 'https://img.youtube.com/vi/$videoId/mqdefault.jpg'
        : null;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(widget.url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            if (thumbnailUrl != null)
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFF1a1a1a),
                  child: const Icon(Icons.broken_image, color: Colors.white24),
                ),
              )
            else
              Container(
                color: const Color(0xFF1a1a1a),
                child: const Center(
                  child: Icon(Icons.play_circle_outline, color: Colors.white30, size: 48),
                ),
              ),
            // Dark overlay
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              color: _isHovered
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.12),
            ),
            // Play button
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                scale: _isHovered ? 1.12 : 1.0,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: _isHovered ? 0.95 : 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: _isHovered ? 0.25 : 0.15,
                        ),
                        blurRadius: _isHovered ? 24 : 16,
                        offset: Offset(0, _isHovered ? 6 : 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: const Color(0xFF1E3845),
                    size: 32,
                  ),
                ),
              ),
            ),
            // YouTube label
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'YouTube',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// VIDEO THUMBNAIL (MP4) — abre dialog con reproductor
// ============================================================

class _VideoThumbnail extends StatefulWidget {
  const _VideoThumbnail({required this.url});

  final String url;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  bool _isHovered = false;

  void _openVideoDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => _VideoDialog(url: widget.url),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: _openVideoDialog,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: const Color(0xFF1a1a1a),
            ),
            // Subtle film icon
            Center(
              child: Icon(
                Icons.videocam_outlined,
                color: Colors.white.withValues(alpha: 0.15),
                size: 48,
              ),
            ),
            // Overlay
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: _isHovered
                  ? Colors.black.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.12),
            ),
            // Play button
            Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: _isHovered ? 1.08 : 1.0,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: _isHovered ? 0.95 : 0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: const Color(0xFF1E3845),
                    size: 32,
                  ),
                ),
              ),
            ),
            // Video label
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'MP4',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// VIDEO DIALOG — Reproductor a pantalla completa
// ============================================================

class _VideoDialog extends StatefulWidget {
  const _VideoDialog({required this.url});

  final String url;

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..addListener(_onListener)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.play();
        }
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  void _onListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          Center(
            child: _hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'No se pudo cargar el video',
                        style: GoogleFonts.roboto(color: Colors.white70),
                      ),
                    ],
                  )
                : _isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
          ),

          // Close button
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),

          // Play/pause overlay (tap to toggle)
          if (_isInitialized)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Container(
                  color: Colors.transparent,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: const Color(0xFF1E3845),
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom progress bar
          if (_isInitialized)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: SafeArea(
                top: false,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
