import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum ConfirmActionType {
  primary,
  destructive,
  warning,
  success,
}

class ConfirmInfoRow {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const ConfirmInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });
}

/// Reusable Mobile-First Confirmation Bottom Sheet / Dialog
/// Cung cấp giao diện xác nhận mượt mà, trực quan, đậm chất thể thao
/// cho các tác vụ quan trọng (đặt sân, thanh toán, hủy vé, đăng xuất, rời trận).
class SportSpotConfirmSheet extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData icon;
  final ConfirmActionType actionType;
  final List<ConfirmInfoRow>? infoRows;
  final Widget? customContent;

  const SportSpotConfirmSheet({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Xác nhận',
    this.cancelLabel = 'Hủy bỏ',
    this.icon = Icons.help_outline_rounded,
    this.actionType = ConfirmActionType.primary,
    this.infoRows,
    this.customContent,
  });

  /// Hiển thị Confirmation Sheet chuẩn Mobile-First (Modal Bottom Sheet)
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Xác nhận',
    String cancelLabel = 'Hủy bỏ',
    IconData icon = Icons.help_outline_rounded,
    ConfirmActionType actionType = ConfirmActionType.primary,
    List<ConfirmInfoRow>? infoRows,
    Widget? customContent,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SportSpotConfirmSheet(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        actionType: actionType,
        infoRows: infoRows,
        customContent: customContent,
      ),
    );
  }

  Color _getAccentColor() {
    switch (actionType) {
      case ConfirmActionType.destructive:
        return const Color(0xFFDC2626);
      case ConfirmActionType.warning:
        return const Color(0xFFD97706);
      case ConfirmActionType.success:
        return const Color(0xFF00A859);
      case ConfirmActionType.primary:
        return const Color(0xFF111315);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191A20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? const Color(0xFFF6F6F3) : const Color(0xFF111315);
    final mutedColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final accentColor = _getAccentColor();

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 16
            : 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header: Icon + Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: mutedColor,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Info Breakdown Rows (if any)
          if (infoRows != null && infoRows!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF22252E) : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: List.generate(infoRows!.length, (idx) {
                  final row = infoRows![idx];
                  return Padding(
                    padding: EdgeInsets.only(bottom: idx == infoRows!.length - 1 ? 0 : 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          row.label,
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 12.5,
                            color: mutedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          row.value,
                          style: TextStyle(
                            fontFamily: AppTheme.headingFont,
                            fontSize: row.isBold ? 14 : 12.5,
                            fontWeight: row.isBold ? FontWeight.w900 : FontWeight.w700,
                            color: row.valueColor ?? textColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 18),
          ],

          if (customContent != null) ...[
            customContent!,
            const SizedBox(height: 18),
          ],

          // Action Buttons: Primary Confirm + Secondary Cancel
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelLabel,
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
