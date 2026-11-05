import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Logo SportSpot từ ảnh thương hiệu của dự án.
class SportSpotBrandLogo extends StatelessWidget {
  final double size;
  final double iconSize;

  const SportSpotBrandLogo({
    super.key,
    this.size = 28,
    this.iconSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'logo-sp.png',
        fit: BoxFit.contain,
        semanticLabel: 'SportSpot',
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

/// Tên thương hiệu SportSpot dạng Wordmark với font Montserrat ExtraBold / Black
class SportSpotBrandWordmark extends StatelessWidget {
  final double fontSize;
  final bool showLogo;
  final double logoSize;
  final Color? textColor;
  final Color accentColor;
  final Color dotColor;

  const SportSpotBrandWordmark({
    super.key,
    this.fontSize = 16,
    this.showLogo = false,
    this.logoSize = 24,
    this.textColor,
    this.accentColor = const Color(0xFF00A859),
    this.dotColor = const Color(0xFFFF5E1F),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = textColor ?? (isDark ? Colors.white : const Color(0xFF111315));

    final textWidget = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'Sport',
          style: TextStyle(
            fontFamily: AppTheme.headingFont,
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            color: primaryColor,
            letterSpacing: -0.4,
          ),
        ),
        Text(
          'Spot',
          style: TextStyle(
            fontFamily: AppTheme.headingFont,
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            color: accentColor,
            letterSpacing: -0.4,
          ),
        ),
        Container(
          width: fontSize * 0.22,
          height: fontSize * 0.22,
          margin: const EdgeInsets.only(left: 1.5),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );

    if (!showLogo) return textWidget;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SportSpotBrandLogo(size: logoSize, iconSize: logoSize * 0.62),
        SizedBox(width: logoSize * 0.32),
        textWidget,
      ],
    );
  }
}

/// ============================================================================
/// DUY NHẤT 1 MẪU HEADER CHUẨN ĐỒNG BỘ 100% CHO TẤT CẢ CÁC TRANG CỦA SPORTSPOT
/// ============================================================================
class SportSpotUnifiedHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? screenName;
  final List<Widget>? actions;
  final bool? showBackButton;
  final VoidCallback? onBack;
  final double height;
  final bool showBottomBorder;

  const SportSpotUnifiedHeader({
    super.key,
    this.screenName,
    this.actions,
    this.showBackButton,
    this.onBack,
    this.height = 56.0,
    this.showBottomBorder = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF191A20) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E313A) : const Color(0xFFE5E7EB);
    final textColor = isDark ? Colors.white : const Color(0xFF111315);
    final canPop = showBackButton ?? (ModalRoute.of(context)?.canPop ?? false);

    return Container(
      height: height + MediaQuery.paddingOf(context).top,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: BoxDecoration(
        color: cardBg,
        border: showBottomBorder
            ? Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: 1.0,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Nút Back chuẩn Flutter để hỗ trợ tester.pageBack() và điều hướng native
            if (canPop)
              Theme(
                data: Theme.of(context).copyWith(
                  iconButtonTheme: IconButtonThemeData(
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                child: BackButton(
                  color: textColor,
                  onPressed: onBack,
                ),
              ),

            // Nhận diện thương hiệu chuẩn: [Logo cố định] + [Chữ SportSpot] + [Badge trang]
            Expanded(
              child: Row(
                children: [
                  const SportSpotBrandLogo(size: 26, iconSize: 15),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 4,
                    child: Text(
                      'SportSpot',
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: textColor,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (screenName != null && screenName!.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 1.0,
                      height: 12,
                      color: isDark ? const Color(0xFF3B4050) : const Color(0xFFD1D5DB),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00A859).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF00A859).withValues(alpha: 0.28),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          screenName!,
                          style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                            color: Color(0xFF00A859),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Actions bên phải nếu có
            if (actions != null && actions!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Giữ lại tương thích ngược cho SportSpotAppBarTitle & SportSpotBrandHeader
class SportSpotAppBarTitle extends StatelessWidget {
  final String? pageTitle;
  final Widget? titleWidget;
  final Widget? trailingBadge;
  final double logoSize;

  const SportSpotAppBarTitle({
    super.key,
    this.pageTitle,
    this.titleWidget,
    this.trailingBadge,
    this.logoSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111315);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SportSpotBrandLogo(size: logoSize, iconSize: logoSize * 0.62),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SportSpotBrandWordmark(fontSize: 13.5, textColor: textColor),
                  if (trailingBadge != null) ...[
                    const SizedBox(width: 6),
                    trailingBadge!,
                  ],
                ],
              ),
              if (titleWidget != null)
                titleWidget!
              else if (pageTitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  pageTitle!,
                  style: TextStyle(
                    fontFamily: AppTheme.headingFont,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class SportSpotBrandHeader extends StatelessWidget {
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final double logoSize;

  const SportSpotBrandHeader({
    super.key,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.logoSize = 34,
  });

  @override
  Widget build(BuildContext context) {
    return SportSpotUnifiedHeader(
      screenName: subtitle,
      actions: trailing != null ? [trailing!] : null,
      showBottomBorder: false,
    );
  }
}
