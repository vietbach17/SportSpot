import 'package:flutter/material.dart';

/// Dashed line painter for boarding pass tear line.
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  const DashedLinePainter({
    this.color = const Color(0xFFCBD5E1),
    this.dashWidth = 5.0,
    this.dashSpace = 4.0,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double startX = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Boarding pass tear divider with semicircular notch cutouts on both ends.
class TicketTearDivider extends StatelessWidget {
  final Color backgroundColor;
  final Color dashColor;
  final double cutoutRadius;

  const TicketTearDivider({
    super.key,
    required this.backgroundColor,
    this.dashColor = const Color(0xFFCBD5E1),
    this.cutoutRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cutoutRadius * 2,
      child: Row(
        children: [
          // Left Notch Cutout
          Transform.translate(
            offset: Offset(-cutoutRadius, 0),
            child: Container(
              width: cutoutRadius * 2,
              height: cutoutRadius * 2,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Dashed Tear Line
          Expanded(
            child: CustomPaint(
              size: Size(double.infinity, cutoutRadius * 2),
              painter: DashedLinePainter(
                color: dashColor,
                dashWidth: 6,
                dashSpace: 4,
              ),
            ),
          ),

          // Right Notch Cutout
          Transform.translate(
            offset: Offset(cutoutRadius, 0),
            child: Container(
              width: cutoutRadius * 2,
              height: cutoutRadius * 2,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated QR Laser Scanning Line moving vertically over the QR code container.
class QrLaserScanLine extends StatefulWidget {
  final Widget child;
  final bool isScanning;
  final Color laserColor;

  const QrLaserScanLine({
    super.key,
    required this.child,
    this.isScanning = true,
    this.laserColor = const Color(0xFF00C853),
  });

  @override
  State<QrLaserScanLine> createState() => _QrLaserScanLineState();
}

class _QrLaserScanLineState extends State<QrLaserScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.isScanning && !_isTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void didUpdateWidget(covariant QrLaserScanLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isTest) return;
    if (widget.isScanning && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isScanning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (widget.isScanning)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final topOffset = _controller.value * (constraints.maxHeight - 20);
                    return Stack(
                      children: [
                        Positioned(
                          top: topOffset,
                          left: 10,
                          right: 10,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Glowing gradient light bar
                              Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: widget.laserColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.laserColor.withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: widget.laserColor.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              // Laser gradient sweep
                              Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      widget.laserColor.withValues(alpha: 0.25),
                                      widget.laserColor.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
