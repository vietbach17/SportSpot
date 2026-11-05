import 'package:flutter/material.dart';

import '../data/repositories/review_repository.dart';

class VenueReviewSheet extends StatefulWidget {
  final int venueId;
  final String venueName;
  final IReviewRepository repository;

  const VenueReviewSheet({
    super.key,
    required this.venueId,
    required this.venueName,
    required this.repository,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int venueId,
    required String venueName,
    required IReviewRepository repository,
  }) => showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => VenueReviewSheet(
      venueId: venueId,
      venueName: venueName,
      repository: repository,
    ),
  );

  @override
  State<VenueReviewSheet> createState() => _VenueReviewSheetState();
}

class _VenueReviewSheetState extends State<VenueReviewSheet> {
  final _formKey = GlobalKey<FormState>();
  final _comment = TextEditingController();
  int _rating = 5;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.repository.submitReview(
        widget.venueId,
        _rating,
        _comment.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error =
              'Chưa gửi được đánh giá. Vui lòng kiểm tra kết nối và thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_submitting,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đánh giá & Nhận xét sân',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(widget.venueName),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Flexible(
                  child: IconButton(
                    key: Key('review_star_${index + 1}'),
                    tooltip: '${index + 1} sao',
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _rating = index + 1),
                    icon: Icon(
                      index < _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            Center(child: Text('$_rating/5 sao')),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('review_comment'),
              controller: _comment,
              enabled: !_submitting,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Nhận xét của bạn',
                hintText: 'Chia sẻ trải nghiệm về sân và dịch vụ...',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập nội dung nhận xét'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('submit_venue_review'),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gửi đánh giá'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
