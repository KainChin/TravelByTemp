import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:flutter/material.dart';

import 'login_screen_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'traveler');
  final _passwordController = TextEditingController(text: 'Traveler@123');

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
        SnackBar(
          content: Text('Đăng nhập thất bại. Hãy kiểm tra backend và tài khoản.\n$e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng này chưa được kết nối.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginScreenStyles.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 36),
                child: Column(
                  children: [
                    _HeroHeader(onLanguageTap: _showComingSoon),
                    const SizedBox(height: 18),
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
                      onForgotPassword: _showComingSoon,
                      onSocialTap: _showComingSoon,
                    ),
                    const SizedBox(height: 18),
                    _Footer(onRegister: _showComingSoon),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onLanguageTap});

  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 230,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1100&q=80',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF006B52), Color(0xFF25B08B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xAA05251D), Color(0x2205251D), Color(0xCC05251D)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          color: LoginScreenStyles.primary,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onLanguageTap,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        icon: const Icon(Icons.language, size: 17),
                        label: const Text(
                          'Tiếng Việt',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text('VietAI Travel', style: LoginScreenStyles.heroEyebrow),
                  const SizedBox(height: 8),
                  const Text(
                    'Lên lịch trình Việt Nam dễ hơn.',
                    style: LoginScreenStyles.heroTitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onSocialTap,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onSocialTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LoginScreenStyles.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LoginScreenStyles.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14005B44),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chào mừng trở lại', style: LoginScreenStyles.title),
            const SizedBox(height: 6),
            const Text(
              'Đăng nhập để tiếp tục lưu điểm đến, tạo lịch trình và hỏi AI du lịch.',
              style: LoginScreenStyles.subtitle,
            ),
            const SizedBox(height: 22),
            const Text('Tên đăng nhập', style: LoginScreenStyles.inputLabel),
            const SizedBox(height: 8),
            TextFormField(
              controller: usernameController,
              textInputAction: TextInputAction.next,
              decoration: LoginScreenStyles.inputDecoration(
                hint: 'Ví dụ: traveler',
                prefixIcon: Icons.person_outline,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên đăng nhập';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Mật khẩu', style: LoginScreenStyles.inputLabel),
            const SizedBox(height: 8),
            TextFormField(
              controller: passwordController,
              obscureText: !isPasswordVisible,
              onFieldSubmitted: (_) => isLoading ? null : onLogin(),
              decoration: LoginScreenStyles.inputDecoration(
                hint: 'Nhập mật khẩu',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: LoginScreenStyles.muted,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập mật khẩu';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: const Text('Quên mật khẩu?', style: LoginScreenStyles.linkText),
              ),
            ),
            const SizedBox(height: 4),
            ElevatedButton(
              onPressed: isLoading ? null : onLogin,
              style: LoginScreenStyles.primaryButtonStyle,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Đăng nhập', style: LoginScreenStyles.primaryButtonText),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(child: Divider(color: LoginScreenStyles.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'hoặc tiếp tục với',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: LoginScreenStyles.muted),
                  ),
                ),
                const Expanded(child: Divider(color: LoginScreenStyles.line)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _SocialButton(icon: Icons.g_mobiledata, label: 'Google', onTap: onSocialTap)),
                const SizedBox(width: 10),
                Expanded(child: _SocialButton(icon: Icons.facebook, label: 'Facebook', onTap: onSocialTap)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: LoginScreenStyles.ink,
        side: const BorderSide(color: LoginScreenStyles.line),
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.onRegister});

  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chưa có tài khoản? ',
          style: TextStyle(color: LoginScreenStyles.muted, fontWeight: FontWeight.w600),
        ),
        GestureDetector(
          onTap: onRegister,
          child: const Text(
            'Đăng ký',
            style: TextStyle(
              color: LoginScreenStyles.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
