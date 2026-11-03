import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/fcm_push_service.dart';
import '../../data/services/floating_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final INotificationRepository? repository;

  const NotificationsScreen({super.key, this.repository});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final INotificationRepository _repository;
  NotificationSummaryModel? _summary;
  bool _isLoading = true;
  int _selectedFilterIndex = 0; // 0: Tất cả, 1: Chưa đọc

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiNotificationRepository();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _repository.getNotifications();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationModel notif) async {
    if (notif.isRead) return;
    setState(() {
      if (_summary != null) {
        final updatedList = _summary!.notifications.map((n) {
          return n.id == notif.id ? n.copyWith(isRead: true) : n;
        }).toList();
        _summary = NotificationSummaryModel(
          unreadCount: updatedList.where((n) => !n.isRead).length,
          notifications: updatedList,
        );
      }
    });
    await _repository.markAsRead(notif.id);
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      if (_summary != null) {
        final updatedList = _summary!.notifications.map((n) => n.copyWith(isRead: true)).toList();
        _summary = NotificationSummaryModel(unreadCount: 0, notifications: updatedList);
      }
    });
    await _repository.markAllAsRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã đánh dấu toàn bộ thông báo là đã đọc')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF8FAFC);
    const textColor = Color(0xFF0F172A);
    const mutedColor = Color(0xFF64748B);

    final notifications = _summary?.notifications ?? [];
    final displayedList = _selectedFilterIndex == 1
        ? notifications.where((n) => !n.isRead).toList()
        : notifications;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Thông Báo & Nhắc Lịch',
          style: TextStyle(
            fontFamily: AppTheme.headingFont,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Color(0xFFFF5E1F)),
            tooltip: 'Thử Thông báo nổi',
            onPressed: () {
              FcmPushService.instance.simulateIncomingPush(
                title: 'Nhắc lịch thi đấu (2 tiếng)',
                message: 'Sân Kỳ Hòa sắp bắt đầu lúc 18:00. Bạn nhớ đến đúng giờ nhé!',
                type: 'Reminder',
              );
            },
          ),
          if ((_summary?.unreadCount ?? 0) > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Choice Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Tất cả (${notifications.length})'),
                  selected: _selectedFilterIndex == 0,
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilterIndex = 0);
                  },
                  selectedColor: const Color(0xFFEFF6FF),
                  labelStyle: TextStyle(
                    color: _selectedFilterIndex == 0 ? const Color(0xFF2563EB) : mutedColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Chưa đọc (${_summary?.unreadCount ?? 0})'),
                  selected: _selectedFilterIndex == 1,
                  onSelected: (val) {
                    if (val) setState(() => _selectedFilterIndex = 1);
                  },
                  selectedColor: const Color(0xFFEFF6FF),
                  labelStyle: TextStyle(
                    color: _selectedFilterIndex == 1 ? const Color(0xFF2563EB) : mutedColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFilterIndex == 1 ? 'Không có thông báo chưa đọc' : 'Chưa có thông báo nào',
                              style: const TextStyle(fontSize: 14, color: mutedColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: displayedList.length,
                          itemBuilder: (context, index) {
                            final n = displayedList[index];
                            return _buildNotificationTile(n, textColor, mutedColor);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel n, Color textColor, Color mutedColor) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    switch (n.type) {
      case 'Reminder':
        icon = Icons.alarm_rounded;
        iconColor = const Color(0xFFD97706);
        iconBg = const Color(0xFFFEF3C7);
        break;
      case 'Booking':
        icon = Icons.check_circle_outline_rounded;
        iconColor = const Color(0xFF16A34A);
        iconBg = const Color(0xFFDCFCE7);
        break;
      case 'Match':
        icon = Icons.groups_rounded;
        iconColor = const Color(0xFF7C3AED);
        iconBg = const Color(0xFFEDE9FE);
        break;
      default:
        icon = Icons.notifications_active_rounded;
        iconColor = const Color(0xFF2563EB);
        iconBg = const Color(0xFFEFF6FF);
    }

    return AppPressable(
      onTap: () {
        _markAsRead(n);
        FloatingNotificationService.show(
          title: n.title,
          message: n.message,
          type: n.type,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n.isRead ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
            width: 1,
          ),
          boxShadow: AppShadows.soft,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: TextStyle(fontSize: 12.5, color: mutedColor, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')} • ${n.createdAt.day}/${n.createdAt.month}/${n.createdAt.year}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
