import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tiện ích hỗ trợ mở Google Maps chỉ đường (Directions)
class MapsLauncher {
  /// Mở Google Maps chỉ đường đến tọa độ hoặc địa chỉ sân.
  /// Định dạng URL: https://www.google.com/maps/dir/?api=1&destination=...
  /// Ưu tiên tọa độ lat/lng nếu hợp lệ (khác 0), nếu không sẽ dùng địa chỉ sân.
  /// Hỗ trợ mở tab mới trên Web (target="_blank" rel="noopener noreferrer")
  /// và mở ứng dụng ngoài (external application) trên Mobile/Desktop.
  static Future<bool> openDirections({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    String destination = '';
    if (latitude != null &&
        longitude != null &&
        latitude != 0.0 &&
        longitude != 0.0) {
      destination = '$latitude,$longitude';
    } else if (address != null && address.trim().isNotEmpty) {
      destination = Uri.encodeComponent(address.trim());
    }

    if (destination.isEmpty) {
      debugPrint('[MapsLauncher] Không có thông tin tọa độ hoặc địa chỉ để chỉ đường.');
      return false;
    }

    final urlString = 'https://www.google.com/maps/dir/?api=1&destination=$destination';
    final uri = Uri.parse(urlString);

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      }
    } catch (e) {
      debugPrint('[MapsLauncher] Lỗi khi mở Google Maps: $e');
      return false;
    }
  }
}
