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

  /// Gửi mã OTP
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

  /// Xác thực mã OTP và nhận JWT Token
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

      // Lưu Token vào SecureStorage
      await TokenService.saveToken(token);

      // Lưu phiên vào Local Cache / SQLite
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

  /// Cập nhật thông tin cá nhân và chế độ tìm kèo
  Future<bool> updateProfile({
    String? fullName,
    String? email,
    bool? isFindMatchEnabled,
    String? favoriteSports,
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
