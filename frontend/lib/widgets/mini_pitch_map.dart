import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CourtInfo {
  final int id;
  final String name;
  final String surface;
  final String status; // 'available', 'reserved', 'in_match'
  final int pricePerHour;

  const CourtInfo({
    required this.id,
    required this.name,
    required this.surface,
    required this.status,
    required this.pricePerHour,
  });
}

/// Stylized interactive Mini Pitch Map representing the venue's court grid.
class MiniPitchMap extends StatefulWidget {
  final String sportType;
  final List<CourtInfo>? courts;
  final ValueChanged<CourtInfo>? onCourtSelected;

  const MiniPitchMap({
    super.key,
    this.sportType = 'Cầu lông',
    this.courts,
    this.onCourtSelected,
  });

  @override
  State<MiniPitchMap> createState() => _MiniPitchMapState();
}

class _MiniPitchMapState extends State<MiniPitchMap> {
  int _selectedCourtIndex = 0;

  late final List<CourtInfo> _courtList = widget.courts ?? [
    const CourtInfo(
      id: 1,
      name: 'Sân 01 (VIP Thảm Yonex)',
      surface: 'Yonex Mat Pro',
      status: 'available',
      pricePerHour: 120000,
    ),
    const CourtInfo(
      id: 2,
      name: 'Sân 02 (Tiêu chuẩn)',
      surface: 'PVC Enlio Anti-slip',
      status: 'reserved',
      pricePerHour: 100000,
    ),
    const CourtInfo(
      id: 3,
      name: 'Sân 03 (Tiêu chuẩn)',
      surface: 'PVC Enlio Anti-slip',
      status: 'available',
      pricePerHour: 100000,
    ),
    const CourtInfo(
      id: 4,
      name: 'Sân 04 (Khởi động)',
      surface: 'Gỗ phong tự nhiên',
      status: 'in_match',
      pricePerHour: 90000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1D23) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2C303C) : const Color(0xFFE4E4E0);
    final textColor = isDark ? Colors.white : const Color(0xFF111315);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    final selected = _courtList[_selectedCourtIndex.clamp(0, _courtList.length - 1)];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A859).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.stadium_rounded, size: 18, color: Color(0xFF00A859)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sơ Đồ Sân Đấu Trực Quan',
                        style: TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A859).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, size: 7, color: Color(0xFF00A859)),
                    SizedBox(width: 4),
                    Text(
                      'Live Map',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF00A859),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Pitch Visual Graphic
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A3A21), Color(0xFF082D19)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Pitch Court Lines Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PitchFieldPainter(),
                    ),
                  ),

                  // Court Nodes Grid
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.3,
                        ),
                        itemCount: _courtList.length,
                        itemBuilder: (context, idx) {
                          final court = _courtList[idx];
                          final isSelected = _selectedCourtIndex == idx;

                          Color statusColor;
                          String statusText;
                          if (court.status == 'available') {
                            statusColor = const Color(0xFF00E676);
                            statusText = 'Trống';
                          } else if (court.status == 'reserved') {
                            statusColor = const Color(0xFFFBBF24);
                            statusText = 'Đặt trước';
                          } else {
                            statusColor = const Color(0xFFF87171);
                            statusText = 'Đang đá';
                          }

                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedCourtIndex = idx);
                              widget.onCourtSelected?.call(court);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.22)
                                    : Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.25),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'SÂN 0${court.id}',
                                          style: TextStyle(
                                            fontFamily: AppTheme.headingFont,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          statusText,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor.withValues(alpha: 0.6),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Selected Court Quick Detail & Status Legend
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22252E) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.name,
                        style: TextStyle(
                          fontFamily: AppTheme.headingFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mặt sân: ${selected.surface}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${selected.pricePerHour ~/ 1000}k/giờ',
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF00A859),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Field perimeter
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
        const Radius.circular(8),
      ),
      paint,
    );

    // Center division line
    canvas.drawLine(
      Offset(size.width / 2, 8),
      Offset(size.width / 2, size.height - 8),
      paint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      22,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
