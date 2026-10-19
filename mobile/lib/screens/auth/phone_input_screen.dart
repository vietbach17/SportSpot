import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    final auth = context.read<AuthProvider>();
    final debugOtp = await auth.sendOtp(phone);

    if (!mounted) return;

    if (debugOtp != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã OTP của bạn là: $debugOtp (Hiệu lực: 120s)'),
          backgroundColor: AppTheme.accentBlue,
          duration: const Duration(seconds: 6),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phoneNumber: phone,
            fullName: name.isNotEmpty ? name : null,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Không thể gửi mã OTP. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập / Đăng ký'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Chào mừng bạn đến SportSpot 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nhập số điện thoại để tiếp tục đặt sân hoặc tham gia các trận đấu phong trào.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textGray,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Họ và tên
                const Text(
                  'Họ và tên của bạn',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Nguyễn Việt Bách',
                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.accentBlue),
                  ),
                ),
                const SizedBox(height: 20),

                // Số điện thoại
                const Text(
                  'Số điện thoại *',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '09xxxxxxxx hoặc 03xxxxxxxx',
                    prefixIcon: Icon(Icons.phone_android_rounded, color: AppTheme.accentBlue),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    final phoneRegex = RegExp(r'^(0[3|5|7|8|9])[0-9]{8}$');
                    if (!phoneRegex.hasMatch(value.trim())) {
                      return 'Số điện thoại không đúng định dạng Việt Nam (10 chữ số)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // Nút Tiếp tục
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onSendOtp,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Gửi mã xác thực OTP'),
                  ),
                ),
                const SizedBox(height: 24),

                // Ghi chú môi trường test
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.pastelBlue.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.pastelBlue),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Mẹo thử nghiệm: Số điện thoại bất kỳ đều được sinh OTP hiển thị ngay trên màn hình hoặc mã 123456.',
                          style: TextStyle(fontSize: 12, color: AppTheme.darkBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
