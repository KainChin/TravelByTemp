import 'package:flutter/material.dart';
import 'login_screen_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Xử lý đăng nhập bằng email/số điện thoại + mật khẩu.
  /// TODO: Gọi API đăng nhập tại đây (ví dụ: AuthService.login(...)).
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Gọi API đăng nhập thật ở đây.
      // final result = await AuthService.login(
      //   identifier: _emailController.text.trim(),
      //   password: _passwordController.text,
      // );
      // Xử lý kết quả: lưu token, điều hướng, hiển thị lỗi...

      await Future.delayed(const Duration(seconds: 1)); // placeholder
    } catch (e) {
      // TODO: Hiển thị lỗi đăng nhập (SnackBar / Dialog) tại đây.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// TODO: Gọi API đăng nhập bằng Google tại đây.
  void _handleGoogleLogin() {}

  /// TODO: Gọi API đăng nhập bằng Facebook tại đây.
  void _handleFacebookLogin() {}

  /// TODO: Gọi API đăng nhập bằng Apple tại đây.
  void _handleAppleLogin() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginScreenStyles.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LoginScreenStyles.horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildTitleSection(),
              const SizedBox(height: LoginScreenStyles.sectionSpacing),
              _buildForm(),
              const SizedBox(height: 24),
              _buildLoginButton(),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 24),
              _buildSocialButtons(),
              const SizedBox(height: 24),
              _buildFooter(),
              const SizedBox(height: 16),
              // TODO: Thay bằng ảnh minh hoạ thật (núi/tháp ở dưới màn hình).
              // Ví dụ: Image.asset('assets/images/login_bottom_illustration.png'),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back),
              color: LoginScreenStyles.textPrimary,
            ),
            // TODO: Thay bằng dropdown đổi ngôn ngữ thực tế (i18n) nếu cần.
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(
                Icons.language,
                size: 18,
                color: LoginScreenStyles.textPrimary,
              ),
              label: const Text(
                'Tiếng Việt',
                style: TextStyle(color: LoginScreenStyles.textPrimary),
              ),
            ),
          ],
        ),
        // TODO: Thay bằng ảnh minh hoạ thật (khinh khí cầu/núi rừng).
        // Ví dụ: Image.asset('assets/images/login_top_illustration.png', height: 140),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTitleSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chào mừng trở lại! 👋', style: LoginScreenStyles.title),
        SizedBox(height: 6),
        Text(
          'Đăng nhập để tiếp tục khám phá những điểm đến tuyệt vời của Việt Nam',
          style: LoginScreenStyles.subtitle,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Email hoặc số điện thoại',
            style: LoginScreenStyles.inputLabel,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: LoginScreenStyles.inputDecoration(
              hint: 'Nhập email hoặc số điện thoại',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email hoặc số điện thoại';
              }
              return null;
            },
          ),
          const SizedBox(height: LoginScreenStyles.fieldSpacing),
          const Text('Mật khẩu', style: LoginScreenStyles.inputLabel),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: LoginScreenStyles.inputDecoration(
              hint: 'Nhập mật khẩu',
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: LoginScreenStyles.textSecondary,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Điều hướng sang màn hình Quên mật khẩu.
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text(
                'Quên mật khẩu?',
                style: LoginScreenStyles.linkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: LoginScreenStyles.primaryButtonStyle,
      child: _isLoading
          ? const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
        ),
      )
          : const Text(
        'Đăng nhập',
        style: LoginScreenStyles.primaryButtonText,
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: const [
        Expanded(child: Divider(color: LoginScreenStyles.inputBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('hoặc', style: LoginScreenStyles.dividerText),
        ),
        Expanded(child: Divider(color: LoginScreenStyles.inputBorder)),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(icon: Icons.g_mobiledata, onTap: _handleGoogleLogin),
        const SizedBox(width: 20),
        _socialButton(icon: Icons.facebook, onTap: _handleFacebookLogin),
        const SizedBox(width: 20),
        _socialButton(icon: Icons.apple, onTap: _handleAppleLogin),
      ],
    );
  }

  Widget _socialButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        LoginScreenStyles.socialButtonRadius,
      ),
      child: Container(
        width: 52,
        height: 52,
        decoration: LoginScreenStyles.socialButtonDecoration,
        child: Icon(icon, color: LoginScreenStyles.textPrimary, size: 26),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Chưa có tài khoản? ',
            style: LoginScreenStyles.footerText,
          ),
          GestureDetector(
            onTap: () {
              // TODO: Điều hướng sang màn hình Đăng ký.
            },
            child: const Text(
              'Đăng ký ngay',
              style: LoginScreenStyles.footerLink,
            ),
          ),
        ],
      ),
    );
  }
}