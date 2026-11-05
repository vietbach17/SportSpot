import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static const String _prefKey = 'custom_backend_api_url';
  static String? _customUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _customUrl = saved.trim().replaceAll(RegExp(r'/+$'), '');
      }
    } catch (_) {}
  }

  static Future<void> setCustomUrl(String? url) async {
    final clean = url?.trim().replaceAll(RegExp(r'/+$'), '');
    _customUrl = (clean != null && clean.isNotEmpty) ? clean : null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customUrl != null) {
        await prefs.setString(_prefKey, _customUrl!);
      } else {
        await prefs.remove(_prefKey);
      }
    } catch (_) {}
  }

  // Tự động nhận diện IP: hỗ trợ tùy chỉnh qua Settings hoặc biến môi trường
  static String get baseUrl {
    if (_customUrl != null && _customUrl!.isNotEmpty) return _customUrl!;
    if (_envApiUrl.isNotEmpty) return _envApiUrl;
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return 'http://$host:5000';
    }
    if (Platform.isAndroid) {
      return 'http://10.87.14.174:5000';
    }
    return 'http://localhost:5000';
  }

  // Endpoints Auth
  static const String login = '/api/auth/login';
  static const String registerEmailOtp = '/api/auth/register-otp';
  static const String registerVerify = '/api/auth/register-verify';
  static const String changePasswordOtp = '/api/auth/change-password-otp';
  static const String changePassword = '/api/auth/change-password';
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';

  // Endpoints Users
  static const String userMe = '/api/users/me';
  static const String userProfile = '/api/users/profile';
  static const String userSkills = '/api/users/skills';

  // Endpoints Venues & Sports
  static const String sports = '/api/sports';
  static const String venues = '/api/venues';
  static const String bookings = '/api/bookings';

  // Endpoints Module 5: Payments (Escrow) & Tickets (Offline QR Pass)
  static const String createPaymentIntent = '/api/payments/create-intent';
  static const String paymentWebhook = '/api/payments/webhook-ipn';
  static const String paymentHistory = '/api/payments/history';
  static String mockInstantPay(String bookingCode) => '/api/payments/mock-pay/$bookingCode';
  static const String myTickets = '/api/tickets/my-tickets';
  static const String verifyQr = '/api/tickets/verify-qr';
  static String cancelTicket(int bookingId) => '/api/tickets/$bookingId/cancel';
}
