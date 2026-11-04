import 'package:flutter/material.dart';

class VenueImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final double borderRadius;
  final String? openUntil;
  final bool isVerified;
  final String verifiedText;
  final VoidCallback? onTapImage;
  final ValueChanged<int>? onPageChanged;

  const VenueImageCarousel({
    super.key,
    required this.images,
    this.height = 220,
    this.borderRadius = 10,
    this.openUntil,
    this.isVerified = true,
    this.verifiedText = 'SÂN XÁC THỰC',
    this.onTapImage,
    this.onPageChanged,
  });

  @override
  State<VenueImageCarousel> createState() => _VenueImageCarouselState();
}

class _VenueImageCarouselState extends State<VenueImageCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  List<String> get _displayImages {
    final clean = widget.images.where((s) => s.trim().isNotEmpty).toList();
    if (clean.isNotEmpty) return clean;
    return const [
      'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=1200&q=80',
      'https://images.unsplash.com/photo-1613918108466-292b78a8ef95?w=1200&q=80',
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=1200&q=80',
    ];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleImageTap(int index) async {
    if (widget.onTapImage != null) {
      widget.onTapImage!();
      return;
    }
    final newIndex = await VenueImageLightbox.show(
      context,
      images: _displayImages,
      initialIndex: index,
    );
    if (newIndex != null && mounted && newIndex != _currentIndex) {
      _pageController.jumpToPage(newIndex);
      setState(() => _currentIndex = newIndex);
      widget.onPageChanged?.call(newIndex);
    }
  }

  void _goToPrevious() {
    final images = _displayImages;
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        images.length - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    final images = _displayImages;
    if (_currentIndex < images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _displayImages;
    final hasMultiple = images.length > 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: const Color(0xFF1E293B),
        child: Stack(
          children: [
            // 1. Swipeable/Scrollable Image PageView with Lightbox Tap
            PageView.builder(
              key: const Key('venue_image_pageview'),
              controller: _pageController,
              itemCount: images.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
                widget.onPageChanged?.call(index);
              },
              itemBuilder: (context, index) {
                final imageUrl = images[index];
                return GestureDetector(
                  key: Key('carousel_image_tap_$index'),
                  onTap: () => _handleImageTap(index),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: widget.height,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: widget.height,
                      width: double.infinity,
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(
                          Icons.sports_tennis_rounded,
                          color: Color(0xFF2563EB),
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. Athletic Vignette Gradients
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Top-Left Badge: Sân Xác Thực
            if (widget.isVerified)
              Positioned(
                top: 14,
                left: 14,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          widget.verifiedText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 4. Top-Right Badge: Giờ mở cửa
            if (widget.openUntil != null && widget.openUntil!.isNotEmpty)
              Positioned(
                top: 14,
                right: 14,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '06:00 - ${widget.openUntil}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 5. Left Transition Button (Nút chuyển trái)
            if (hasMultiple)
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('carousel_btn_prev'),
                      onTap: _goToPrevious,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.48),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 0.8),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 6. Right Transition Button (Nút chuyển phải)
            if (hasMultiple)
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('carousel_btn_next'),
                      onTap: _goToNext,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.48),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 0.8),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 7. Pagination Dots ở dưới đáy hình báo số lượng ảnh
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  key: const Key('venue_carousel_pagination'),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // List of pagination dots
                      ...List.generate(images.length, (index) {
                        final isActive = index == _currentIndex;
                        return GestureDetector(
                          key: Key('carousel_dot_$index'),
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF00A859) : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00A859).withValues(alpha: 0.6),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                      if (hasMultiple) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 1,
                          height: 10,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_currentIndex + 1}/${images.length}',
                          key: const Key('carousel_counter'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ],
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

/// Fullscreen Lightbox displaying venue images with pinch-to-zoom (InteractiveViewer),
/// swiping gesture, pagination dots/index counter, and close button.
class VenueImageLightbox extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const VenueImageLightbox({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  static Future<int?> show(
    BuildContext context, {
    required List<String> images,
    int initialIndex = 0,
  }) {
    return Navigator.push<int>(
      context,
      PageRouteBuilder<int>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, animation, secondaryAnimation) => VenueImageLightbox(
          images: images,
          initialIndex: initialIndex,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<VenueImageLightbox> createState() => _VenueImageLightboxState();
}

class _VenueImageLightboxState extends State<VenueImageLightbox> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        widget.images.length - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final hasMultiple = images.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Swipeable Fullscreen PageView with InteractiveViewer (pinch-to-zoom)
          PageView.builder(
            key: const Key('lightbox_pageview'),
            controller: _pageController,
            itemCount: images.length,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return Center(
                child: InteractiveViewer(
                  key: Key('lightbox_interactive_viewer_$index'),
                  minScale: 0.8,
                  maxScale: 4.0,
                  clipBehavior: Clip.none,
                  child: Image.network(
                    images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white54,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Top Bar with Title and Close Button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_rounded, size: 14, color: Colors.white70),
                          const SizedBox(width: 6),
                          Text(
                            'Xem Chi Tiết Sân (${_currentIndex + 1}/${images.length})',
                            key: const Key('lightbox_header_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('lightbox_btn_close'),
                        onTap: () => Navigator.pop(context, _currentIndex),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Left Transition Button (Nút chuyển trái)
          if (hasMultiple)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('lightbox_btn_prev'),
                    onTap: _goToPrevious,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 0.8),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 4. Right Transition Button (Nút chuyển phải)
          if (hasMultiple)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: const Key('lightbox_btn_next'),
                    onTap: _goToNext,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30, width: 0.8),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 5. Bottom Pagination Dots & Counter (Chấm tròn và chỉ số)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  key: const Key('lightbox_pagination'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // List of pagination dots
                      ...List.generate(images.length, (index) {
                        final isActive = index == _currentIndex;
                        return GestureDetector(
                          key: Key('lightbox_dot_$index'),
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: isActive ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF00A859) : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF00A859).withValues(alpha: 0.6),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }),
                      if (hasMultiple) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 12,
                          color: Colors.white24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_currentIndex + 1}/${images.length}',
                          key: const Key('lightbox_counter'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
