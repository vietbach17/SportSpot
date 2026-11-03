import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/match_comment_model.dart';
import '../../data/repositories/match_comment_repository.dart';

class MatchDiscussionSheet extends StatefulWidget {
  final int matchId;
  final String matchTitle;
  final IMatchCommentRepository? repository;

  const MatchDiscussionSheet({
    super.key,
    required this.matchId,
    required this.matchTitle,
    this.repository,
  });

  static void show(BuildContext context, {required int matchId, required String matchTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MatchDiscussionSheet(matchId: matchId, matchTitle: matchTitle),
    );
  }

  @override
  State<MatchDiscussionSheet> createState() => _MatchDiscussionSheetState();
}

class _MatchDiscussionSheetState extends State<MatchDiscussionSheet> {
  late final IMatchCommentRepository _repository;
  final List<MatchCommentModel> _comments = [];
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ApiMatchCommentRepository();
    _loadComments();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final list = await _repository.getComments(widget.matchId);
      if (mounted) {
        setState(() {
          _comments.clear();
          _comments.addAll(list);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() => _isSending = true);

    try {
      final comment = await _repository.addComment(widget.matchId, text);
      if (mounted) {
        setState(() {
          _comments.add(comment);
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF0F172A);
    const mutedColor = Color(0xFF64748B);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: 520,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thảo Luận Kèo Đấu',
                      style: TextStyle(
                        fontFamily: AppTheme.headingFont,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.matchTitle,
                      style: const TextStyle(fontSize: 12, color: mutedColor),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: _loadComments,
                  tooltip: 'Làm mới tin nhắn',
                ),
              ],
            ),
            const Divider(height: 16),

            // Comments list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có thảo luận nào. Hãy gửi lời chào đầu tiên!',
                            style: TextStyle(fontSize: 13, color: mutedColor),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            return _buildCommentItem(c, textColor, mutedColor);
                          },
                        ),
            ),
            const Divider(height: 8),

            // Input bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'Nhắn tin thảo luận chiến thuật, vợt, cầu...',
                        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Color(0xFF2563EB)),
                    onPressed: _isSending ? null : _sendComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(MatchCommentModel c, Color textColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: const Color(0xFF2563EB),
            child: Text(
              c.userName.isNotEmpty ? c.userName[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.userName,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      Text(
                        '${c.createdAt.hour.toString().padLeft(2, '0')}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    c.content,
                    style: TextStyle(fontSize: 12.5, color: textColor, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
