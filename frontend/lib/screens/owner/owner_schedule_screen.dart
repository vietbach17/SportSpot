import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/owner_schedule_model.dart';
import '../../data/repositories/owner_schedule_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_header.dart';

class OwnerScheduleScreen extends StatefulWidget {
  final OwnerScheduleRepository? repository;
  const OwnerScheduleScreen({super.key, this.repository});
  @override
  State<OwnerScheduleScreen> createState() => _OwnerScheduleScreenState();
}

class _OwnerScheduleScreenState extends State<OwnerScheduleScreen> {
  late final OwnerScheduleRepository _repo =
      widget.repository ?? OwnerScheduleRepository();
  List<ManagedVenue> _venues = [];
  int? _venueId;
  OwnerSchedule? _data;
  DateTime _date = DateTime.now().toUtc().add(const Duration(hours: 7));
  bool _week = false, _loading = true, _saving = false;
  String? _error;
  int _loadVersion = 0;
  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final venues = await _repo.venues();
      final id = venues.any((v) => v.id == _venueId)
          ? _venueId
          : venues.firstOrNull?.id;
      final data = id == null
          ? null
          : await _repo.schedule(
              id,
              _iso(_date),
              _iso(_date.add(Duration(days: _week ? 6 : 0))),
            );
      if (mounted && version == _loadVersion) {
        setState(() {
          _venues = venues;
          _venueId = id;
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && version == _loadVersion) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _run(Future<void> Function() work) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await work();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật lịch sân')));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null && mounted) {
      _date = d;
      await _load();
    }
  }

  Future<void> _create({ScheduleCourt? court, ScheduleSlot? slot}) async {
    final data = _data;
    if (data == null || data.courts.isEmpty) return;
    var courtId = court?.id ?? data.courts.first.id;
    final selected = <int>{if (slot != null) slot.id};
    var maintenance = false;
    var name = '', phone = '', note = '', paidText = '0';
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) {
          final available = data.slots
              .where(
                (s) =>
                    !data.bookings.any(
                      (b) =>
                          b.subVenueId == courtId &&
                          b.playDate == _iso(_date) &&
                          b.slotIds.contains(s.id),
                    ) &&
                    _dateAt(s.startTime).isAfter(_vietnamNow()),
              )
              .toList();
          final total = maintenance
              ? 0
              : data.slots
                    .where((s) => selected.contains(s.id))
                    .fold<int>(
                      0,
                      (v, s) =>
                          v +
                          (s.isPeak
                              ? data.venue.peakPrice
                              : data.venue.basePrice),
                    );
          return AlertDialog(
            title: const Text('Thêm lịch sân'),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Form(
                  key: form,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ngày ${_iso(_date)}'),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Chặn giờ bảo trì'),
                        value: maintenance,
                        onChanged: (v) => update(() {
                          maintenance = v;
                          paidText = '0';
                        }),
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: courtId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Sân con'),
                        items: data.courts
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  '${c.name}${c.isActive ? '' : ' (đang đóng)'}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => update(() {
                          courtId = v!;
                          selected.clear();
                        }),
                      ),
                      const SizedBox(height: 12),
                      const Text('Chọn các giờ liên tiếp'),
                      Wrap(
                        spacing: 6,
                        children: available
                            .map(
                              (s) => FilterChip(
                                label: Text('${s.startTime}–${s.endTime}'),
                                selected: selected.contains(s.id),
                                onSelected: (v) => update(() {
                                  v
                                      ? selected.add(s.id)
                                      : selected.remove(s.id);
                                }),
                              ),
                            )
                            .toList(),
                      ),
                      if (available.isEmpty)
                        const Text('Không còn giờ trống trong ngày này.'),
                      if (!maintenance) ...[
                        TextFormField(
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Tên khách',
                          ),
                          onChanged: (v) => name = v,
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Nhập tên khách'
                              : null,
                        ),
                        TextFormField(
                          maxLength: 20,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                          ),
                          onChanged: (v) => phone = v,
                          validator: (v) =>
                              RegExp(r'^\+?[0-9]{9,15}$').hasMatch(v ?? '')
                              ? null
                              : 'Nhập số điện thoại hợp lệ',
                        ),
                        TextFormField(
                          key: ValueKey(maintenance),
                          initialValue: '0',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tiền mặt đã thu (đ)',
                          ),
                          onChanged: (v) => paidText = v,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            return n == null || n < 0 || n > total
                                ? 'Nhập số từ 0 đến $total'
                                : null;
                          },
                        ),
                      ],
                      TextFormField(
                        maxLength: 500,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: maintenance ? 'Lý do bảo trì' : 'Ghi chú',
                        ),
                        onChanged: (v) => note = v,
                        validator: (v) =>
                            maintenance && (v?.trim().isEmpty ?? true)
                            ? 'Nhập lý do'
                            : null,
                      ),
                      Text(
                        'Tổng tiền: $total đ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (!maintenance)
                        const Text(
                          'Ghi nhận tiền mặt tại quầy; không tạo giao dịch cọc trực tuyến.',
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        if (form.currentState!.validate()) {
                          Navigator.pop(ctx, true);
                        }
                      },
                child: const Text('Lưu lịch'),
              ),
            ],
          );
        },
      ),
    );
    if (ok == true && mounted) {
      await _run(
        () => _repo.create({
          'subVenueId': courtId,
          'playDate': _iso(_date),
          'slotIds': selected.toList(),
          'maintenance': maintenance,
          'customerName': name.trim(),
          'customerPhone': phone.trim(),
          'note': note.trim(),
          'collectedAmount': maintenance ? 0 : int.parse(paidText),
        }),
      );
    }
  }

  DateTime _vietnamNow() =>
      DateTime.now().toUtc().add(const Duration(hours: 7));
  DateTime _dateAt(String time) {
    final parts = time.split(':');
    return DateTime.utc(
      _date.year,
      _date.month,
      _date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<void> _prices() async {
    final v = _data!.venue;
    var base = '${v.basePrice}', peak = '${v.peakPrice}';
    final form = GlobalKey<FormState>();
    String? validate(String? s) {
      final n = int.tryParse(s ?? '');
      return n == null || n < 1 || n > 10000000
          ? 'Nhập giá từ 1 đến 10.000.000 đ'
          : null;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bảng giá sân'),
        content: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: base,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá giờ thường (đ)',
                  ),
                  validator: validate,
                  onChanged: (s) => base = s,
                ),
                TextFormField(
                  initialValue: peak,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Giá giờ cao điểm (đ)',
                  ),
                  validator: validate,
                  onChanged: (s) => peak = s,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Giá mới áp dụng cho các đơn tạo sau. Đơn đã đặt giữ nguyên giá.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Lưu giá'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _run(() => _repo.prices(v.id, int.parse(base), int.parse(peak)));
    }
  }

  Future<void> _cancel(ScheduleBooking b) async {
    var confirmed = b.collectedAmount == 0;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(
            b.isMaintenance ? 'Mở lại khung giờ?' : 'Hủy lịch tại quầy?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${b.code}\n${b.customerName} • ${b.playDate}'),
              if (b.collectedAmount > 0)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: confirmed,
                  title: Text(
                    'Tôi đã trả lại ${b.collectedAmount} đ tiền mặt cho khách',
                  ),
                  onChanged: (v) => update(() => confirmed = v!),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: confirmed ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && mounted) await _run(() => _repo.cancel(b.id, confirmed));
  }

  Future<void> _collect(ScheduleBooking b) async {
    var amount = '${b.remainingBalance}';
    final form = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ghi nhận thu tiền mặt'),
        content: Form(
          key: form,
          child: TextFormField(
            initialValue: amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Còn thiếu ${b.remainingBalance} đ',
            ),
            onChanged: (v) => amount = v,
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n <= 0 || n > b.remainingBalance
                  ? 'Số tiền không hợp lệ'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Đã nhận tiền'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _run(() => _repo.collect(b.id, int.parse(amount)));
    }
  }

  Future<void> _details(ScheduleBooking b) async {
    final data = _data!;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.isMaintenance ? 'Bảo trì sân' : b.customerName,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                Text(
                  '${b.code}\n${b.customerPhone}\n${b.playDate} • ${data.slots.where((s) => b.slotIds.contains(s.id)).map((s) => '${s.startTime}–${s.endTime}').join(', ')}',
                ),
                if (b.note.isNotEmpty) Text(b.note),
                if (!b.isMaintenance)
                  Text(
                    'Tổng: ${b.totalPrice} đ\nĐã thu/cọc: ${b.collectedAmount} đ\nCòn lại: ${b.remainingBalance} đ',
                  ),
                const SizedBox(height: 16),
                if (b.type == 'WalkIn' &&
                    b.remainingBalance > 0 &&
                    b.status == 'Upcoming')
                  FilledButton(
                    onPressed: _saving
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _collect(b);
                          },
                    child: const Text('Thu tiền mặt'),
                  ),
                if (b.type == 'WalkIn' &&
                    b.remainingBalance == 0 &&
                    b.status == 'Upcoming')
                  FilledButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            Navigator.pop(ctx);
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (dialog) => AlertDialog(
                                title: const Text('Hoàn tất đơn tại quầy?'),
                                content: const Text(
                                  'Xác nhận khách đã thuê sân xong và đã thanh toán đủ. Chỉ hoàn tất được sau giờ kết thúc.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialog),
                                    child: const Text('Quay lại'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(dialog, true),
                                    child: const Text('Hoàn tất'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true && mounted) {
                              await _run(() => _repo.complete(b.id));
                            }
                          },
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Hoàn tất đơn'),
                  ),
                if (b.isManaged && b.status == 'Upcoming')
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _cancel(b);
                          },
                    child: Text(
                      b.isMaintenance ? 'Bỏ chặn giờ' : 'Hủy lịch tại quầy',
                    ),
                  ),
                if (!b.isManaged)
                  const Text(
                    'Đơn đặt qua app. Khách sử dụng luồng hủy vé để áp dụng chính sách hoàn cọc.',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    final data = _data!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 62,
        dataRowMaxHeight: 76,
        columnSpacing: 12,
        columns: [
          const DataColumn(label: Text('Giờ')),
          ...data.courts.map(
            (c) => DataColumn(
              label: SizedBox(
                width: 130,
                child: Text(
                  '${c.name}${c.isActive ? '' : '\nNgừng nhận khách'}',
                ),
              ),
            ),
          ),
        ],
        rows: data.slots
            .map(
              (s) => DataRow(
                cells: [
                  DataCell(Text('${s.startTime}\n${s.endTime}')),
                  ...data.courts.map((c) {
                    final b = data.bookings
                        .where(
                          (b) =>
                              b.subVenueId == c.id &&
                              b.playDate == _iso(_date) &&
                              b.slotIds.contains(s.id),
                        )
                        .firstOrNull;
                    final past = !_dateAt(s.startTime).isAfter(_vietnamNow());
                    final color = b?.isMaintenance == true
                        ? Colors.orange
                        : b != null
                        ? Colors.blue
                        : past || !c.isActive
                        ? Colors.grey
                        : Colors.green;
                    return DataCell(
                      SizedBox(
                        width: 130,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            b == null
                                ? past
                                      ? 'Đã qua giờ'
                                      : !c.isActive
                                      ? 'Sân đang đóng'
                                      : 'Trống • ${s.isPeak ? data.venue.peakPrice : data.venue.basePrice} đ'
                                : b.isMaintenance
                                ? 'Bảo trì\n${b.note}'
                                : '${b.customerName}\n${b.type == 'WalkIn' ? 'Tại quầy' : 'Trên app'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: color.shade700),
                          ),
                        ),
                      ),
                      onTap: _saving
                          ? null
                          : b != null
                          ? () => _details(b)
                          : past
                          ? null
                          : () => _create(court: c, slot: s),
                    );
                  }),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _content() {
    final role = context.watch<AuthProvider>().currentUser?.role;
    final data = _data!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey(_venueId),
          initialValue: _venueId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Cụm sân quản lý'),
          items: _venues
              .map((v) => DropdownMenuItem(value: v.id, child: Text(v.name)))
              .toList(),
          onChanged: _saving
              ? null
              : (v) {
                  _venueId = v;
                  _load();
                },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month),
              label: Text(_iso(_date)),
            ),
            ChoiceChip(
              label: const Text('Ngày'),
              selected: !_week,
              onSelected: (_) {
                _week = false;
                _load();
              },
            ),
            ChoiceChip(
              label: const Text('7 ngày'),
              selected: _week,
              onSelected: (_) {
                _week = true;
                _load();
              },
            ),
            IconButton(
              tooltip: 'Trước',
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                _date = _date.subtract(Duration(days: _week ? 7 : 1));
                _load();
              },
            ),
            IconButton(
              tooltip: 'Sau',
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                _date = _date.add(Duration(days: _week ? 7 : 1));
                _load();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : () => _create(),
              icon: const Icon(Icons.add),
              label: const Text('Đặt tại quầy / Bảo trì'),
            ),
            if (role != 'VenueStaff')
              OutlinedButton.icon(
                onPressed: _saving ? null : _prices,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Bảng giá'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Xanh lá: trống • Xanh dương: đã đặt • Cam: bảo trì\nChạm một ô để xem chi tiết hoặc thêm lịch.',
        ),
        const SizedBox(height: 12),
        if (!_week)
          _grid()
        else ...[
          Text(
            'Lịch từ ${_iso(_date)} đến ${_iso(_date.add(const Duration(days: 6)))}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (data.bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Chưa có lịch trong 7 ngày này.'),
            ),
          ...data.bookings.map(
            (b) => Card(
              child: ListTile(
                leading: Icon(
                  b.isMaintenance
                      ? Icons.build_outlined
                      : Icons.event_available,
                ),
                title: Text(
                  '${b.playDate} • ${data.courts.firstWhere((c) => c.id == b.subVenueId).name}',
                ),
                subtitle: Text(
                  '${b.customerName}\n${data.slots.where((s) => b.slotIds.contains(s.id)).map((s) => s.startTime).join(', ')}',
                ),
                isThreeLine: true,
                onTap: () => _details(b),
              ),
            ),
          ),
        ],
        if (role != 'VenueStaff') ...[
          const SizedBox(height: 24),
          Text(
            'Trạng thái sân con',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...data.courts.map(
            (c) => SwitchListTile(
              title: Text(c.name),
              subtitle: Text(
                c.isActive ? 'Đang nhận khách' : 'Ngừng nhận khách mới',
              ),
              value: c.isActive,
              onChanged: _saving
                  ? null
                  : (v) async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(v ? 'Mở sân?' : 'Tạm dừng sân?'),
                          content: const Text(
                            'Các đơn đã đặt vẫn được giữ. Dùng chặn giờ nếu chỉ bảo trì trong một số khung giờ.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Quay lại'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Xác nhận'),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && mounted) {
                        await _run(() => _repo.toggle(c.id, v));
                      }
                    },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: SportSpotUnifiedHeader(
      screenName: 'Lịch quản lý sân',
      actions: [
        IconButton(
          onPressed: _saving ? null : _load,
          tooltip: 'Tải lại',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: Column(
      children: [
        if (_saving) const LinearProgressIndicator(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _data == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Tài khoản chưa được phân công cụm sân. Nhờ quản trị viên gán sân để quản lý lịch.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(onRefresh: _load, child: _content()),
        ),
      ],
    ),
  );
}
