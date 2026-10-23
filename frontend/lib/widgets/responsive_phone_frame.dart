import 'package:flutter/material.dart';

/// Bọc giao diện Flutter vào một khung điện thoại thông minh (Phone Mockup)
/// khi chạy trên Web hoặc Desktop, giúp người dùng và nhóm nhìn thấy chính xác
/// tỷ lệ điện thoại di động mà không cần phải chỉnh F12 thủ công.
/// Khi chạy trên điện thoại thật (màn hình < 520px), widget sẽ tự động bung full screen 100%.
class ResponsivePhoneFrame extends StatelessWidget {
  final Widget child;

  const ResponsivePhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Nếu màn hình nhỏ (điện thoại thật hoặc màn hình < 520px) -> hiển thị full màn hình
        if (constraints.maxWidth <= 520) {
          return child;
        }

        const double frameWidth = 412.0;
        final double frameHeight = constraints.maxHeight.clamp(680.0, 890.0);

        return Scaffold(
          backgroundColor: const Color(0xFF0F1117),
          body: Stack(
            alignment: Alignment.center,
            children: [
              // Logo chìm trang trí nền máy tính
              const Positioned.fill(
                child: Opacity(
                  opacity: 0.04,
                  child: Center(
                    child: Icon(
                      Icons.sports_tennis_rounded,
                      size: 600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Thanh tiêu đề gợi ý trên nền web
              Positioned(
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E212B),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.smartphone_rounded, size: 14, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        'SportSpot Mobile Preview (412 x 890)',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              // Khung điện thoại thông minh (Phone Frame)
              Center(
                child: Container(
                  width: frameWidth,
                  height: frameHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(44),
                    border: Border.all(
                      color: const Color(0xFF2E3446),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 40,
                        spreadRadius: 2,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                        blurRadius: 70,
                        spreadRadius: -10,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Nội dung ứng dụng bọc trong MediaQuery chuẩn điện thoại
                      MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          size: Size(frameWidth, frameHeight),
                          padding: const EdgeInsets.only(top: 32, bottom: 8),
                          viewInsets: EdgeInsets.zero,
                        ),
                        child: child,
                      ),

                      // Dynamic Island / Camera Notch giả lập
                      Positioned(
                        top: 7,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 104,
                            height: 22,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1E293B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
