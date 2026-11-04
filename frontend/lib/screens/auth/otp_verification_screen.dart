import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../main/main_screen.dart';
import '../../widgets/brand_header.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? email;
  final String? fullName;
  final String? password;
  final DateTime? dateOfBirth;
  final bool isEmailOtp;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.email,
    this.fullName,
    this.password,
    this.dateOfBirth,
    this.isEmailOtp = false,
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
    bool success = false;

    if (widget.isEmailOtp && widget.email != null) {
      success = await auth.registerWithEmailOtp(
        email: widget.email!,
        otpCode: otp,
        fullName: widget.fullName ?? 'Thành viên SportSpot',
        phoneNumber: widget.phoneNumber,
        password: widget.password ?? '',
        dateOfBirth: widget.dateOfBirth,
      );
    } else {
      success = await auth.verifyOtp(
        widget.phoneNumber,
        otp,
        fullName: widget.fullName,
      );
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác thực tài khoản thành công! Chào mừng bạn gia nhập SportSpot.'),
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
          content: Text(auth.errorMessage ?? 'Mã OTP không hợp lệ hoặc đã hết hạn. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onResendOtp() async {
    final auth = context.read<AuthProvider>();
    bool success = false;

    if (widget.isEmailOtp && widget.email != null) {
      success = await auth.sendRegisterEmailOtp(
        email: widget.email!,
        fullName: widget.fullName ?? 'Thành viên SportSpot',
      );
    } else {
      final res = await auth.sendOtp(widget.phoneNumber);
      success = res != null;
    }

    if (!mounted) return;

    if (success) {
      _startTimer();
      _pinController.clear();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEmailOtp
              ? 'Mã OTP mới đã được gửi tới email ${widget.email}. Vui lòng kiểm tra hộp thư!'
              : 'Mã OTP mới đã được gửi!'),
          backgroundColor: AppTheme.turfGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Không thể gửi lại mã OTP.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOtpBoxes(bool isDark) {
    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // TextField ẩn để nhận input mượt mà
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
          // 6 Ô hiển thị số
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
                  color: isDark
                      ? (hasValue ? const Color(0xFF1E293B) : const Color(0xFF181A20))
                      : (hasValue ? const Color(0xFFDCFCE7).withValues(alpha: 0.3) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFocused
                        ? AppTheme.turfGreen
                        : (hasValue ? AppTheme.turfGreen : (isDark ? Colors.white24 : const Color(0xFFCBD5E1))),
                    width: isFocused ? 2 : 1.2,
                  ),
                  boxShadow: isFocused
                      ? [
                          BoxShadow(
                            color: AppTheme.turfGreen.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  char,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textDark,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = context.watch<AuthProvider>().isLoading;

    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: SportSpotUnifiedHeader(
        screenName: widget.isEmailOtp ? 'Xác thực Email' : 'Xác thực mã OTP',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Text(
                'Nhập mã gồm 6 chữ số',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : AppTheme.textGray),
                  children: [
                    TextSpan(
                      text: widget.isEmailOtp
                          ? 'Mã xác thực đã được gửi đến hộp thư Email:\n'
                          : 'Mã xác thực đã được gửi đến số điện thoại:\n',
                    ),
                    TextSpan(
                      text: widget.isEmailOtp ? (widget.email ?? '') : widget.phoneNumber,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppTheme.textDark,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isEmailOtp) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: AppTheme.turfGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Vui lòng kiểm tra Hộp thư đến (Inbox) hoặc Thư rác (Spam) trong email của bạn.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // 6 Ô OTP thuần Native Flutter
              _buildOtpBoxes(isDark),

              const SizedBox(height: 32),

              // Đồng hồ đếm ngược 120s
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: isDark ? Colors.white54 : AppTheme.textGray),
                  const SizedBox(width: 6),
                  Text(
                    'Mã có hiệu lực trong: $minutes:$seconds',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white54 : AppTheme.textGray,
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
                  'Gửi lại mã OTP qua Email',
                  style: TextStyle(
                    color: _secondsRemaining == 0 ? AppTheme.turfGreen : Colors.grey,
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
