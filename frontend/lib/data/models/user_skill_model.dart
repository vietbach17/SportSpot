class UserSkillModel {
  final int id;
  final int userId;
  final int sportId;
  final String sportName;
  final String skillLevel;
  final double ratingScore;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? updatedAt;

  UserSkillModel({
    required this.id,
    required this.userId,
    required this.sportId,
    required this.sportName,
    required this.skillLevel,
    required this.ratingScore,
    this.isVerified = false,
    this.verifiedBy,
    this.updatedAt,
  });

  factory UserSkillModel.fromJson(Map<String, dynamic> json) {
    return UserSkillModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      sportId: json['sportId'] ?? 0,
      sportName: json['sportName'] ?? '',
      skillLevel: json['skillLevel'] ?? 'Phong trào',
      ratingScore: (json['ratingScore'] is num)
          ? (json['ratingScore'] as num).toDouble()
          : double.tryParse(json['ratingScore']?.toString() ?? '3.5') ?? 3.5,
      isVerified: json['isVerified'] ?? false,
      verifiedBy: json['verifiedBy'],
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sportId': sportId,
      'sportName': sportName,
      'skillLevel': skillLevel,
      'ratingScore': ratingScore,
    };
  }
}
