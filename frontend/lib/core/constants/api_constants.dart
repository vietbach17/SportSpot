import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Tự động nhận diện IP: 10.0.2.2 cho Android Emulator, localhost cho Windows/Web
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://localhost:5000';
  }

  // Endpoints Auth
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String login = '/api/auth/login';

  // Endpoints Users
  static const String userMe = '/api/users/me';
  static const String userProfile = '/api/users/profile';

  // Endpoints Venues & Sports
  static const String sports = '/api/sports';
  static const String venues = '/api/venues';
  static const String bookings = '/api/bookings';
}
