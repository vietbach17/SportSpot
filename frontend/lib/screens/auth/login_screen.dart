import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../main/main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    final auth = context.read<AuthProvider>();
    final success = await auth.loginWithPassword(
      identifier: identifier,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chào mừng ${auth.currentUser?.fullName ?? "bạn"} trở lại!'),
          backgroundColor: AppTheme.turfGreen,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Đăng nhập không thành công. Vui lòng kiểm tra lại thông tin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showForgotPasswordSheet() {
    final emailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool otpSent = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    otpSent ? 'Đặt lại mật khẩu' : 'Quên mật khẩu?',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    otpSent
                        ? 'Nhập mã OTP 6 số đã được gửi qua email cùng mật khẩu mới.'
                        : 'Nhập email đã đăng ký. Hệ thống sẽ gửi mã OTP xác thực qua email cho bạn.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!otpSent) ...[
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ Email',
                        hintText: 'example@gmail.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final email = emailController.text.trim();
                                if (email.isEmpty || !email.contains('@')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Vui lòng nhập email hợp lệ')),
                                  );
                                  return;
                                }
                                setSheetState(() => isSubmitting = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final auth = context.read<AuthProvider>();
                                final sent = await auth.sendChangePasswordEmailOtp(email: email);
                                setSheetState(() => isSubmitting = false);
                                if (sent) {
                                  setSheetState(() => otpSent = true);
                                } else {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(auth.errorMessage ?? 'Gửi OTP thất bại')),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Gửi mã OTP qua Email'),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Mã OTP (6 chữ số)',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final otp = otpController.text.trim();
                                final newPass = newPasswordController.text.trim();
                                if (otp.length != 6 || newPass.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Mã OTP 6 số và mật khẩu tối thiểu 6 ký tự')),
                                  );
                                  return;
                                }
                                setSheetState(() => isSubmitting = true);
                                final messenger = ScaffoldMessenger.of(context);
                                final auth = context.read<AuthProvider>();
                                final res = await auth.changePasswordWithEmailOtp(
                                  email: emailController.text.trim(),
                                  otpCode: otp,
                                  newPassword: newPass,
                                );
                                setSheetState(() => isSubmitting = false);
                                if (res) {
                                  if (!mounted) return;
                                  Navigator.pop(ctx);
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text(auth.errorMessage ?? 'Đổi mật khẩu thất bại')),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Xác nhận đặt lại mật khẩu'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Chào mừng bạn đến SportSpot 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đăng nhập bằng Email hoặc Số điện thoại để tham gia đặt sân và thi đấu.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppTheme.textGray,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),

                // Identifier Field
                Text(
                  'Email hoặc Số điện thoại *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Nhập email (vd: bach@gmail.com) hoặc SĐT',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập Email hoặc Số điện thoại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                Text(
                  'Mật khẩu *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu của bạn',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    if (value.trim().length < 6) {
                      return 'Mật khẩu phải từ 6 ký tự trở lên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordSheet,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onLogin,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Đăng Nhập',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider Or
                Row(
                  children: [
                    Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'HOẶC',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 20),

                // Register Navigation Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? Colors.white24 : AppTheme.carbon),
                    ),
                    child: Text(
                      'Tạo tài khoản mới (Đăng ký)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.carbon,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Guest Mode Button
                Center(
                  child: TextButton(
                    onPressed: () {
                      context.read<AuthProvider>().setGuestMode();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Tiếp tục với tư cách Khách vãng lai',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : AppTheme.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
