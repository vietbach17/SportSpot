import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../data/models/venue_config_models.dart';
import '../../data/repositories/venue_config_repository.dart';
import '../../widgets/venue_application_card.dart';

class VenueModerationScreen extends StatefulWidget {
  final IVenueConfigRepository? repository;
  const VenueModerationScreen({super.key, this.repository});
  @override
  State<VenueModerationScreen> createState() => _VenueModerationScreenState();
}

class _VenueModerationScreenState extends State<VenueModerationScreen> {
  late final _repo = widget.repository ?? ApiVenueConfigRepository();
  List<VenueApplicationModel> _items = [];
  String? _error;
  bool _loading = true;
  int? _busy;
  String _filter = 'Pending';

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
      final items = await _repo.getAdminVenues();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(VenueApplicationModel v, bool approve) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ReviewDialog(approve: approve, name: v.name),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = v.id);
    try {
      final updated = await _repo.reviewVenue(
        v.id,
        approve: approve,
        revision: v.revision,
        reason: reason,
      );
      if (!mounted) return;
      setState(
        () => _items = _items
            .map((item) => item.id == v.id ? updated : item)
            .toList(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            approve
                ? 'Đã duyệt sân và kích hoạt quyền chủ sân'
                : 'Đã từ chối và gửi lý do cho chủ sân',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      if (e is ApiException && e.statusCode == 409) await _load();
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items
        .where((v) => _filter == 'All' || v.status == _filter)
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái hồ sơ',
                  ),
                  items: [
                    for (final s in ['Pending', 'Approved', 'Rejected', 'All'])
                      DropdownMenuItem(
                        value: s,
                        child: Text(
                          s == 'All' ? 'Tất cả' : venueApplicationStatus(s),
                        ),
                      ),
                  ],
                  onChanged: _busy != null
                      ? null
                      : (s) => setState(() => _filter = s!),
                ),
              ),
              IconButton(
                tooltip: 'Làm mới hồ sơ',
                onPressed: _loading || _busy != null ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Không có hồ sơ ở trạng thái này'),
                        ),
                      for (final v in items)
                        VenueApplicationCard(
                          application: v,
                          actions: v.status != 'Pending'
                              ? []
                              : [
                                  OutlinedButton(
                                    onPressed: _busy != null
                                        ? null
                                        : () => _review(v, false),
                                    child: const Text('Từ chối'),
                                  ),
                                  FilledButton(
                                    onPressed: _busy != null
                                        ? null
                                        : () => _review(v, true),
                                    child: Text(
                                      _busy == v.id
                                          ? 'Đang xử lý…'
                                          : 'Phê duyệt',
                                    ),
                                  ),
                                ],
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final bool approve;
  final String name;
  const _ReviewDialog({required this.approve, required this.name});
  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.approve ? 'Phê duyệt ${widget.name}?' : 'Từ chối ${widget.name}',
    ),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _reason,
        maxLength: 1000,
        minLines: 2,
        maxLines: 5,
        decoration: InputDecoration(
          labelText: widget.approve
              ? 'Ghi chú (không bắt buộc)'
              : 'Lý do từ chối',
        ),
        validator: (s) => !widget.approve && (s == null || s.trim().isEmpty)
            ? 'Nhập lý do để chủ sân bổ sung hồ sơ'
            : null,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, _reason.text.trim());
          }
        },
        child: const Text('Xác nhận'),
      ),
    ],
  );
}
