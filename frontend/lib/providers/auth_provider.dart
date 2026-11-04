import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../data/models/user_model.dart';
import '../data/services/database_helper.dart';
import '../data/services/token_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  UserModel? _currentUser;
  bool _isGuest = true;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => !_isGuest && _currentUser != null;
  String? get errorMessage => _errorMessage;

  /// Khởi tạo phiên khi mở ứng dụng: Đọc token và session
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await TokenService.getToken();
      if (token != null && token.isNotEmpty) {
        // Thử lấy profile từ Backend
        try {
          final data = await _apiClient.get(ApiConstants.userMe);
          _currentUser = UserModel.fromJson(data);
          _isGuest = false;

          // Cập nhật lại SQLite session
          await _dbHelper.saveUserSession(
            userId: _currentUser!.userId,
            fullName: _currentUser!.fullName,
            phoneNumber: _currentUser!.phoneNumber,
            email: _currentUser!.email,
            role: _currentUser!.role,
            walletBalance: _currentUser!.walletBalance,
            accessToken: token,
          );
        } catch (_) {
          // Nếu mất mạng, khôi phục từ SQLite session offline
          final session = await _dbHelper.getUserSession();
          if (session != null) {
            _currentUser = UserModel(
              userId: session['user_id'],
              fullName: session['full_name'],
              phoneNumber: session['phone_number'],
              email: session['email'],
              role: session['role'],
              walletBalance: session['wallet_balance'] ?? 0,
            );
            _isGuest = false;
          }
        }
      } else {
        _isGuest = true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Đăng nhập bằng Email/SĐT + Mật khẩu (Không gửi OTP)
  Future<bool> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConstants.login,
        {
          'identifier': identifier.trim(),
          'password': password.trim(),
        },
        requiresAuth: false,
      );

      final token = res['accessToken'] as String;
      _currentUser = UserModel.fromJson(res);
      _isGuest = false;

      await TokenService.saveToken(token);

      try {
        await _dbHelper.saveUserSession(
          userId: _currentUser!.userId,
          fullName: _currentUser!.fullName,
          phoneNumber: _currentUser!.phoneNumber,
          email: _currentUser!.email,
          role: _currentUser!.role,
          walletBalance: _currentUser!.walletBalance,
          accessToken: token,
        );
      } catch (dbErr) {
        debugPrint('Warning: Local session save error: $dbErr');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gửi OTP xác thực đăng ký tài khoản qua Email thật
  Future<bool> sendRegisterEmailOtp({
    required String email,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.registerEmailOtp,
        {
          'email': email.trim().toLowerCase(),
          'fullName': fullName.trim(),
        },
        requiresAuth: false,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xác thực OTP Email và hoàn tất đăng ký tài khoản mới
  Future<bool> registerWithEmailOtp({
    required String email,
    required String otpCode,
    required String fullName,
    required String phoneNumber,
    required String password,
    DateTime? dateOfBirth,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConstants.registerVerify,
        {
          'email': email.trim().toLowerCase(),
          'otpCode': otpCode.trim(),
          'fullName': fullName.trim(),
          'phoneNumber': phoneNumber.trim(),
          'password': password.trim(),
          'dateOfBirth': dateOfBirth != null
              ? '${dateOfBirth.year}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}'
              : null,
        },
        requiresAuth: false,
      );

      final token = res['accessToken'] as String;
      _currentUser = UserModel.fromJson(res);
      _isGuest = false;

      await TokenService.saveToken(token);

      try {
        await _dbHelper.saveUserSession(
          userId: _currentUser!.userId,
          fullName: _currentUser!.fullName,
          phoneNumber: _currentUser!.phoneNumber,
          email: _currentUser!.email,
          role: _currentUser!.role,
          walletBalance: _currentUser!.walletBalance,
          accessToken: token,
        );
      } catch (dbErr) {
        debugPrint('Warning: Local session save error: $dbErr');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gửi OTP yêu cầu đổi mật khẩu qua Email
  Future<bool> sendChangePasswordEmailOtp({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.changePasswordOtp,
        {'email': email.trim().toLowerCase()},
        requiresAuth: false,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Xác thực OTP và hoàn tất đổi mật khẩu
  Future<bool> changePasswordWithEmailOtp({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiClient.post(
        ApiConstants.changePassword,
        {
          'email': email.trim().toLowerCase(),
          'otpCode': otpCode.trim(),
          'newPassword': newPassword.trim(),
        },
        requiresAuth: false,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// [Legacy] Gửi mã OTP qua SĐT (Tương thích ngược)
  Future<String?> sendOtp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConstants.sendOtp,
        {'phoneNumber': phoneNumber},
        requiresAuth: false,
      );
      return res['debugOtp']?.toString();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// [Legacy] Xác thực mã OTP qua SĐT (Tương thích ngược)
  Future<bool> verifyOtp(String phoneNumber, String otpCode, {String? fullName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(
        ApiConstants.verifyOtp,
        {
          'phoneNumber': phoneNumber,
          'otpCode': otpCode,
          'fullName': fullName,
        },
        requiresAuth: false,
      );

      final token = res['accessToken'] as String;
      _currentUser = UserModel.fromJson(res);
      _isGuest = false;

      await TokenService.saveToken(token);

      try {
        await _dbHelper.saveUserSession(
          userId: _currentUser!.userId,
          fullName: _currentUser!.fullName,
          phoneNumber: _currentUser!.phoneNumber,
          email: _currentUser!.email,
          role: _currentUser!.role,
          walletBalance: _currentUser!.walletBalance,
          accessToken: token,
        );
      } catch (dbErr) {
        debugPrint('Warning: Local session save error: $dbErr');
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cập nhật thông tin cá nhân, ảnh đại diện và chế độ tìm kèo
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    bool? isFindMatchEnabled,
    String? favoriteSports,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (email != null) body['email'] = email;
      if (isFindMatchEnabled != null) body['isFindMatchEnabled'] = isFindMatchEnabled;
      if (favoriteSports != null) body['favoriteSports'] = favoriteSports;
      if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

      final res = await _apiClient.put(ApiConstants.userProfile, body);
      _currentUser = UserModel.fromJson(res);

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vào ứng dụng với tư cách Khách vãng lai (Guest Mode)
  void setGuestMode() {
    _isGuest = true;
    _currentUser = null;
    notifyListeners();
  }

  /// Đăng xuất
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await TokenService.deleteToken();
    await _dbHelper.clearUserSession();

    _currentUser = null;
    _isGuest = true;
    _isLoading = false;
    notifyListeners();
  }
}
