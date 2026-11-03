import '../../core/network/api_client.dart';
import '../models/match_comment_model.dart';

abstract class IMatchCommentRepository {
  Future<List<MatchCommentModel>> getComments(int matchId);
  Future<MatchCommentModel> addComment(int matchId, String content);
}

class MockMatchCommentRepository implements IMatchCommentRepository {
  final Map<int, List<MatchCommentModel>> _comments = {
    1: [
      MatchCommentModel(
        id: 1,
        matchId: 1,
        userId: 1,
        userName: 'Host Minh',
        content: 'Anh em nhớ mang giày đế kếp sân thảm để bảo vệ sân nhé!',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      MatchCommentModel(
        id: 2,
        matchId: 1,
        userId: 2,
        userName: 'Thành viên Hùng',
        content: 'Mình mang theo ống cầu Victor Gold, lát chia nhau test nhé!',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
  };

  @override
  Future<List<MatchCommentModel>> getComments(int matchId) async {
    return List.from(_comments[matchId] ?? _comments[1] ?? []);
  }

  @override
  Future<MatchCommentModel> addComment(int matchId, String content) async {
    final newComment = MatchCommentModel(
      id: DateTime.now().millisecondsSinceEpoch % 10000,
      matchId: matchId,
      userId: 99,
      userName: 'Bạn',
      content: content,
      createdAt: DateTime.now(),
    );

    if (!_comments.containsKey(matchId)) {
      _comments[matchId] = [];
    }
    _comments[matchId]!.add(newComment);
    return newComment;
  }
}

class ApiMatchCommentRepository implements IMatchCommentRepository {
  final ApiClient _client;
  final MockMatchCommentRepository _fallback = MockMatchCommentRepository();

  ApiMatchCommentRepository({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<List<MatchCommentModel>> getComments(int matchId) async {
    try {
      final response = await _client.get('/api/matches/$matchId/comments', requiresAuth: false);
      if (response is List) {
        return response
            .map((e) => MatchCommentModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return await _fallback.getComments(matchId);
    } catch (_) {
      return await _fallback.getComments(matchId);
    }
  }

  @override
  Future<MatchCommentModel> addComment(int matchId, String content) async {
    try {
      final response = await _client.post('/api/matches/$matchId/comments', {
        'content': content,
      });
      if (response is Map<String, dynamic>) {
        return MatchCommentModel.fromJson(response);
      }
      return await _fallback.addComment(matchId, content);
    } catch (_) {
      return await _fallback.addComment(matchId, content);
    }
  }
}
