class MatchCommentModel {
  final int id;
  final int matchId;
  final int userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final DateTime createdAt;

  const MatchCommentModel({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory MatchCommentModel.fromJson(Map<String, dynamic> json) {
    return MatchCommentModel(
      id: json['id'] as int? ?? 0,
      matchId: json['matchId'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      userName: json['userName'] as String? ?? 'Thành viên',
      userAvatarUrl: json['userAvatarUrl'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
