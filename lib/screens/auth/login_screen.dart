import 'dart:ui';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
                    _HeroHeader(onLanguageTap: _showComingSoon)
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(begin: const Offset(0.95, 0.95), duration: 800.ms, curve: Curves.easeOutQuart),
                    const SizedBox(height: 24),
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
                    ).animate().fadeIn(delay: 200.ms, duration: 800.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart),
                    const SizedBox(height: 24),
                    _Footer(onRegister: _showComingSoon)
                        .animate()
                        .fadeIn(delay: 400.ms, duration: 800.ms),
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
      borderRadius: BorderRadius.circular(32),
      child: SizedBox(
        height: 260,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const SafeNetworkImage(
              url: 'https://images.unsplash.com/photo-1528127269322-539801943592?auto=format&fit=crop&w=1100&q=80',
              fit: BoxFit.cover,
              source: 'login hero image',
              fallback: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4338CA), Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0x990F172A), Color(0xDD0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10)],
                        ),
                        child: const Icon(
                          Icons.travel_explore,
                          color: Color(0xFF4338CA),
                          size: 26,
                        ),
                      ),
                      const Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: TextButton.icon(
                            onPressed: onLanguageTap,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                            ),
                            icon: const Icon(Icons.language, size: 18),
                            label: const Text(
                              'Tiếng Việt',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text('VietAI Travel', style: LoginScreenStyles.heroEyebrow),
                  const SizedBox(height: 8),
                  const Text(
                    'Khám phá thế giới\nvới AI thông minh.',
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 32,
            offset: Offset(0, 16),
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
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4338CA), Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Đăng nhập', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
              ),
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
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        backgroundColor: const Color(0xFFF8FAFC),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
              color: Color(0xFF4338CA),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
