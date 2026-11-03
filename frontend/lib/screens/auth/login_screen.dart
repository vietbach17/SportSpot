import 'package:flutter/material.dart';
import 'phone_input_screen.dart';

/// Màn hình Đăng nhập SportSpot (chuyển hướng đến luồng xác thực Phone OTP chuẩn mực)
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PhoneInputScreen();
  }
}
