// ignore_for_file: unnecessary_library_name
library login_screen;

import 'dart:ui';
import 'package:assignment/core/widgets/vietai_scope.dart';
import 'package:assignment/core/widgets/safe_network_image.dart';
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
