import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_client.dart';
import '../../data/models/venue_config_models.dart';
import '../../data/repositories/venue_config_repository.dart';

class VenueApplicationForm extends StatefulWidget {
  final IVenueConfigRepository repository;
  final VenueApplicationModel? application;
  const VenueApplicationForm({
    super.key,
    required this.repository,
    this.application,
  });
  @override
  State<VenueApplicationForm> createState() => _VenueApplicationFormState();
}

class _VenueApplicationFormState extends State<VenueApplicationForm> {
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fields = {};
  final List<String> _courtNameCache = [];
  List<Map<String, dynamic>> _sports = [];
  List<VenueSlotConfigItemModel> _slots = [];
  List<UploadedVenueImageModel> _images = [], _unused = [];
  int? _sportId;
  int _deposit = 30;
  bool _loading = true, _saving = false, _uploading = false, _stale = false;
  String? _error;
  TextEditingController f(String key) => _fields[key]!;

  @override
  void initState() {
    super.initState();
    final v = widget.application;
    final values = <String, String>{
      'name': v?.name ?? '',
      'address': v?.address ?? '',
      'district': v?.district ?? '',
      'hotline': v?.hotline ?? '',
      'mapsLink': v == null
          ? ''
          : 'https://www.google.com/maps?q=${v.latitude},${v.longitude}',
      'imageLink': '',
      'basePrice': '${v?.basePrice ?? 100000}',
      'peakPrice': '${v?.peakPrice ?? 150000}',
      'maxSlotsPerBooking': '${v?.maxSlotsPerBooking ?? 3}',
      'description': v?.description ?? '',
      'amenities': v?.amenities ?? '',
      'courts': v?.courtNames.join('\n') ?? 'Sân 1',
      'courtCount': '${v?.courtNames.length ?? 1}',
    };
    for (final entry in values.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
    _courtNameCache.addAll(_courtNames());
    _sportId = v?.sportId;
    _deposit = v?.minDepositPercent ?? 30;
    _images = [...?v?.images];
    _load();
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sports = await widget.repository.getSports();
      final slots = await widget.repository.getSlotTemplates();
      final unused = await widget.repository.getUnusedImages();
      if (!mounted) return;
      setState(() {
        _sports = sports;
        _sportId ??= sports.isEmpty
            ? null
            : (sports.first['id'] as num).toInt();
        final existing = {
          for (final s
              in widget.application?.slotConfigs ??
                  <VenueSlotConfigItemModel>[])
            s.slotId: s,
        };
        _slots = slots.map((s) => existing[s.slotId] ?? s).toList();
        _unused = [...unused, ...?widget.application?.images];
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      if (await file.length() > 8 * 1024 * 1024) {
        if (mounted) _message('Ảnh tối đa 8 MB');
        return;
      }
      final image = await widget.repository.uploadVenueImage(
        await file.readAsBytes(),
        file.name,
      );
      if (mounted) {
        setState(() {
          _images.add(image);
          _unused.add(image);
        });
      }
    } catch (e) {
      if (mounted) _message('$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      _message('Kiểm tra các trường được đánh dấu trong hồ sơ');
      return;
    }
    if (_sportId == null) {
      _message('Chọn môn thể thao');
      return;
    }
    if (_images.isEmpty) {
      _message('Cần ít nhất 1 ảnh sân');
      return;
    }
    if (!_slots.any((s) => s.isActive)) {
      _message('Chọn ít nhất 1 khung giờ hoạt động');
      return;
    }
    setState(() => _saving = true);
    try {
      final location = await widget.repository.resolveVenueMapsLink(
        f('mapsLink').text.trim(),
      );
      await widget.repository.submitVenueApplication({
        for (final key in [
          'name',
          'address',
          'district',
          'hotline',
          'description',
          'amenities',
        ])
          key: f(key).text.trim(),
        'sportId': _sportId,
        'latitude': location['latitude'],
        'longitude': location['longitude'],
        for (final key in ['basePrice', 'peakPrice', 'maxSlotsPerBooking'])
          key: int.parse(f(key).text.trim()),
        'minDepositPercent': _deposit, 'courtNames': _courtNames(),
        'imageIds': _images.map((i) => i.id).toList(),
        'slotConfigs': _slots.map((s) => s.toInputJson()).toList(),
        // Keep existing auxiliary services when resubmitting a rejected application.
        'services':
            widget.application?.services.map((s) => s.toJson()).toList() ?? [],
        'revision': widget.application?.revision ?? 0,
      }, id: widget.application?.id);
      if (!mounted) return;
      _message('Đã gửi hồ sơ, vui lòng chờ admin duyệt');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException &&
          e.statusCode == 409 &&
          widget.application != null) {
        setState(() => _stale = true);
      }
      _message('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _courtNames() =>
      f('courts').text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

  void _rememberCourtNames() {
    final names = _courtNames();
    for (var i = 0; i < names.length; i++) {
      if (i < _courtNameCache.length) {
        _courtNameCache[i] = names[i];
      } else {
        _courtNameCache.add(names[i]);
      }
    }
  }

  void _resizeCourts(String value) {
    final count = int.tryParse(value.trim());
    if (count == null || count < 1 || count > 20) return;
    _rememberCourtNames();
    while (_courtNameCache.length < count) {
      var number = _courtNameCache.length + 1;
      while (_courtNameCache.any((n) => n.toLowerCase() == 'sân $number')) {
        number++;
      }
      _courtNameCache.add('Sân $number');
    }
    f('courts').text = _courtNameCache.take(count).join('\n');
  }

  Future<void> _addImageLink() async {
    final url = f('imageLink').text.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      _message('Dán link HTTPS trực tiếp đến ảnh công khai');
      return;
    }
    if (_images.any((i) => i.url == url)) {
      _message('Ảnh này đã được thêm');
      return;
    }
    setState(() => _uploading = true);
    try {
      final image = await widget.repository.addVenueImageLink(url);
      if (!mounted) return;
      setState(() {
        _images.add(image);
        _unused.add(image);
        f('imageLink').clear();
      });
    } catch (e) {
      if (mounted) _message('$e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _text(
    String key,
    String label, {
    int? maxLength,
    int min = 1,
    int lines = 1,
    bool optional = false,
    double? lower,
    double? upper,
    bool integer = false,
    ValueChanged<String>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      key: ValueKey(key),
      controller: f(key),
      onChanged: onChanged,
      maxLength: maxLength,
      maxLines: lines,
      keyboardType: lower != null
          ? TextInputType.numberWithOptions(
              decimal: !integer,
              signed: lower < 0,
            )
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (raw) {
        final s = raw?.trim() ?? '';
        if (!optional && s.length < min) return 'Nhập ít nhất $min ký tự';
        if (key == 'hotline' && !RegExp(r'^\+?[0-9]{9,15}$').hasMatch(s)) {
          return 'Nhập SĐT gồm 9–15 chữ số';
        }
        if (lower != null) {
          final n = integer ? int.tryParse(s) : double.tryParse(s);
          if (n == null || !n.isFinite || n < lower || n > upper!) {
            return 'Giá trị từ $lower đến $upper';
          }
        }
        if (key == 'courts') {
          final names = _courtNames();
          if (names.isEmpty ||
              names.length > 20 ||
              names.any((n) => n.length > 50)) {
            return 'Nhập 1–20 sân, mỗi tên tối đa 50 ký tự';
          }
          if (names.map((n) => n.toLowerCase()).toSet().length !=
              names.length) {
            return 'Tên sân con không được trùng';
          }
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving && !_uploading,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.application == null ? 'Đăng ký sân mới' : 'Bổ sung hồ sơ',
        ),
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
          : AbsorbPointer(
              absorbing: _saving || _uploading,
              child: Form(
                key: _form,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.application?.rejectionReason != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'Cần bổ sung: ${widget.application!.rejectionReason}',
                          ),
                        ),
                      _text('name', 'Tên cụm sân', min: 3, maxLength: 150),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<int>(
                          initialValue: _sports.any((s) => s['id'] == _sportId)
                              ? _sportId
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Môn thể thao',
                            border: OutlineInputBorder(),
                          ),
                          items: _sports
                              .map(
                                (s) => DropdownMenuItem(
                                  value: (s['id'] as num).toInt(),
                                  child: Text('${s['name']}'),
                                ),
                              )
                              .toList(),
                          validator: (v) =>
                              v == null ? 'Chọn môn thể thao' : null,
                          onChanged: (v) => setState(() => _sportId = v),
                        ),
                      ),
                      _text('address', 'Địa chỉ', min: 5, maxLength: 255),
                      _text('district', 'Quận / huyện', maxLength: 100),
                      _text('hotline', 'Hotline', maxLength: 16),
                      _text(
                        'mapsLink',
                        'Link Google Maps của sân',
                        maxLength: 8000,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: Text(
                          'Mở địa điểm sân trên Google Maps → Chia sẻ → Sao chép liên kết. Hệ thống tự lấy tọa độ.',
                        ),
                      ),
                      _text(
                        'basePrice',
                        'Giá thường (đ/giờ)',
                        lower: 1000,
                        upper: 10000000,
                        integer: true,
                      ),
                      _text(
                        'peakPrice',
                        'Giá cao điểm (đ/giờ)',
                        lower: 1000,
                        upper: 10000000,
                        integer: true,
                      ),
                      _text(
                        'maxSlotsPerBooking',
                        'Số slot tối đa mỗi đơn',
                        lower: 1,
                        upper: 12,
                        integer: true,
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: _deposit,
                        decoration: const InputDecoration(
                          labelText: 'Cọc tối thiểu',
                        ),
                        items: [
                          for (final p in [30, 50, 100])
                            DropdownMenuItem(value: p, child: Text('$p%')),
                        ],
                        onChanged: (p) => setState(() => _deposit = p!),
                      ),
                      const SizedBox(height: 16),
                      _text(
                        'courtCount',
                        'Số lượng sân con',
                        lower: 1,
                        upper: 20,
                        integer: true,
                        onChanged: _resizeCourts,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 14),
                        child: Text(
                          'Tự tạo tên theo số lượng sân con (1–20 sân). Bạn có thể chỉnh tên từng sân bên dưới.',
                        ),
                      ),
                      _text(
                        'courts',
                        'Tên sân con (mỗi dòng một sân)',
                        lines: 4,
                        onChanged: (_) {
                          _rememberCourtNames();
                          f('courtCount').text = '${_courtNames().length}';
                        },
                      ),
                      _text(
                        'description',
                        'Mô tả',
                        optional: true,
                        maxLength: 3000,
                        lines: 3,
                      ),
                      _text(
                        'amenities',
                        'Tiện ích',
                        optional: true,
                        maxLength: 1000,
                        lines: 2,
                      ),
                      const Text(
                        'Ảnh sân (1–8 ảnh). Tải ảnh từ thiết bị hoặc dán link ảnh công khai. Ảnh đầu tiên là ảnh đại diện.',
                      ),
                      if (_images.length < 8) ...[
                        const SizedBox(height: 12),
                        _text(
                          'imageLink',
                          'Link ảnh (https://...)',
                          optional: true,
                          maxLength: 1000,
                        ),
                        OutlinedButton.icon(
                          onPressed: _addImageLink,
                          icon: const Icon(Icons.link),
                          label: const Text('Thêm ảnh bằng link'),
                        ),
                        const Text(
                          'Dùng link trực tiếp đến ảnh, không dùng link trang web hoặc link Google Drive cần đăng nhập.',
                        ),
                      ],
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final image in _images)
                            SizedBox(
                              width: 120,
                              child: Column(
                                children: [
                                  Image.network(
                                    image.url,
                                    height: 90,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const SizedBox(
                                      height: 90,
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _images.remove(image)),
                                    child: const Text('Bỏ ảnh'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      if (_images.length < 8)
                        OutlinedButton.icon(
                          onPressed: _upload,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: Text(
                            _uploading
                                ? 'Đang tải ảnh…'
                                : 'Tải ảnh từ thiết bị',
                          ),
                        ),
                      if (_unused.any((i) => !_images.any((s) => s.id == i.id)))
                        ExpansionTile(
                          title: const Text('Ảnh đã tải chưa sử dụng'),
                          children: [
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final image in _unused.where(
                                  (i) => !_images.any((s) => s.id == i.id),
                                ))
                                  InkWell(
                                    onTap: () {
                                      if (_images.length < 8) {
                                        setState(() => _images.add(image));
                                      }
                                    },
                                    child: Image.network(
                                      image.url,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const SizedBox(
                                        width: 90,
                                        height: 90,
                                        child: Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        initiallyExpanded: true,
                        title: const Text('Khung giờ hoạt động'),
                        subtitle: const Text(
                          'Bật giờ mở cửa; đánh dấu giờ cao điểm',
                        ),
                        children: [
                          for (var i = 0; i < _slots.length; i++)
                            SwitchListTile(
                              title: Text(
                                '${_slots[i].startTime}–${_slots[i].endTime}',
                              ),
                              subtitle: Row(
                                children: [
                                  Checkbox(
                                    value: _slots[i].isPeak,
                                    onChanged: (v) => setState(
                                      () => _slots[i] = _slots[i].copyWith(
                                        isPeak: v,
                                      ),
                                    ),
                                  ),
                                  const Flexible(child: Text('Giờ cao điểm')),
                                ],
                              ),
                              value: _slots[i].isActive,
                              onChanged: (v) => setState(
                                () =>
                                    _slots[i] = _slots[i].copyWith(isActive: v),
                              ),
                            ),
                        ],
                      ),
                      if (_stale)
                        const Text(
                          'Hồ sơ đã thay đổi. Quay lại danh sách và làm mới trước khi gửi lại.',
                        ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _stale ? null : _submit,
                        child: Text(
                          _saving ? 'Đang gửi…' : 'Gửi hồ sơ chờ duyệt',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    ),
  );
}
