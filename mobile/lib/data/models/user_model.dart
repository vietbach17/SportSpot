class UserModel {
  final int userId;
  String fullName;
  final String phoneNumber;
  String? email;
  final String role;
  int walletBalance;
  String? avatarUrl;
  bool isFindMatchEnabled;
  String? favoriteSports;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.role,
    this.walletBalance = 0,
    this.avatarUrl,
    this.isFindMatchEnabled = false,
    this.favoriteSports = 'Cầu lông,Bóng đá mini',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'Player',
      walletBalance: json['walletBalance'] ?? 0,
      avatarUrl: json['avatarUrl'],
      isFindMatchEnabled: json['isFindMatchEnabled'] ?? false,
      favoriteSports: json['favoriteSports'] ?? 'Cầu lông,Bóng đá mini',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'role': role,
      'walletBalance': walletBalance,
      'avatarUrl': avatarUrl,
      'isFindMatchEnabled': isFindMatchEnabled,
      'favoriteSports': favoriteSports,
    };
  }

  List<String> get favoriteSportsList {
    if (favoriteSports == null || favoriteSports!.isEmpty) return [];
    return favoriteSports!.split(',').map((e) => e.trim()).toList();
  }
}
