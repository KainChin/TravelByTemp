// ignore_for_file: unnecessary_library_name
library login_screen;

import 'dart:ui';

import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'login_screen_styles.dart';

part 'login_screen/login_widgets.dart';

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await VietaiScope.of(context).login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại.\n$e')),
      );
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
    final messenger = ScaffoldMessenger.of(context);
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
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Đăng ký thất bại.\n$e')),
      );
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      await WidgetsBinding.instance.endOfFrame;
      await session.resetPassword(
        usernameOrEmail: pending.account,
        newPassword: pending.password,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Đã đổi mật khẩu. Bạn có thể đăng nhập bằng mật khẩu mới.')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Không đổi được mật khẩu.\n$e')),
      );
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
        ],
      ),
    );
  }
}

class _PendingRegister {
  const _PendingRegister({
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
  });

  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String password;
}

enum _RegisterContactMethod { email, phone }

class _RegisterDialog extends StatefulWidget {
  const _RegisterDialog({required this.validate});

  final String? Function({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) validate;

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;
  _RegisterContactMethod _contactMethod = _RegisterContactMethod.email;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _contactMethod == _RegisterContactMethod.email
        ? _emailController.text.trim()
        : '';
    final phone = _contactMethod == _RegisterContactMethod.phone
        ? _phoneController.text.trim()
        : '';
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    final error = widget.validate(
      fullName: fullName,
      username: username,
      email: email,
      phone: phone,
      password: password,
      confirmPassword: confirm,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _isSubmitting = true);
    Navigator.of(context).pop(
      _PendingRegister(
        fullName: fullName,
        username: username,
        email: email,
        phone: phone,
        password: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthDialogShell(
      title: 'Tạo tài khoản',
      subtitle: 'Điền thông tin để bắt đầu lưu hành trình và hỏi AI du lịch.',
      actionLabel: 'Đăng ký',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AuthTextField(
            controller: _fullNameController,
            label: 'Họ và tên',
            hint: 'Ví dụ: Nguyễn Văn A',
            icon: Icons.badge_outlined,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _usernameController,
            label: 'Tên đăng nhập',
            hint: 'Ví dụ: traveler',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 12),
          SegmentedButton<_RegisterContactMethod>(
            segments: const [
              ButtonSegment(
                value: _RegisterContactMethod.email,
                icon: Icon(Icons.email_outlined, size: 18),
                label: Text('Email'),
              ),
              ButtonSegment(
                value: _RegisterContactMethod.phone,
                icon: Icon(Icons.phone_outlined, size: 18),
                label: Text('Số điện thoại'),
              ),
            ],
            selected: {_contactMethod},
            onSelectionChanged: _isSubmitting
                ? null
                : (selection) {
                    setState(() => _contactMethod = selection.first);
                  },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _contactMethod == _RegisterContactMethod.email
                ? _AuthTextField(
                    key: const ValueKey('register-email'),
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  )
                : _AuthTextField(
                    key: const ValueKey('register-phone'),
                    controller: _phoneController,
                    label: 'Số điện thoại',
                    hint: 'Ví dụ: 0901234567',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _passwordController,
            label: 'Mật khẩu',
            hint: 'Ít nhất 6 ký tự',
            icon: Icons.lock_outline,
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _AuthTextField(
            controller: _confirmController,
            label: 'Nhập lại mật khẩu',
            hint: 'Nhập lại mật khẩu',
            icon: Icons.lock_reset_outlined,
            obscureText: true,
            onFieldSubmitted: (_) => _isSubmitting ? null : _submit(),
          ),
        ],
      ),
    );
  }
}

class _OtpDialog extends StatefulWidget {
  const _OtpDialog({required this.request});

  final BeginRegisterResult request;

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  late final TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.request.devCode ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Xác thực đăng ký'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nhập mã OTP 6 số để hoàn tất tạo tài khoản.'),
          if (widget.request.devCode != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'Mã test local: ${widget.request.devCode}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Mã OTP',
              prefixIcon: Icon(Icons.verified_user_outlined),
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          const SizedBox(height: 8),
          Text(
            'Mã hết hạn lúc ${widget.request.expiresAt.toLocal().toString().substring(11, 16)}.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_codeController.text),
          child: const Text('Xác thực'),
        ),
      ],
    );
  }
}

class _PendingResetPassword {
  const _PendingResetPassword({required this.account, required this.password});

  final String account;
  final String password;
}

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({
    required this.requiredValidator,
    required this.passwordValidator,
  });

  final String? Function(String?) Function(String message) requiredValidator;
  final String? Function(String?) passwordValidator;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    Navigator.of(context).pop(
      _PendingResetPassword(
        account: _accountController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _AuthDialogShell(
      title: 'Quên mật khẩu',
      subtitle: 'Nhập username, email hoặc số điện thoại và đặt mật khẩu mới.',
      actionLabel: 'Đổi mật khẩu',
      isSubmitting: _isSubmitting,
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AuthTextField(
              controller: _accountController,
              label: 'Username, email hoặc số điện thoại',
              hint: 'traveler, you@example.com hoặc 0901234567',
              icon: Icons.alternate_email,
              validator: widget.requiredValidator('Vui lòng nhập username, email hoặc số điện thoại'),
            ),
            const SizedBox(height: 12),
            _AuthTextField(
              controller: _passwordController,
              label: 'Mật khẩu mới',
              hint: 'Ít nhất 6 ký tự',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: widget.passwordValidator,
            ),
            const SizedBox(height: 12),
            _AuthTextField(
              controller: _confirmController,
              label: 'Nhập lại mật khẩu mới',
              hint: 'Nhập lại mật khẩu mới',
              icon: Icons.lock_reset_outlined,
              obscureText: true,
              onFieldSubmitted: (_) => _isSubmitting ? null : _submit(),
              validator: (value) {
                final error = widget.passwordValidator(value);
                if (error != null) return error;
                if (value != _passwordController.text) {
                  return 'Mật khẩu nhập lại không khớp';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
