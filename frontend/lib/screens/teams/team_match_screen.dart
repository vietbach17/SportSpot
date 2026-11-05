import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/team_model.dart';
import '../../data/repositories/team_repository.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_header.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class TeamMatchScreen extends StatefulWidget {
  final TeamRepository? repository;
  const TeamMatchScreen({super.key, this.repository});
  @override
  State<TeamMatchScreen> createState() => _TeamMatchScreenState();
}

class _TeamMatchScreenState extends State<TeamMatchScreen> {
  late final TeamRepository _repo = widget.repository ?? TeamRepository();
  List<FootballTeam> _teams = [];
  List<TeamChallenge> _challenges = [];
  bool _loading = true, _saving = false, _mine = false;
  String? _error;
  int? _size;
  int _loadVersion = 0;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      final results = await Future.wait([
        _repo.challenges(mine: _mine && auth.isAuthenticated),
        if (auth.isAuthenticated) _repo.myTeams(),
      ]);
      if (!mounted || version != _loadVersion) return;
      setState(() {
        _challenges = results[0].cast<TeamChallenge>();
        _teams = results.length > 1 ? results[1].cast<FootballTeam>() : [];
        _loading = false;
      });
    } catch (e) {
      if (mounted && version == _loadVersion) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<bool> _login() async {
    if (context.read<AuthProvider>().isAuthenticated) return true;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!mounted) return false;
    await _load();
    return mounted && context.read<AuthProvider>().isAuthenticated;
  }

  Future<void> _run(Future<void> Function() work) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await work();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Đã cập nhật kèo đấu')));
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

  Future<void> _createTeam() async {
    if (!await _login() || !mounted) return;
    var name = '';
    final form = GlobalKey<FormState>();
    var size = 7;
    var level = 'Cơ bản';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Tạo đội bóng'),
          content: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    onChanged: (v) => name = v,
                    maxLength: 100,
                    decoration: const InputDecoration(labelText: 'Tên đội'),
                    validator: (v) => (v?.trim().length ?? 0) < 2
                        ? 'Nhập ít nhất 2 ký tự'
                        : null,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: size,
                    decoration: const InputDecoration(labelText: 'Loại sân'),
                    items: [5, 7, 11]
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text('$s người'),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => update(() => size = v!),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: const InputDecoration(labelText: 'Trình độ'),
                    items: ['Cơ bản', 'Trung bình', 'Nâng cao']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => update(() => level = v!),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn sẽ là đội trưởng và đại diện đội gửi, nhận lời mời đối kháng.',
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
              child: const Text('Tạo đội'),
            ),
          ],
        ),
      ),
    );
    final teamName = name.trim();
    if (ok == true && mounted) {
      await _run(() => _repo.createTeam(teamName, size, level));
    }
  }

  Future<void> _openChallenge() async {
    if (!await _login() || !mounted) return;
    if (_teams.isEmpty) {
      await _createTeam();
      return;
    }
    try {
      final bookings = await _repo.bookings(
        context.read<AuthProvider>().currentUser!.id,
      );
      if (!mounted) return;
      final used = _challenges
          .where((c) => c.status != 'Cancelled')
          .map((c) => c.bookingId)
          .toSet();
      bookings.removeWhere((b) => used.contains(b['bookingId']));
      if (bookings.isEmpty) {
        final book = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cần có sân trước khi mở kèo'),
            content: const Text(
              'Đặt một sân bóng, sau đó quay lại để tìm đội đối kháng. Đơn sân phải sắp diễn ra và chưa mở tuyển người lẻ.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tìm sân'),
              ),
            ],
          ),
        );
        if (book == true && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
          if (mounted) await _load();
        }
        return;
      }
      var teamId = _teams.first.id;
      var bookingId = bookings.first['bookingId'] as int;
      var note = '';
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Mở tìm đối thủ'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: teamId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Đội của bạn'),
                  items: _teams
                      .map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => teamId = v!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: bookingId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Đơn đặt sân'),
                  items: bookings
                      .map(
                        (b) => DropdownMenuItem(
                          value: b['bookingId'] as int,
                          child: Text(
                            '${b['venueName']} • ${b['playDate']} • ${(b['timeSlots'] as List).join(', ')}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => bookingId = v!,
                ),
                TextField(
                  maxLength: 500,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Lời nhắn, luật giao hữu',
                  ),
                  onChanged: (v) => note = v,
                ),
                const Text(
                  'Mỗi đội chia 50% tiền sân. Tiền đối thủ được hai đội thanh toán trực tiếp; app chưa thu khoản này.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mở kèo'),
            ),
          ],
        ),
      );
      if (ok == true && mounted) {
        await _run(() => _repo.open(teamId, bookingId, note));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _apply(TeamChallenge c) async {
    if (!await _login() || !mounted) return;
    final eligible = _teams
        .where((t) => t.teamSize == c.team.teamSize)
        .toList();
    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tạo đội ${c.team.teamSize} người để gửi lời mời.'),
        ),
      );
      await _createTeam();
      return;
    }
    var teamId = eligible.first.id;
    var message = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Giao hữu với ${c.team.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${c.playDate} • ${c.timeSlots.join(', ')}\nPhần tiền sân đội bạn: ${c.opponentCourtShare} đ (thanh toán trực tiếp).',
              ),
              DropdownButtonFormField<int>(
                initialValue: teamId,
                isExpanded: true,
                items: eligible
                    .map(
                      (t) => DropdownMenuItem(value: t.id, child: Text(t.name)),
                    )
                    .toList(),
                onChanged: (v) => teamId = v!,
              ),
              TextField(
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Lời nhắn cho đội trưởng',
                ),
                onChanged: (v) => message = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gửi lời mời'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await _run(() => _repo.apply(c.id, teamId, message));
    }
  }

  Future<void> _confirm(
    TeamChallenge c,
    String action, {
    int? requestId,
  }) async {
    final text = switch (action) {
      'accept' =>
        'Xác nhận chọn đội này làm đối thủ? Các lời mời khác sẽ bị từ chối.',
      'reject' => 'Từ chối lời mời này?',
      'withdraw' => 'Rút lời mời? Nếu đã ghép, kèo sẽ mở tìm đối thủ trở lại.',
      _ => 'Đóng kèo đối kháng? Đơn đặt sân vẫn được giữ nguyên.',
    };
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(text),
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
      await _run(() => _repo.action(c.id, action, requestId: requestId));
    }
  }

  static String _label(String s) => switch (s) {
    'Open' => 'Đang tìm đối thủ',
    'Matched' => 'Đã ghép đội',
    'Cancelled' => 'Đã đóng',
    'Expired' => 'Đã qua giờ',
    'Pending' => 'Chờ duyệt',
    'Accepted' => 'Đã nhận',
    'Rejected' => 'Đã từ chối',
    'Withdrawn' => 'Đã rút',
    _ => s,
  };

  Widget _card(TeamChallenge c) {
    final uid = context.read<AuthProvider>().currentUser?.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.team.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              '${c.team.teamSize} người • ${c.team.skillLevel} • ${_label(c.status)}',
            ),
            const Divider(),
            Text('${c.venueName} • ${c.subVenueName}'),
            Text('${c.district}\n${c.playDate} • ${c.timeSlots.join(', ')}'),
            Text(
              'Chia tiền sân: ${c.opponentCourtShare} đ/đội',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (c.contactPhone != null)
              SelectableText('Liên hệ đội trưởng đối thủ: ${c.contactPhone}'),
            if (c.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(c.note),
              ),
            for (final r in c.requests) ...[
              const Divider(),
              Text(
                '${r.team.name} • ${_label(r.status)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (r.message.isNotEmpty) Text(r.message),
              if (c.status == 'Open' && c.isHost && r.status == 'Pending')
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _saving
                          ? null
                          : () => _confirm(c, 'accept', requestId: r.id),
                      child: const Text('Chọn đội'),
                    ),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => _confirm(c, 'reject', requestId: r.id),
                      child: const Text('Từ chối'),
                    ),
                  ],
                ),
              if (r.team.captainUserId == uid &&
                  ['Pending', 'Accepted'].contains(r.status) &&
                  ['Open', 'Matched'].contains(c.status))
                TextButton(
                  onPressed: _saving
                      ? null
                      : () => _confirm(c, 'withdraw', requestId: r.id),
                  child: const Text('Rút lời mời'),
                ),
            ],
            const SizedBox(height: 8),
            if (c.isHost && ['Open', 'Matched'].contains(c.status))
              OutlinedButton(
                onPressed: _saving ? null : () => _confirm(c, 'cancel'),
                child: const Text('Đóng kèo đối kháng'),
              ),
            if (!c.isHost && c.status == 'Open' && c.team.captainUserId != uid)
              FilledButton.icon(
                onPressed: _saving ? null : () => _apply(c),
                icon: const Icon(Icons.handshake_outlined),
                label: const Text('Gửi lời mời giao hữu'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = _challenges
        .where(
          (c) =>
              (_size == null || c.team.teamSize == _size) &&
              '${c.team.name} ${c.venueName} ${c.district}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return Scaffold(
      appBar: SportSpotUnifiedHeader(
        screenName: 'Ghép đội bóng',
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _saving ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_saving) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _createTeam,
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Tạo đội'),
                    ),
                    FilledButton.icon(
                      onPressed: _saving ? null : _openChallenge,
                      icon: const Icon(Icons.add),
                      label: const Text('Tìm đối thủ'),
                    ),
                  ],
                ),
                if (_teams.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Đội của bạn: ${_teams.map((t) => '${t.name} (${t.teamSize})').join(', ')}',
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Tên đội, sân, khu vực',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tất cả'),
                      selected: !_mine,
                      onSelected: _saving
                          ? null
                          : (_) {
                              _mine = false;
                              _load();
                            },
                    ),
                    ChoiceChip(
                      label: const Text('Kèo của tôi'),
                      selected: _mine,
                      onSelected: _saving
                          ? null
                          : (_) async {
                              if (await _login() && mounted) {
                                _mine = true;
                                _load();
                              }
                            },
                    ),
                    DropdownButton<int>(
                      value: _size,
                      hint: const Text('Loại sân'),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Mọi loại sân'),
                        ),
                        ...[5, 7, 11].map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text('$s người'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _size = v),
                    ),
                  ],
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
                        Text(_error!, textAlign: TextAlign.center),
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Chưa có kèo phù hợp. Tạo đội và mở tìm đối thủ!',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ...filtered.map(_card),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
