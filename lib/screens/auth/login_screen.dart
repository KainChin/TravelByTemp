// ignore_for_file: unnecessary_library_name
library login_screen;

import 'dart:async';
import 'dart:ui';

import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'login_screen_styles.dart';

part 'login_screen/login_widgets.dart';
part 'login_screen/login_dialogs.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String? _notificationMessage;
  bool _isSuccessNotification = false;
  Timer? _notificationTimer;

  void _showNotification(String message, bool isSuccess) {
    _notificationTimer?.cancel();
    setState(() {
      _notificationMessage = message;
      _isSuccessNotification = isSuccess;
    });
    _notificationTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _notificationMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await VietaiScope.of(context).login(
        _usernameController.text.trim(),
        _passwordController.text,
        delayNotify: true,
      );
      _showNotification('Đăng nhập thành công!', true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      VietaiScope.of(context).applyPendingLogin();
    } catch (e) {
      if (!mounted) return;
      _showNotification('Đăng nhập thất bại: $e', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showRegisterDialog() async {
    final pending = await showDialog<_PendingRegister>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RegisterDialog(validate: _validateRegisterInput),
    );
    if (pending == null || !mounted) return;

    final session = VietaiScope.of(context);
    setState(() => _isLoading = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final request = await session.beginRegister(
        username: pending.username,
        email: pending.email.isEmpty ? null : pending.email,
        password: pending.password,
        fullName: pending.fullName,
        phone: pending.phone.isEmpty ? null : pending.phone,
      );
      if (!mounted) return;
      final code = await _showOtpDialog(request);
      if (code == null || code.trim().isEmpty || !mounted) return;
      await session.verifyRegister(
        verificationId: request.verificationId,
        code: code.trim(),
        delayNotify: true,
      );
      _showNotification('Đăng ký tài khoản thành công!', true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      session.applyPendingLogin();
    } catch (e) {
      if (!mounted) return;
      _showNotification('Đăng ký thất bại: $e', false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _showOtpDialog(BeginRegisterResult request) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OtpDialog(request: request),
    );
  }

  Future<void> _showResetPasswordDialog() async {
    final pending = await showDialog<_PendingResetPassword>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResetPasswordDialog(
        requiredValidator: _requiredValidator,
        passwordValidator: _passwordValidator,
      ),
    );
    if (pending == null || !mounted) return;

    final session = VietaiScope.of(context);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await session.resetPassword(
        usernameOrEmail: pending.account,
        newPassword: pending.password,
      );
      if (!mounted) return;
      _showNotification('Đổi mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.', true);
    } catch (e) {
      if (!mounted) return;
      _showNotification('Không đổi được mật khẩu: $e', false);
    }
  }

  String? Function(String?) _requiredValidator(String message) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  String? _validateRegisterInput({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) {
    if (fullName.isEmpty) return 'Vui lòng nhập họ tên';
    if (username.isEmpty) return 'Vui lòng nhập tên đăng nhập';
    if (email.isEmpty && phone.isEmpty) return 'Vui lòng nhập email hoặc số điện thoại';
    if (email.isNotEmpty && !email.contains('@')) return 'Email không hợp lệ';
    if (phone.isNotEmpty && phone.length < 8) return 'Số điện thoại không hợp lệ';
    final passwordError = _passwordValidator(password);
    if (passwordError != null) return passwordError;
    if (password != confirmPassword) return 'Mật khẩu nhập lại không khớp';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng này chưa được kết nối.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image (Top Half)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Image.asset(
              'assets/images/login.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.7,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Scrollable Content
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _HeroHeader(onLanguageTap: _showComingSoon)
                            .animate()
                            .fadeIn(duration: 700.ms),
                        _LoginPanel(
                          formKey: _formKey,
                          usernameController: _usernameController,
                          passwordController: _passwordController,
                          isPasswordVisible: _isPasswordVisible,
                          isLoading: _isLoading,
                          onTogglePassword: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                          onLogin: _handleLogin,
                          onRegister: _showRegisterDialog,
                          onForgotPassword: _showResetPasswordDialog,
                          onSocialTap: _showComingSoon,
                        ).animate().slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 500.ms,
                              curve: Curves.easeOutQuart,
                            ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Floating Notification
          if (_notificationMessage != null)
            Positioned(
              top: 24,
              left: 20,
              right: 20,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _isSuccessNotification ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSuccessNotification ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccessNotification ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: _isSuccessNotification ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _notificationMessage!,
                            style: TextStyle(
                              color: _isSuccessNotification ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            _notificationTimer?.cancel();
                            setState(() {
                              _notificationMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _isSuccessNotification ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: _isSuccessNotification ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: -0.3, end: 0, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(duration: 250.ms),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


