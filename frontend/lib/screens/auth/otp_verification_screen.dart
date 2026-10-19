import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../main/main_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? fullName;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.fullName,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _timer;
  int _secondsRemaining = 120;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Tự động focus vào ô nhập
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _startTimer() {
    _secondsRemaining = 120;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onVerify(String otp) async {
    if (otp.length != 6) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.verifyOtp(
      widget.phoneNumber,
      otp,
      fullName: widget.fullName,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      // Chuyển thẳng vào MainScreen và xóa sạch stack Auth
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      _pinController.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Mã OTP không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onResendOtp() async {
    final auth = context.read<AuthProvider>();
    final debugOtp = await auth.sendOtp(widget.phoneNumber);

    if (!mounted) return;

    _startTimer();
    _pinController.clear();
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mã OTP mới: ${debugOtp ?? "123456"}'),
        backgroundColor: AppTheme.accentBlue,
      ),
    );
  }

  // Component 6 ô số thuần Flutter Native: 100% không bị lỗi LookupBoundary hay No Material
  Widget _buildOtpBoxes() {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // TextField ẩn để nhận input mượt mà từ bàn phím và paste
          Opacity(
            opacity: 0,
            child: TextField(
              controller: _pinController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
              onChanged: (val) {
                setState(() {});
                if (val.length == 6) {
                  _onVerify(val);
                }
              },
            ),
          ),
          // 6 Ô hiển thị số với hiệu ứng active tinh tế
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final isFocused = _pinController.text.length == index;
              final hasValue = _pinController.text.length > index;
              final char = hasValue ? _pinController.text[index] : '';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 46,
                height: 56,
                decoration: BoxDecoration(
                  color: hasValue ? AppTheme.pastelBlue.withOpacity(0.3) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? AppTheme.accentBlue
                        : (hasValue ? AppTheme.accentBlue : const Color(0xFFCBD5E1)),
                    width: isFocused ? 2 : 1.2,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppTheme.accentBlue.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  char,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực mã OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Nhập mã gồm 6 chữ số',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: AppTheme.textGray),
                  children: [
                    const TextSpan(text: 'Mã xác thực đã được gửi đến số điện thoại\n'),
                    TextSpan(
                      text: widget.phoneNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // 6 Ô OTP thuần Native Flutter
              _buildOtpBoxes(),

              const SizedBox(height: 32),

              // Đồng hồ đếm ngược 120s
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: AppTheme.textGray),
                  const SizedBox(width: 6),
                  Text(
                    'Mã có hiệu lực trong: $minutes:$seconds',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nút Gửi lại mã
              TextButton(
                onPressed: _secondsRemaining == 0 && !isLoading ? _onResendOtp : null,
                child: Text(
                  'Gửi lại mã OTP',
                  style: TextStyle(
                    color: _secondsRemaining == 0 ? AppTheme.accentBlue : Colors.grey,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Nút Xác nhận
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading || _pinController.text.length != 6
                      ? null
                      : () => _onVerify(_pinController.text),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Xác nhận & Hoàn tất'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
