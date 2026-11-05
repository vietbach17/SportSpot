import 'package:flutter/material.dart';

import '../../data/models/venue_config_models.dart';
import '../../data/repositories/venue_config_repository.dart';
import '../../widgets/venue_application_card.dart';
import 'venue_application_form.dart';

class VenueApplicationsScreen extends StatefulWidget {
  final IVenueConfigRepository? repository;
  final Future<void> Function()? onStatusRefresh;
  const VenueApplicationsScreen({
    super.key,
    this.repository,
    this.onStatusRefresh,
  });
  @override
  State<VenueApplicationsScreen> createState() =>
      _VenueApplicationsScreenState();
}

class _VenueApplicationsScreenState extends State<VenueApplicationsScreen> {
  late final _repo = widget.repository ?? ApiVenueConfigRepository();
  List<VenueApplicationModel> _items = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.getMyApplications();
      if (mounted) setState(() => _items = items);
      await widget.onStatusRefresh?.call();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([VenueApplicationModel? v]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VenueApplicationForm(repository: _repo, application: v),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Hồ sơ đăng ký sân'),
      actions: [
        IconButton(
          tooltip: 'Làm mới hồ sơ',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _loading ? null : () => _edit(),
      icon: const Icon(Icons.add_business),
      label: const Text('Đăng ký sân mới'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Thử lại')),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Sân chỉ nhận đặt lịch sau khi admin phê duyệt. Kéo xuống để cập nhật trạng thái hồ sơ.',
                  ),
                ),
                if (_items.isEmpty)
                  const Text(
                    'Bạn chưa có hồ sơ. Chọn “Đăng ký sân mới” để bắt đầu.',
                  ),
                for (final v in _items)
                  VenueApplicationCard(
                    application: v,
                    actions: [
                      if (v.status == 'Rejected')
                        FilledButton(
                          onPressed: () => _edit(v),
                          child: const Text('Bổ sung và gửi lại'),
                        ),
                    ],
                  ),
              ],
            ),
          ),
  );
}
