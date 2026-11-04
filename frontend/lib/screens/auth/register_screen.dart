import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _selectedDob;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 6),
      helpText: 'CHỌN NGÀY THÁNG NĂM SINH',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
    );

    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    final auth = context.read<AuthProvider>();

    // Gửi OTP thật tới email qua EmailService
    final success = await auth.sendRegisterEmailOtp(
      email: email,
      fullName: fullName,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mã OTP 6 số đã được gửi tới email: $email. Vui lòng kiểm tra hộp thư!'),
          backgroundColor: AppTheme.turfGreen,
          duration: const Duration(seconds: 4),
        ),
      );

      // Chuyển sang màn hình xác thực OTP Email
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            email: email,
            phoneNumber: phoneNumber,
            fullName: fullName,
            password: password,
            dateOfBirth: _selectedDob,
            isEmailOtp: true,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Không thể gửi mã xác thực. Vui lòng thử lại.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo tài khoản SportSpot 🎉',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nhập thông tin cá nhân bên dưới. Mã OTP xác thực sẽ được gửi trực tiếp đến Email của bạn.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppTheme.textGray,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Họ và tên
                _buildFieldLabel('Họ và tên *', isDark),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Nguyễn Văn An',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên' : null,
                ),
                const SizedBox(height: 16),

                // Số điện thoại
                _buildFieldLabel('Số điện thoại *', isDark),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 0912345678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                    final cleaned = v.trim().replaceAll(RegExp(r'\s+'), '');
                    if (!RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(cleaned)) {
                      return 'Số điện thoại không hợp lệ (10 chữ số)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Ngày tháng năm sinh
                _buildFieldLabel('Ngày tháng năm sinh *', isDark),
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _pickDateOfBirth,
                  decoration: const InputDecoration(
                    hintText: 'Chọn ngày/tháng/năm sinh',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng chọn ngày sinh' : null,
                ),
                const SizedBox(height: 16),

                // Email
                _buildFieldLabel('Địa chỉ Email nhận mã OTP *', isDark),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: nguyenvana@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập địa chỉ email';
                    final email = v.trim();
                    if (!RegExp(r'^[\w\.\-]+@[\w\-]+(\.[a-zA-Z]{2,})+$').hasMatch(email)) {
                      return 'Địa chỉ email không đúng định dạng';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Mật khẩu
                _buildFieldLabel('Mật khẩu *', isDark),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Tối thiểu 6 ký tự',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập mật khẩu';
                    if (v.trim().length < 6) return 'Mật khẩu phải tối thiểu 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Xác nhận mật khẩu
                _buildFieldLabel('Xác nhận mật khẩu *', isDark),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập lại mật khẩu vừa đặt',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng xác nhận mật khẩu';
                    if (v.trim() != _passwordController.text.trim()) {
                      return 'Mật khẩu xác nhận không trùng khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Nút Đăng ký (Gửi OTP Email)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onRegister,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Tiếp tục & Gửi mã OTP qua Email',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Đã có tài khoản
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(color: isDark ? Colors.white70 : AppTheme.textGray),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Đăng nhập ngay',
                        style: TextStyle(
                          color: AppTheme.turfGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : AppTheme.textDark,
        ),
      ),
    );
  }
}
