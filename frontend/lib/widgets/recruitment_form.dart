import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'match_ui.dart';

String money(int amount) =>
    '${NumberFormat.decimalPattern('vi_VN').format(amount)} đ';

class RecruitmentValue {
  final bool enabled;
  final int total, needed;
  final String skill;
  const RecruitmentValue({
    this.enabled = false,
    this.total = 10,
    this.needed = 4,
    this.skill = 'Cơ bản',
  });
  bool get valid => !enabled || (total > 1 && needed > 0 && needed < total);
  Map<String, dynamic> toJson() => {
    'isOpenMatch': enabled,
    if (enabled) ...{
      'totalExpectedPlayers': total,
      'neededPlayers': needed,
      'skillLevel': skill,
    },
  };
}

/// Embed inside the booking Form; courtPrice excludes accessory/service charges.
class RecruitmentForm extends StatefulWidget {
  final int courtPrice;
  final ValueChanged<RecruitmentValue> onChanged;
  const RecruitmentForm({
    super.key,
    required this.courtPrice,
    required this.onChanged,
  });
  @override
  State<RecruitmentForm> createState() => _RecruitmentFormState();
}

class _RecruitmentFormState extends State<RecruitmentForm> {
  bool enabled = false;
  int total = 10, needed = 4;
  String skill = 'Cơ bản';
  void emit() => widget.onChanged(
    RecruitmentValue(
      enabled: enabled,
      total: total,
      needed: needed,
      skill: skill,
    ),
  );

  Widget totalField() => TextFormField(
    initialValue: '$total',
    decoration: const InputDecoration(
      labelText: 'Tổng số người dự kiến',
      prefixIcon: Icon(Icons.groups_outlined, size: 20),
    ),
    keyboardType: TextInputType.number,
    validator: (v) => enabled && (int.tryParse(v ?? '') ?? 0) <= 1
        ? 'Tổng số người phải lớn hơn 1'
        : null,
    onChanged: (v) {
      setState(() => total = int.tryParse(v) ?? 0);
      emit();
    },
  );
  Widget neededField() => TextFormField(
    initialValue: '$needed',
    decoration: const InputDecoration(
      labelText: 'Số vãng lai cần tuyển',
      prefixIcon: Icon(Icons.person_add_alt_rounded, size: 20),
    ),
    keyboardType: TextInputType.number,
    validator: (v) {
      final n = int.tryParse(v ?? '') ?? 0;
      return enabled && (n <= 0 || n >= total)
          ? 'Phải lớn hơn 0 và nhỏ hơn tổng số người'
          : null;
    },
    onChanged: (v) {
      setState(() => needed = int.tryParse(v) ?? 0);
      emit();
    },
  );

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: enabled
            ? MatchColors.blue.withValues(alpha: .35)
            : MatchColors.line,
        width: 1.2,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: CheckboxListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
            activeColor: MatchColors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF3FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.group_add_outlined,
                color: MatchColors.blue,
                size: 24,
              ),
            ),
            title: const Text(
              'Tuyển vãng lai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: MatchColors.ink,
              ),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Thêm đồng đội, chia sẻ tiền sân.',
                style: TextStyle(fontSize: 12, color: MatchColors.muted),
              ),
            ),
            value: enabled,
            onChanged: (v) {
              setState(() => enabled = v!);
              emit();
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !enabled
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: MatchColors.line, height: 25),
                      LayoutBuilder(
                        builder: (context, constraints) =>
                            constraints.maxWidth >= 430
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: totalField()),
                                  const SizedBox(width: 12),
                                  Expanded(child: neededField()),
                                ],
                              )
                            : Column(
                                children: [
                                  totalField(),
                                  const SizedBox(height: 14),
                                  neededField(),
                                ],
                              ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: skill,
                        decoration: const InputDecoration(
                          labelText: 'Trình độ đồng đội',
                          prefixIcon: Icon(Icons.bar_chart_rounded, size: 21),
                        ),
                        items: ['Cơ bản', 'Trung bình']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => skill = v!);
                          emit();
                        },
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF8D9),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 16,
                                  color: Color(0xFF456B19),
                                ),
                                SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'MỖI VÃNG LAI ĐÓNG',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1,
                                      color: Color(0xFF456B19),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text(
                              total > 1
                                  ? money((widget.courtPrice / total).round())
                                  : '—',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: MatchColors.navy,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              total > 1
                                  ? '${money(widget.courtPrice)} tiền sân ÷ $total người'
                                  : 'Nhập tổng số người hợp lệ',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF456B19),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 15,
                            color: MatchColors.muted,
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Giá chia tự động, không gồm phụ kiện và không thể tự sửa.',
                              style: TextStyle(
                                color: MatchColors.muted,
                                fontSize: 11,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}
