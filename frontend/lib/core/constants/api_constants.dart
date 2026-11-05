import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConstants {
  static const String _envApiUrl = String.fromEnvironment('API_URL');
  static const String _prefKey = 'custom_backend_api_url';
  static const String ngrokUrl = 'https://couptative-kickless-eleonor.ngrok-free.dev';
  static String? _customUrl;
  static String? _detectedAndroidUrl;

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        final clean = saved.trim().replaceAll(RegExp(r'/+$'), '');
        if (clean.contains('10.87.14.174')) {
          await prefs.remove(_prefKey);
          _customUrl = null;
        } else {
          _customUrl = clean;
        }
      }
    } catch (_) {}

    if (!kIsWeb && Platform.isAndroid && (_customUrl == null || _customUrl!.isEmpty)) {
      await _detectBestAndroidUrl();
    }
  }

  static Future<void> _detectBestAndroidUrl() async {
    const candidates = [
      'http://10.0.2.2:5000',
      ngrokUrl,
      'http://10.87.33.177:5000',
    ];
    for (final candidate in candidates) {
      try {
        final res = await http.get(
          Uri.parse('$candidate/api/payments/payos-webhook'),
          headers: const {'ngrok-skip-browser-warning': 'true'},
        ).timeout(const Duration(milliseconds: 1800));
        if (res.statusCode >= 200 && res.statusCode < 500) {
          _detectedAndroidUrl = candidate;
          debugPrint('[ApiConstants] Connected to backend at: $candidate');
          return;
        }
      } catch (_) {}
    }
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

  // Tự động nhận diện IP cho Android Emulator (10.0.2.2), máy thật (Ngrok / LAN) hoặc Web
  static String get baseUrl {
    if (_customUrl != null && _customUrl!.isNotEmpty) return _customUrl!;
    if (_envApiUrl.isNotEmpty) return _envApiUrl;
    if (kIsWeb) {
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : 'localhost';
      return 'http://$host:5000';
    }
    if (Platform.isAndroid) {
      return _detectedAndroidUrl ?? 'http://10.0.2.2:5000';
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
