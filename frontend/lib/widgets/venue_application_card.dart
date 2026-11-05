import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models/venue_config_models.dart';

String venueApplicationStatus(String status) => switch (status) {
  'Approved' => 'Đã duyệt',
  'Rejected' => 'Bị từ chối',
  _ => 'Chờ duyệt',
};

class VenueApplicationCard extends StatelessWidget {
  final VenueApplicationModel application;
  final List<Widget> actions;
  const VenueApplicationCard({
    super.key,
    required this.application,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final v = application;
    final money = NumberFormat.decimalPattern('vi');
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v.name, style: Theme.of(context).textTheme.titleLarge),
            Chip(label: Text(venueApplicationStatus(v.status))),
            Text('${v.sportName} • ${v.courtNames.length} sân con'),
            Text('${v.address}, ${v.district}'),
            Text('Chủ sân: ${v.ownerName} • ${v.ownerPhone}'),
            Text('Hotline: ${v.hotline}'),
            if (v.submittedAt != null)
              Text(
                'Ngày gửi: ${DateFormat('dd/MM/yyyy HH:mm').format(v.submittedAt!.toLocal())}',
              ),
            if (v.rejectionReason != null)
              Text(
                'Lý do từ chối: ${v.rejectionReason}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Chi tiết hồ sơ'),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    [
                      'Tọa độ: ${v.latitude}, ${v.longitude}',
                      'Giá thường: ${money.format(v.basePrice)}đ • Cao điểm: ${money.format(v.peakPrice)}đ',
                      'Cọc tối thiểu: ${v.minDepositPercent}% • Tối đa ${v.maxSlotsPerBooking} slot/đơn',
                      'Giờ mở cửa: ${v.operatingHoursSummary}',
                      'Sân con: ${v.courtNames.join(', ')}',
                      if (v.description.isNotEmpty) 'Mô tả: ${v.description}',
                      if (v.amenities.isNotEmpty) 'Tiện ích: ${v.amenities}',
                      for (final s in v.services)
                        'Dịch vụ: ${s.name} • ${money.format(s.price)}đ • SL ${s.stockQuantity}',
                      for (final s in v.slotConfigs.where((s) => s.isActive))
                        '${s.startTime}–${s.endTime}: ${money.format(s.effectivePrice)}đ${s.isPeak ? ' (cao điểm)' : ''}',
                    ].join('\n'),
                  ),
                ),
                if (v.images.isNotEmpty)
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final img in v.images)
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: InkWell(
                              onTap: () => showDialog<void>(
                                context: context,
                                builder: (ctx) => Dialog(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: InteractiveViewer(
                                          child: Image.network(
                                            img.url,
                                            errorBuilder: (_, _, _) =>
                                                const Text(
                                                  'Không tải được ảnh',
                                                ),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Đóng'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              child: Image.network(
                                img.url,
                                width: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox(
                                  width: 180,
                                  child: Center(
                                    child: Text('Không tải được ảnh'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                for (final log in v.history)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${venueApplicationStatus(log.decision)} • ${log.adminName}',
                    ),
                    subtitle: Text(
                      '${log.reason}\n${DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt.toLocal())}',
                    ),
                  ),
              ],
            ),
            if (actions.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}
