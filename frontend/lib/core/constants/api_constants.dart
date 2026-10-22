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

  // Endpoints Module 5: Payments (Escrow) & Tickets (Offline QR Pass)
  static const String createPaymentIntent = '/api/payments/create-intent';
  static const String paymentWebhook = '/api/payments/webhook-ipn';
  static const String paymentHistory = '/api/payments/history';
  static String mockInstantPay(String bookingCode) => '/api/payments/mock-pay/$bookingCode';
  static const String myTickets = '/api/tickets/my-tickets';
  static const String verifyQr = '/api/tickets/verify-qr';
  static String cancelTicket(int bookingId) => '/api/tickets/$bookingId/cancel';
}
