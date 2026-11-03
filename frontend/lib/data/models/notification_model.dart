class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Thông báo',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'System',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

class NotificationSummaryModel {
  final int unreadCount;
  final List<NotificationModel> notifications;

  const NotificationSummaryModel({
    required this.unreadCount,
    required this.notifications,
  });

  factory NotificationSummaryModel.fromJson(Map<String, dynamic> json) {
    final listRaw = json['notifications'] as List<dynamic>? ?? [];
    final items = listRaw
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return NotificationSummaryModel(
      unreadCount: json['unreadCount'] as int? ?? items.where((n) => !n.isRead).length,
      notifications: items,
    );
  }
}
